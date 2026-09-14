import 'package:gym_app/features/coach/domain/ai_conversation.dart';
import 'package:gym_app/features/coach/domain/ai_message.dart';
import 'package:gym_app/services/api_client.dart';

/// Wraps the AI chat endpoints on [ApiClient] and maps raw JSON into domain
/// models, following the same repository-over-ApiClient pattern used by
/// ExerciseRepository.
class AiChatRepository {
  Future<void> ensureFolder() => ApiClient.I.fetchAiFolder();

  Future<List<AiConversation>> listConversations() async {
    final list = await ApiClient.I.fetchAiConversations();
    return list.map(AiConversation.fromJson).toList();
  }

  Future<AiConversation> createConversation() async {
    final json = await ApiClient.I.createAiConversation();
    return AiConversation.fromJson(json);
  }

  Future<AiConversation> renameConversation(String id, String title) async {
    final json = await ApiClient.I.renameAiConversation(id, title);
    return AiConversation.fromJson(json);
  }

  Future<void> deleteConversation(String id) => ApiClient.I.deleteAiConversation(id);

  Future<List<AiMessage>> listMessages(String conversationId) async {
    final list = await ApiClient.I.fetchAiMessages(conversationId);
    return list.map(AiMessage.fromJson).toList();
  }

  /// Sends [content] and yields incremental assistant text as it streams
  /// in. Throws on a terminal `error` event or a transport failure.
  Stream<String> sendMessage({
    required String conversationId,
    required String content,
  }) async* {
    await for (final event in ApiClient.I.streamAiConversationMessage(
      conversationId: conversationId,
      content: content,
    )) {
      switch (event.event) {
        case 'delta':
          yield event.data['text'] as String? ?? '';
          break;
        case 'error':
          throw AiChatStreamException(
            event.data['detail'] as String? ??
                'The assistant is temporarily unavailable. Please try again.',
          );
        case 'done':
          return;
      }
    }
  }
}

class AiChatStreamException implements Exception {
  AiChatStreamException(this.message);
  final String message;

  @override
  String toString() => message;
}
