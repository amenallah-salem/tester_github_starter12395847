import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/features/plans/domain/plan_summary.dart';
import 'package:gym_app/services/api_client.dart';

/// Lists every backend `Plan` belonging to the signed-in user (WELORA's
/// real, multi-plan training programs — distinct from the AI-coach "Today"
/// dashboard, which only ever edits the first one).
class PlansListPage extends StatefulWidget {
  const PlansListPage({super.key});

  @override
  State<PlansListPage> createState() => _PlansListPageState();
}

class _PlansListPageState extends State<PlansListPage> {
  late Future<List<PlanSummary>> _plans;

  @override
  void initState() {
    super.initState();
    _plans = ApiClient.I.fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return mobileWrap(
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/explorer'),
          ),
          title: const Text('My Plans'),
        ),
        body: FutureBuilder<List<PlanSummary>>(
          future: _plans,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                message: 'Unable to load your plans. Try again.',
                icon: Icons.error_outline,
              );
            }
            final plans = snapshot.data ?? const [];
            if (plans.isEmpty) {
              return const EmptyState(
                message: 'No plans yet.',
                icon: Icons.calendar_month_outlined,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final plan in plans)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Text(
                        plan.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        plan.description.isNotEmpty
                            ? '${plan.exerciseCount} exercises · ${plan.description}'
                            : '${plan.exerciseCount} exercises',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (plan.isActive)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.check_circle,
                                  color: AppTheme.primary, size: 18),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.push('/plans/${plan.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
