import 'package:flutter/material.dart';
import '../services/api_client.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<String> exercises = ['Bench Press', 'Overhead Press', 'Tricep Dips'];
  final List<bool> completed = [false, false, false];
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ApiClient.I.createWorkout(notes: 'Completed ${completed.where((c) => c).length}/${exercises.length}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (_, i) => Card(
          child: CheckboxListTile(
            title: Text(exercises[i]),
            value: completed[i],
            onChanged: (v) => setState(() => completed[i] = v ?? false),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _finish,
        icon: const Icon(Icons.check),
        label: const Text('Finish'),
      ),
    );
  }
}
