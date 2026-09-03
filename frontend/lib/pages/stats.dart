import 'package:flutter/material.dart';
import '../models/progress_metric.dart';
import '../services/api_client.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<ProgressMetric>> _progress;

  @override
  void initState() {
    super.initState();
    _progress = ApiClient.I.fetchProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: FutureBuilder<List<ProgressMetric>>(
        future: _progress,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No progress yet. Log a workout first.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final m = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.show_chart, color: Colors.indigo),
                  title: Text(m.date),
                  subtitle: Text('reps: ${m.reps} • weight: ${m.weightKg ?? '-'} kg'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
