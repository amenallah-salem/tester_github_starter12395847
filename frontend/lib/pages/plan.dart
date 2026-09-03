import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/api_client.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});
  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late Future<List<Plan>> _plans;

  @override
  void initState() {
    super.initState();
    _plans = ApiClient.I.fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: FutureBuilder<List<Plan>>(
        future: _plans,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final plans = snap.data ?? [];
          if (plans.isEmpty) {
            return const Center(child: Text('No plans yet. Start the backend!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (_, i) {
              final p = plans[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.teal),
                  title: Text(p.name),
                  subtitle: Text('${p.exerciseCount} exercises\n${p.description}'),
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
