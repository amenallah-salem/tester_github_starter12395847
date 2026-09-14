import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/coach/application/ai_chat_providers.dart';
import 'package:gym_app/features/coach/domain/ai_conversation.dart';

/// "AI Discussions" home: Kaori's conversation list. Real chat lives at
/// /coach/new (new conversation) and /coach/:id (continue an existing one).
class CoachPage extends ConsumerWidget {
  const CoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(aiConversationListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
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
        actions: [
          IconButton(
            tooltip: 'Form Vault',
            onPressed: () => context.push('/vault'),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coach/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.read(aiConversationListProvider.notifier).refresh(),
        ),
        data: (list) => list.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () => ref.read(aiConversationListProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _ConversationTile(conversation: list[index]),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final AiConversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppTheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(conversation.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _formatTimestamp(conversation.lastMessageAt ?? conversation.updatedAt),
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
        ),
        onTap: () => context.push('/coach/${conversation.id}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'rename') {
              await _showRenameDialog(context, ref, conversation);
            } else if (value == 'delete') {
              await _confirmDelete(context, ref, conversation);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, AiConversation conversation) async {
    final controller = TextEditingController(text: conversation.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
      try {
        await ref
            .read(aiConversationListProvider.notifier)
            .renameConversation(conversation.id, newTitle);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not rename this conversation.')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AiConversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text('"${conversation.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(aiConversationListProvider.notifier).deleteConversation(conversation.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete this conversation.')),
          );
        }
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_outlined, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text('Ask Kaori anything', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Training structure, technique, recovery, or motivation — start a new chat to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load your conversations.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.toLocal();
  final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (isToday) return 'Today · $hh:$mm';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
