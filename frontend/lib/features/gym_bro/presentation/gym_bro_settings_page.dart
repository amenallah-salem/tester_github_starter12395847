import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/features/gym_bro/domain/gym_bro_options.dart';
import 'package:gym_app/services/api_client.dart';

/// GB-1: Gym Bro training-profile settings screen.
///
/// Separate from the initial onboarding flow — this is reachable any time
/// from Settings ("You" tab) and edits the same backend `Profile` fields
/// used by the discovery feed (GB-2) to decide who is shown to others.
///
/// Privacy note: only a free-text city/area string is collected for
/// `location` — this screen intentionally has no map picker or GPS request.
class GymBroSettingsPage extends StatefulWidget {
  const GymBroSettingsPage({super.key});

  @override
  State<GymBroSettingsPage> createState() => _GymBroSettingsPageState();
}

class _GymBroSettingsPageState extends State<GymBroSettingsPage> {
  final _bioController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _locationController = TextEditingController();
  final Set<String> _selectedGoals = {};
  String? _experienceLevel;

  String? _profileId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _availabilityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ApiClient.I.fetchProfile();
      if (!mounted) return;
      _profileId = profile['id']?.toString();
      _bioController.text = (profile['bio'] as String?) ?? '';
      _availabilityController.text = (profile['availability'] as String?) ?? '';
      _locationController.text = (profile['location'] as String?) ?? '';
      _experienceLevel =
          (profile['experience_level'] as String?)?.isEmpty ?? true
              ? null
              : profile['experience_level'] as String;
      final goals = (profile['training_goals'] as List?)?.cast<String>() ?? [];
      setState(() {
        _selectedGoals
          ..clear()
          ..addAll(goals);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = 'Unable to load profile: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final profileId = _profileId;
    if (profileId == null) return;
    setState(() => _saving = true);
    try {
      await ApiClient.I.updateProfile(profileId, {
        'bio': _bioController.text.trim(),
        'training_goals': _selectedGoals.toList(),
        'experience_level': _experienceLevel ?? '',
        'availability': _availabilityController.text.trim(),
        'location': _locationController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym Bro profile saved.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Bro profile'),
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/you'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppTheme.error)),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'This is what other people see when they swipe on you '
                  "in Gym Bro. It's separate from your training plan.",
                  style: TextStyle(color: AppTheme.mut),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'A short intro about you and your training.',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Training goals',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in gymBroGoalOptions)
                      FilterChip(
                        label: Text(option.value),
                        selected: _selectedGoals.contains(option.key),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedGoals.add(option.key);
                          } else {
                            _selectedGoals.remove(option.key);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Experience level',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in gymBroExperienceOptions)
                      ChoiceChip(
                        label: Text(option.value),
                        selected: _experienceLevel == option.key,
                        onSelected: (_) =>
                            setState(() => _experienceLevel = option.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _availabilityController,
                  decoration: const InputDecoration(
                    labelText: 'Availability',
                    hintText: 'e.g. Weekday mornings, Saturday afternoons',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'City or area only, e.g. Austin, TX',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We only ask for a city or area — never precise location '
                  'or GPS coordinates.',
                  style: TextStyle(color: AppTheme.mut, fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving || _profileId == null ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save profile'),
                  ),
                ),
              ],
            ),
    );
  }
}
