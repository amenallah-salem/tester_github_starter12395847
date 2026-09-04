import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/biomechanics/data/biomechanics_mock.dart';

/// Form Vault — archive of past movement recordings.
/// Aligns to Stitch: welora_form_vault_movement_archive.
/// Mock data isolated in data/biomechanics_mock.dart (NOT real measurements).
class FormVaultPage extends ConsumerWidget {
  const FormVaultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(formVaultProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Movement archive',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            'Mock archive — connect a camera or wearable to record real sessions.',
            style: TextStyle(color: AppTheme.mut.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => _VaultEntry(entry: e)),
        ],
      ),
    );
  }
}

class _VaultEntry extends StatelessWidget {
  const _VaultEntry({required this.entry});
  final FormVaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final scoreColor = entry.score >= 85
        ? const Color(0xFF446651)
        : entry.score >= 70
            ? const Color(0xFFE8C547)
            : AppTheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_circle_outline,
                color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.exerciseName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${entry.date} · ${entry.durationSec}s',
                  style: const TextStyle(color: AppTheme.mut, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${entry.score}',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
