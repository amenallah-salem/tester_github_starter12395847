import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_options.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_profile.dart';
import 'package:gym_app/services/api_client.dart';

/// Compact Gym Bro swipe deck embedded at the bottom of the Workouts tab.
/// Mirrors GymBroDiscoverPage's swipe-to-like/pass flow but sized to sit
/// inside a scrolling page instead of taking the full screen.
class GymBroExplorerSection extends StatefulWidget {
  const GymBroExplorerSection({super.key});

  @override
  State<GymBroExplorerSection> createState() => _GymBroExplorerSectionState();
}

class _GymBroExplorerSectionState extends State<GymBroExplorerSection> {
  List<GymBroProfile> _profiles = const [];
  bool _loading = true;
  bool _swiping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ApiClient.I.fetchGymBroDiscovery();
      if (!mounted) return;
      setState(() => _profiles = rows.map(GymBroProfile.fromJson).toList());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = 'Unable to load profiles: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _swipe(GymBroProfile profile, {required bool like}) async {
    if (_swiping) return;
    setState(() => _swiping = true);
    try {
      final result = await ApiClient.I.sendGymBroSwipe(
        toUserId: profile.userId,
        like: like,
      );
      if (!mounted) return;
      setState(() => _profiles = _profiles.skip(1).toList());
      if (result['matched'] == true) {
        _showMatchDialog(profile);
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not record swipe: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _swiping = false);
    }
  }

  void _showMatchDialog(GymBroProfile profile) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("It's a match!"),
        content: Text(
          'You and ${profile.displayName} both liked each other. '
          'Say hi from your matches list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep browsing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/gym-bro/matches');
            },
            child: const Text('View matches'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Messages',
              onPressed: () => context.push('/gym-bro/matches'),
              icon: const Icon(Icons.forum_outlined),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gym Bro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Swipe to find a training partner',
                    style: TextStyle(color: AppTheme.mut, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open full screen',
              onPressed: () => context.push('/gym-bro/discover'),
              icon: const Icon(Icons.open_in_full),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 380,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _SectionMessage(
                      icon: Icons.wifi_off,
                      text: _error!,
                      actionLabel: 'Try again',
                      onAction: _load,
                    )
                  : _profiles.isEmpty
                      ? _SectionMessage(
                          icon: Icons.diversity_3_outlined,
                          text: 'No more Gym Bros nearby right now.',
                          actionLabel: 'Refresh',
                          onAction: _load,
                        )
                      : _SwipeCard(
                          profile: _profiles.first,
                          remaining: _profiles.length - 1,
                          busy: _swiping,
                          onLike: () => _swipe(_profiles.first, like: true),
                          onPass: () => _swipe(_profiles.first, like: false),
                        ),
        ),
      ],
    );
  }
}

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.profile,
    required this.remaining,
    required this.busy,
    required this.onLike,
    required this.onPass,
  });

  final GymBroProfile profile;
  final int remaining;
  final bool busy;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Dismissible(
            key: ValueKey(profile.userId),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              if (direction == DismissDirection.startToEnd) {
                onLike();
              } else {
                onPass();
              }
            },
            background: const _SwipeBackground(
              color: AppTheme.primaryContainer,
              icon: Icons.favorite,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: const _SwipeBackground(
              color: AppTheme.errorContainer,
              icon: Icons.close,
              alignment: Alignment.centerRight,
            ),
            child: _ProfileCard(profile: profile),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          remaining > 0 ? '$remaining more nearby' : 'Last one for now',
          style: const TextStyle(color: AppTheme.mut, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoundButton(
              icon: Icons.close,
              color: AppTheme.error,
              onPressed: busy ? null : onPass,
            ),
            _RoundButton(
              icon: Icons.favorite,
              color: AppTheme.primary,
              onPressed: busy ? null : onLike,
            ),
          ],
        ),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Icon(icon, size: 32, color: AppTheme.ink),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final GymBroProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryContainer,
              child: Text(
                profile.displayName.isNotEmpty
                    ? profile.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (profile.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(profile.location, style: const TextStyle(color: AppTheme.mut)),
            ],
            const SizedBox(height: 10),
            if (profile.bio.isNotEmpty) Text(profile.bio),
            const SizedBox(height: 10),
            if (profile.trainingGoals.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final goal in profile.trainingGoals)
                    Chip(
                      label: Text(gymBroGoalLabel(goal)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            if (profile.experienceLevel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Experience: ${gymBroExperienceLabel(profile.experienceLevel)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.mut),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
