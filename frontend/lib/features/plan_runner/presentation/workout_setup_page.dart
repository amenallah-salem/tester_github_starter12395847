import 'package:flutter/material.dart';
import 'package:gym_app/core/theme/app_theme.dart';

/// Workout setup / machine calibration card (Stitch: welora_workout_setup_machine_calibration).
class WorkoutSetupPage extends StatelessWidget {
  const WorkoutSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Calibrate your machine',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the equipment you will use for this session.',
            style: TextStyle(color: AppTheme.mut),
          ),
          const SizedBox(height: 16),
          ...const [
            'Barbell',
            'Dumbbell',
            'Kettlebell',
            'Bodyweight',
            'Machine',
            'Resistance band',
          ].map((item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.settings, color: AppTheme.primary),
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sensor check',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('No sensors connected. Connect a wearable for real-time HR and form cue tracking.',
                      style: TextStyle(color: AppTheme.mut, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
