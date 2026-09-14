import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/features/coach/data/ai_chat_repository.dart';
import 'package:gym_app/features/coach/domain/ai_conversation.dart';
import 'package:gym_app/features/coach/domain/ai_message.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) => AiChatRepository());

/// The signed-in user's AI conversation list (the "AI Discussions" folder
/// contents). New Chat / rename / delete all go through this notifier so
/// the list stays in sync with the backend, which is the source of truth.
class AiConversationListNotifier extends Notifier<AsyncValue<List<AiConversation>>> {
  @override
  AsyncValue<List<AiConversation>> build() {
    _load();
    return const AsyncLoading();
  }

  Future<void> _load() async {
    final repo = ref.read(aiChatRepositoryProvider);
    try {
      await repo.ensureFolder();
      final conversations = await repo.listConversations();
      state = AsyncData(conversations);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() => _load();

  Future<AiConversation> createConversation() async {
    final repo = ref.read(aiChatRepositoryProvider);
    final conversation = await repo.createConversation();
    final current = state.valueOrNull ?? const [];
    state = AsyncData([conversation, ...current]);
    return conversation;
  }

  Future<void> renameConversation(String id, String title) async {
    final repo = ref.read(aiChatRepositoryProvider);
    final updated = await repo.renameConversation(id, title);
    final current = state.valueOrNull ?? const [];
    state = AsyncData([
      for (final c in current) c.id == id ? updated : c,
    ]);
  }

  Future<void> deleteConversation(String id) async {
    final repo = ref.read(aiChatRepositoryProvider);
    await repo.deleteConversation(id);
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  /// Called by the chat screen after the first message auto-titles a
  /// conversation, so the list reflects it without a full refresh.
  void applyTitle(String id, String title) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final c in current) c.id == id ? c.copyWith(title: title) : c,
    ]);
  }
}

final aiConversationListProvider =
    NotifierProvider<AiConversationListNotifier, AsyncValue<List<AiConversation>>>(
  AiConversationListNotifier.new,
);

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isLoadingHistory = true,
    this.isSending = false,
    this.error,
  });

  final List<AiMessage> messages;
  final bool isLoadingHistory;
  final bool isSending;
  final String? error;

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoadingHistory,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives a single conversation's message history + live streaming state.
/// One instance per conversation id (family), so switching conversations
/// never mixes up in-flight streams.
class AiChatNotifier extends FamilyNotifier<AiChatState, String> {
  late String _conversationId;
  String? _pendingUserMessage;
  String? _lastUserMessageId;
  String? _lastAssistantMessageId;

  @override
  AiChatState build(String conversationId) {
    _conversationId = conversationId;
    _loadHistory();
    return const AiChatState();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(aiChatRepositoryProvider);
    try {
      final messages = await repo.listMessages(_conversationId);
      if (state.isSending || state.messages.isNotEmpty) {
        // A send already raced ahead of this initial fetch (e.g. a chat
        // that was just created and sent to in the same action) — don't
        // clobber the optimistic/streaming state with a stale snapshot.
        state = state.copyWith(isLoadingHistory: false);
        return;
      }
      state = state.copyWith(messages: messages, isLoadingHistory: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: 'Could not load this conversation. Pull to retry.',
      );
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final repo = ref.read(aiChatRepositoryProvider);
    final optimisticUser = AiMessage(
      id: 'pending-user-${DateTime.now().microsecondsSinceEpoch}',
      role: AiMessageRole.user,
      content: trimmed,
      status: AiMessageStatus.completed,
      createdAt: DateTime.now(),
    );
    final assistantPlaceholder = AiMessage(
      id: 'pending-assistant-${DateTime.now().microsecondsSinceEpoch}',
      role: AiMessageRole.assistant,
      content: '',
      status: AiMessageStatus.pending,
      createdAt: DateTime.now(),
    );
    _pendingUserMessage = trimmed;
    _lastUserMessageId = optimisticUser.id;
    _lastAssistantMessageId = assistantPlaceholder.id;
    state = state.copyWith(
      messages: [...state.messages, optimisticUser, assistantPlaceholder],
      isSending: true,
      clearError: true,
    );

    try {
      final buffer = StringBuffer();
      await for (final delta in repo.sendMessage(conversationId: _conversationId, content: trimmed)) {
        buffer.write(delta);
        _updateAssistantPlaceholder(assistantPlaceholder.id, buffer.toString(), AiMessageStatus.pending);
      }
      _updateAssistantPlaceholder(assistantPlaceholder.id, buffer.toString(), AiMessageStatus.completed);
      _pendingUserMessage = null;
      state = state.copyWith(isSending: false);
    } catch (error) {
      _updateAssistantPlaceholder(
        assistantPlaceholder.id,
        state.messages.firstWhere((m) => m.id == assistantPlaceholder.id).content,
        AiMessageStatus.failed,
      );
      state = state.copyWith(
        isSending: false,
        error: error is AiChatStreamException
            ? error.message
            : 'Could not reach the assistant. Check your connection and try again.',
      );
    }
  }

  void _updateAssistantPlaceholder(String id, String content, AiMessageStatus status) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == id) m.copyWith(content: content, status: status) else m,
      ],
    );
  }

  /// Retries the last user message after a failed send: drops exactly the
  /// failed attempt's user+assistant pair, then resends the same content.
  Future<void> retryLast() async {
    final last = _pendingUserMessage;
    final userId = _lastUserMessageId;
    final assistantId = _lastAssistantMessageId;
    if (last == null) return;
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != userId && m.id != assistantId).toList(),
      clearError: true,
    );
    await sendMessage(last);
  }
}

final aiChatProvider = NotifierProvider.family<AiChatNotifier, AiChatState, String>(
  AiChatNotifier.new,
);
