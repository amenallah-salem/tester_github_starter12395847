import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_match.dart';
import 'package:gym_app/services/api_client.dart';

/// GB-3/GB-4: list of mutual Gym Bro matches, tap through to chat.
class GymBroMatchesPage extends StatefulWidget {
  const GymBroMatchesPage({super.key});

  @override
  State<GymBroMatchesPage> createState() => _GymBroMatchesPageState();
}

class _GymBroMatchesPageState extends State<GymBroMatchesPage> {
  List<GymBroMatch> _matches = const [];
  bool _loading = true;
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
      final rows = await ApiClient.I.fetchGymBroMatches();
      if (!mounted) return;
      setState(() => _matches = rows.map(GymBroMatch.fromJson).toList());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = 'Unable to load matches: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your matches'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/you'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              : _matches.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum_outlined, size: 48, color: AppTheme.mut),
                            const SizedBox(height: 16),
                            const Text(
                              'No matches yet.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Keep swiping in Discover to find a training partner.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.mut),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: () => context.push('/gym-bro/discover'),
                              child: const Text('Discover'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: _matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final match = _matches[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryContainer,
                                child: Text(
                                  match.profile.displayName.isNotEmpty
                                      ? match.profile.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                match.profile.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                match.profile.bio.isNotEmpty
                                    ? match.profile.bio
                                    : 'Say hi to start the conversation.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                '/gym-bro/matches/${match.id}/chat',
                                extra: match.profile.displayName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
