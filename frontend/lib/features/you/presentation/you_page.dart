import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_app/core/state/app_state.dart';
import 'package:gym_app/core/strings/coaching.dart';
import 'package:gym_app/features/plan/data/sample_plan.dart';
import 'package:gym_app/features/plan/domain/plan_contract.dart';
import 'package:gym_app/features/plan/state/plan_notifier.dart';
import 'package:gym_app/services/api_client.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/core/state/auth_state.dart';

/// Welora profile + settings tab. Enhanced per Stitch:
/// - welora_profile_rhythm (name, goal, rhythm)
/// - welora_profile_wearables_biometric_settings (sensors, tone, prefs)
class YouPage extends ConsumerStatefulWidget {
  const YouPage({super.key});

  @override
  ConsumerState<YouPage> createState() => _YouPageState();
}

class _YouPageState extends ConsumerState<YouPage> {
  bool _notifications = true;
  bool _wearables = false;
  bool _heartRateAlerts = true;
  bool _restVibration = true;
  bool _voicePrompts = true;
  bool _upgrading = false;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(profileNameProvider);
    final tone = ref.watch(coachingToneProvider);
    final themeMode = ref.watch(themeModeProvider);
    final plan = ref.watch(planNotifierProvider).value ?? samplePlan;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WELORA MINDFUL',
              style: TextStyle(fontSize: 10, letterSpacing: 1),
            ),
            Text('Kaori'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Coach',
            onPressed: () => context.go('/coach'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // ── Identity ──
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _editName(context),
                      child: const Text('Edit name'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: AppTheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryContainer,
                    child: Icon(
                      Icons.spa_outlined,
                      size: 30,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kaori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Machine form specialist · Online',
                          style: TextStyle(color: AppTheme.mut),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/coach'),
                    icon: const Icon(Icons.call_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Membership',
            child: FutureBuilder<Map<String, dynamic>>(
              future: ApiClient.I.fetchSubscription(),
              builder: (context, snapshot) {
                final plan = snapshot.data?['plan_name'] as String? ?? 'free';
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan == 'free'
                            ? 'Free plan · unlock more coaching with Premium.'
                            : 'Premium plan active.',
                      ),
                    ),
                    if (plan == 'free')
                      FilledButton(
                        onPressed: _upgrading
                            ? null
                            : () async {
                                setState(() => _upgrading = true);
                                try {
                                  await ApiClient.I.upgradeSubscription();
                                  if (mounted) setState(() {});
                                } finally {
                                  if (mounted)
                                    setState(() => _upgrading = false);
                                }
                              },
                        child: Text(_upgrading ? '...' : 'Upgrade'),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () async {
              ref.read(accessTokenProvider.notifier).state = null;
              ref.read(refreshTokenProvider.notifier).state = null;
              ApiClient.I.accessToken = null;
              ApiClient.I.refreshToken = null;
              ref.read(onboardingDoneProvider.notifier).state = false;
              await clearPersistedAuth();
              await clearPersistedOnboarding();
              context.go('/sign-in');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),

          // ── Goal card ──
          Card(
            shape: _cardShape(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your goal',
                    style: TextStyle(color: AppTheme.mut),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enumName(plan.profile.goal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.profile.daysPerWeek}-day plan · ${enumName(plan.weeklySplit)}',
                    style: const TextStyle(color: AppTheme.mut, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Appearance ──
          _SectionCard(
            title: 'Appearance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).state = s.first,
                ),
                const SizedBox(height: 8),
                Text(
                  themeMode == ThemeMode.light
                      ? 'Bright cream with forest-green accents.'
                      : themeMode == ThemeMode.dark
                      ? 'Deep forest, easy on the eyes at night.'
                      : 'Matches your device setting.',
                  style: const TextStyle(color: AppTheme.mut, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Coach tone ──
          _SectionCard(
            title: 'AI Guide · Kaori',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  onSelectionChanged: (s) =>
                      ref.read(coachingToneProvider.notifier).state = s.first,
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
          const SizedBox(height: 12),

          // ── Wearables / biometric (Stitch: welora_profile_wearables_biometric_settings) ──
          _SectionCard(
            title: 'Sensors & Wearables',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.watch_outlined,
                  label: 'Connect wearable',
                  trailing: Switch(
                    value: _wearables,
                    onChanged: (v) => setState(() => _wearables = v),
                  ),
                ),
                const Divider(height: 1),
                _SettingRow(
                  icon: Icons.favorite_outline,
                  label: 'Heart-rate alerts',
                  trailing: Switch(
                    value: _heartRateAlerts,
                    onChanged: (v) => setState(() => _heartRateAlerts = v),
                  ),
                ),
                const Divider(height: 1),
                _SettingRow(
                  icon: Icons.vibration,
                  label: 'Rest timer vibration',
                  trailing: Switch(
                    value: _restVibration,
                    onChanged: (v) => setState(() => _restVibration = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Coaching preferences ──
          _SectionCard(
            title: 'Coaching preferences',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifications',
                  trailing: Switch(
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                ),
                const Divider(height: 1),
                _SettingRow(
                  icon: Icons.volume_up_outlined,
                  label: 'Voice prompts',
                  trailing: Switch(
                    value: _voicePrompts,
                    onChanged: (v) => setState(() => _voicePrompts = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(profileNameProvider),
    );
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

ShapeBorder _cardShape() => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(20),
  side: const BorderSide(color: AppTheme.outlineVariant),
);

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: _cardShape(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.mut),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          trailing,
        ],
      ),
    );
  }
}
