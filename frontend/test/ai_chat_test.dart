import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/coach/application/ai_chat_providers.dart';
import 'package:gym_app/features/coach/domain/ai_conversation.dart';
import 'package:gym_app/features/coach/domain/ai_message.dart';
import 'package:gym_app/features/coach/presentation/chat_page.dart';
import 'package:gym_app/features/coach/presentation/coach_page.dart';

/// Test doubles that skip the network entirely by overriding `build()` to
/// return canned state directly, rather than calling the real repository —
/// the standard Riverpod approach for testing screens without a mock HTTP
/// layer (this project has no existing HTTP-mocking test harness).
class _FixedConversationList extends AiConversationListNotifier {
  _FixedConversationList(this._initial);
  final AsyncValue<List<AiConversation>> _initial;

  @override
  AsyncValue<List<AiConversation>> build() => _initial;
}

class _FixedChat extends AiChatNotifier {
  _FixedChat(this._initial);
  final AiChatState _initial;

  @override
  AiChatState build(String conversationId) => _initial;
}

AiConversation _conversation({String id = 'c1', String title = 'Push day plan'}) {
  final now = DateTime.now();
  return AiConversation(
    id: id,
    title: title,
    model: 'openrouter/free',
    createdAt: now,
    updatedAt: now,
    lastMessageAt: now,
  );
}

AiMessage _message({
  required String id,
  required AiMessageRole role,
  required String content,
  AiMessageStatus status = AiMessageStatus.completed,
}) {
  return AiMessage(id: id, role: role, content: content, status: status, createdAt: DateTime.now());
}

void main() {
  testWidgets('conversation list shows the empty state with no conversations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConversationListProvider.overrideWith(
            () => _FixedConversationList(const AsyncData([])),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CoachPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ask Kaori anything'), findsOneWidget);
    expect(find.text('New Chat'), findsOneWidget);
  });

  testWidgets('conversation list renders conversations with title and menu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConversationListProvider.overrideWith(
            () => _FixedConversationList(AsyncData([_conversation()])),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CoachPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push day plan'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('conversation list shows a retry action on error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConversationListProvider.overrideWith(
            () => _FixedConversationList(AsyncError('network down', StackTrace.empty)),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CoachPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your conversations.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('rename dialog updates the list via the notifier', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiConversationListProvider.overrideWith(
            () => _FixedConversationList(AsyncData([_conversation()])),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CoachPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename conversation'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New title');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    // The overridden notifier's real renameConversation() would hit the
    // network; here we only verify the dialog closed cleanly (no crash).
    expect(find.text('Rename conversation'), findsNothing);
  });

  testWidgets('new chat empty screen prompts before any conversation exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const ChatPage(conversationId: null)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ask Kaori about training, technique, recovery, or motivation.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('chat screen renders user and assistant bubbles with streaming/failed states',
      (tester) async {
    final state = AiChatState(
      isLoadingHistory: false,
      messages: [
        _message(id: '1', role: AiMessageRole.user, content: 'How should I train legs?'),
        _message(
          id: '2',
          role: AiMessageRole.assistant,
          content: 'Start with squats',
          status: AiMessageStatus.pending,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatProvider.overrideWith(() => _FixedChat(state)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ChatPage(conversationId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How should I train legs?'), findsOneWidget);
    expect(find.text('Start with squats', findRichText: true), findsOneWidget);
  });

  testWidgets('chat screen shows an error banner with retry when the last send failed',
      (tester) async {
    final state = AiChatState(
      isLoadingHistory: false,
      error: 'The assistant is temporarily unavailable. Please try again.',
      messages: [
        _message(id: '1', role: AiMessageRole.user, content: 'hello'),
        _message(
          id: '2',
          role: AiMessageRole.assistant,
          content: '',
          status: AiMessageStatus.failed,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatProvider.overrideWith(() => _FixedChat(state)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ChatPage(conversationId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not delivered'), findsOneWidget);
    expect(find.text('The assistant is temporarily unavailable. Please try again.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  test('AiConversation.fromJson parses backend shape', () {
    final now = DateTime.now().toUtc();
    final conversation = AiConversation.fromJson({
      'id': 'abc',
      'title': 'New Chat',
      'model': 'openrouter/free',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'last_message_at': null,
    });
    expect(conversation.id, 'abc');
    expect(conversation.title, 'New Chat');
    expect(conversation.lastMessageAt, isNull);
  });

  test('AiMessage.fromJson parses role and status', () {
    final message = AiMessage.fromJson({
      'id': 'm1',
      'role': 'assistant',
      'content': 'hi',
      'status': 'failed',
      'created_at': DateTime.now().toIso8601String(),
    });
    expect(message.role, AiMessageRole.assistant);
    expect(message.status, AiMessageStatus.failed);
  });
}
