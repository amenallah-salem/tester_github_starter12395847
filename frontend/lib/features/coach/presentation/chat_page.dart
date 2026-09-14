import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/coach/application/ai_chat_providers.dart';
import 'package:gym_app/features/coach/domain/ai_message.dart';
import 'package:gym_app/features/coach/presentation/markdown_lite.dart';

/// Kaori chat screen. Pass `conversationId: null` to start a brand-new
/// conversation (created lazily on first send); pass an id to continue an
/// existing one, loading its persisted history first.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String? conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String? _conversationId;
  bool _creatingConversation = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();

    var conversationId = _conversationId;
    if (conversationId == null) {
      setState(() => _creatingConversation = true);
      try {
        final conversation =
            await ref.read(aiConversationListProvider.notifier).createConversation();
        conversationId = conversation.id;
        if (!mounted) return;
        setState(() {
          _conversationId = conversationId;
          _creatingConversation = false;
        });
        context.replace('/coach/$conversationId');
      } catch (_) {
        if (!mounted) return;
        setState(() => _creatingConversation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start a new chat. Please try again.')),
        );
        return;
      }
    }

    await ref.read(aiChatProvider(conversationId).notifier).sendMessage(text);
    _scrollToBottom();
    // Refresh list metadata (title/last-message time) now that the backend
    // may have auto-titled the conversation on its first message.
    if (mounted) {
      unawaited(ref.read(aiConversationListProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationId = _conversationId;
    final chatState = conversationId != null ? ref.watch(aiChatProvider(conversationId)) : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/coach'),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryContainer,
              child: Icon(Icons.spa_outlined, color: AppTheme.primary),
            ),
            SizedBox(width: 10),
            Text('Kaori'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageArea(chatState)),
          if (chatState?.error != null) _buildErrorBanner(chatState!.error!, conversationId!),
          _buildInputBar(chatState),
        ],
      ),
    );
  }

  Widget _buildMessageArea(AiChatState? chatState) {
    if (chatState == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Ask Kaori about training, technique, recovery, or motivation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }
    if (chatState.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chatState.messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Say hello to start the conversation.',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }
    _scrollToBottom();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _MessageBubble(message: chatState.messages[index]),
      ),
    );
  }

  Widget _buildErrorBanner(String error, String conversationId) {
    return Material(
      color: AppTheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
            TextButton(
              onPressed: () => ref.read(aiChatProvider(conversationId).notifier).retryLast(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(AiChatState? chatState) {
    final sending = chatState?.isSending == true || _creatingConversation;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: TextField(
          controller: _inputController,
          minLines: 1,
          maxLines: 5,
          textInputAction: TextInputAction.send,
          enabled: !sending,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            hintText: sending ? 'Kaori is thinking…' : 'Message Kaori',
            prefixIcon: const Icon(Icons.add_circle_outline),
            suffixIcon: sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;
    final isFailed = message.status == AiMessageStatus.failed;
    final isPending = message.status == AiMessageStatus.pending;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.surface : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
          border: isFailed ? Border.all(color: Colors.redAccent, width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.content.isEmpty && isPending)
              const Text('…')
            else if (isUser)
              Text(message.content)
            else
              MarkdownLiteText(message.content),
            if (isFailed)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Not delivered',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
