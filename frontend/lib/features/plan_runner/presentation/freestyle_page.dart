import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_app/features/plan/domain/plan_contract.dart';
import 'package:gym_app/features/plan/domain/plan_enums.dart';
import 'package:gym_app/services/api_client.dart';

class FreestylePage extends StatefulWidget {
  const FreestylePage({required this.onStart, super.key});

  final void Function(List<PlanExercise>) onStart;

  @override
  State<FreestylePage> createState() => _FreestylePageState();
}

class _FreestylePageState extends State<FreestylePage> {
  late final Future<List<Map<String, dynamic>>> _exercises =
      ApiClient.I.fetchLibraryExercises();
  final Set<String> _selected = {};

  PlanExercise _toPlanExercise(Map<String, dynamic> exercise) {
    return PlanExercise(
      exerciseId: exercise['id'].toString(),
      name: exercise['name'] as String,
      equipment: Equipment.bodyweight,
      muscleGroups: const [FocusArea.fullBody],
      sets: 3,
      reps: '8-12',
      restSec: 60,
      isTimed: exercise['is_timed'] == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freestyle workout'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercises,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load exercises.'));
          }
          final exercises = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Pick any exercises for this session.'),
              const SizedBox(height: 12),
              for (final exercise in exercises)
                CheckboxListTile(
                  value: _selected.contains(exercise['id'].toString()),
                  title: Text(exercise['name'] as String),
                  subtitle: Text(exercise['body_part']?.toString() ?? ''),
                  onChanged: (_) => setState(() {
                    final id = exercise['id'].toString();
                    if (!_selected.add(id)) _selected.remove(id);
                  }),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => widget.onStart(
                          exercises
                              .where(
                                  (e) => _selected.contains(e['id'].toString()))
                              .map(_toPlanExercise)
                              .toList(),
                        ),
                child: Text('Start (${_selected.length})'),
              ),
            ],
          );
        },
      ),
    );
  }
}
