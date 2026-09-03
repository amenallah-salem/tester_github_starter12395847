import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';

/// Profile tab: name, goals, equipment, notifications, and the coach-tone
/// opt-in that switches the whole app between Encouraging and No-nonsense
/// voice (TES-6 §5).
class YouPage extends ConsumerStatefulWidget {
  const YouPage({super.key});

  @override
  ConsumerState<YouPage> createState() => _YouPageState();
}

class _YouPageState extends ConsumerState<YouPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(profileNameProvider);
    final tone = ref.watch(coachingToneProvider);
    final plan = ref.watch(planNotifierProvider).value ?? samplePlan;

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.brand,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _editName(context),
                      child: const Text('Edit name'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your goal',
                      style: TextStyle(color: AppTheme.mut)),
                  const SizedBox(height: 4),
                  Text(plan.profile.goal.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      '${plan.profile.daysPerWeek}-day plan · ${plan.weeklySplit.name}',
                      style: const TextStyle(color: AppTheme.mut)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications'),
                  Switch(
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coach tone',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SegmentedButton<CoachingTone>(
                    segments: const [
                      ButtonSegment(
                        value: CoachingTone.encouraging,
                        label: Text('Encouraging'),
                      ),
                      ButtonSegment(
                        value: CoachingTone.noNonsense,
                        label: Text('No-nonsense'),
                      ),
                    ],
                    selected: {tone},
                    onSelectionChanged: (s) => ref
                        .read(coachingToneProvider.notifier)
                        .state = s.first,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tone == CoachingTone.noNonsense
                        ? 'Terse, to-the-point cues.'
                        : 'Warm, upbeat trainer voice.',
                    style: const TextStyle(color: AppTheme.mut, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context) {
    final controller =
        TextEditingController(text: ref.read(profileNameProvider));
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                ref.read(profileNameProvider.notifier).state = v;
              }
              Navigator.of(c).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
