import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

/// Workout setup / machine calibration card (Stitch: welora_workout_setup_machine_calibration).
class WorkoutSetupPage extends StatefulWidget {
  const WorkoutSetupPage({super.key});

  @override
  State<WorkoutSetupPage> createState() => _WorkoutSetupPageState();
}

class _WorkoutSetupPageState extends State<WorkoutSetupPage> {
  String _equipment = 'Dumbbell';
  bool _sensorConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session setup'),
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Prepare your space',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'A calm setup helps every rep feel more intentional.',
            style: TextStyle(color: AppTheme.mut),
          ),
          const SizedBox(height: 24),
          const Text(
            'Equipment',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                'Barbell',
                'Dumbbell',
                'Kettlebell',
                'Bodyweight',
                'Machine',
                'Resistance band',
              ])
                ChoiceChip(
                  label: Text(item),
                  selected: _equipment == item,
                  onSelected: (_) => setState(() => _equipment = item),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sensor check',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sensorConnected
                        ? 'Wearable connected. Heart rate cues are ready.'
                        : 'No sensors connected. You can still train with guided cues.',
                    style: const TextStyle(color: AppTheme.mut, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Connect wearable'),
                    value: _sensorConnected,
                    onChanged: (value) =>
                        setState(() => _sensorConnected = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/run'),
              icon: const Icon(Icons.play_arrow),
              label: Text('Begin with $_equipment'),
            ),
          ),
        ],
      ),
    );
  }
}
