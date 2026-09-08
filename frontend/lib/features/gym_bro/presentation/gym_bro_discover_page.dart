import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_options.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_profile.dart';
import 'package:gym_app/services/api_client.dart';

/// GB-2/GB-3: Gym Bro discovery feed with swipe-to-like/pass.
class GymBroDiscoverPage extends StatefulWidget {
  const GymBroDiscoverPage({super.key});

  @override
  State<GymBroDiscoverPage> createState() => _GymBroDiscoverPageState();
}

class _GymBroDiscoverPageState extends State<GymBroDiscoverPage> {
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
      setState(() {
        _profiles = rows.map(GymBroProfile.fromJson).toList();
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/you'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _profiles.isEmpty
                  ? _EmptyState(onRefresh: _load)
                  : _SwipeStack(
                      profile: _profiles.first,
                      remaining: _profiles.length - 1,
                      busy: _swiping,
                      onLike: () => _swipe(_profiles.first, like: true),
                      onPass: () => _swipe(_profiles.first, like: false),
                    ),
    );
  }
}

class _SwipeStack extends StatelessWidget {
  const _SwipeStack({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
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
          const SizedBox(height: 8),
          Text(
            remaining > 0 ? '$remaining more nearby' : 'Last one for now',
            style: const TextStyle(color: AppTheme.mut),
          ),
          const SizedBox(height: 16),
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
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Icon(icon, size: 40, color: AppTheme.ink),
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
          padding: const EdgeInsets.all(18),
          child: Icon(icon, color: color, size: 28),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryContainer,
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          if (profile.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(profile.location, style: const TextStyle(color: AppTheme.mut)),
          ],
          const SizedBox(height: 16),
          if (profile.bio.isNotEmpty) Text(profile.bio),
          const SizedBox(height: 16),
          if (profile.trainingGoals.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final goal in profile.trainingGoals)
                  Chip(label: Text(gymBroGoalLabel(goal))),
              ],
            ),
          if (profile.experienceLevel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Experience: ${gymBroExperienceLabel(profile.experienceLevel)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (profile.availability.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Available: ${profile.availability}',
                style: const TextStyle(color: AppTheme.mut)),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diversity_3_outlined, size: 48, color: AppTheme.mut),
            const SizedBox(height: 16),
            const Text(
              'No more Gym Bros nearby right now.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later, or complete your profile so others can find you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mut),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
