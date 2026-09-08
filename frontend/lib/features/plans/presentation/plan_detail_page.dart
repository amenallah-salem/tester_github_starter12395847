import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_app/core/theme/app_theme.dart';
import 'package:gym_app/core/widgets/common.dart';
import 'package:gym_app/services/api_client.dart';

const _weekdayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Read-only view of one backend `Plan`: its weekly schedule (from
/// `/plans/{id}/week/`) plus the full exercise list attached to the plan
/// (from `/plans/{id}/`), so exercises are visible even before they're
/// assigned to a specific weekday.
class PlanDetailPage extends StatefulWidget {
  const PlanDetailPage({required this.planId, super.key});

  final String planId;

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  late Future<_PlanDetailData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_PlanDetailData> _load() async {
    final detail = await ApiClient.I.fetchPlanDetail(widget.planId);
    final week = await ApiClient.I.fetchPlanWeek(widget.planId);
    return _PlanDetailData(detail: detail, week: week);
  }

  @override
  Widget build(BuildContext context) {
    return mobileWrap(
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/plans'),
          ),
          title: const Text('Plan'),
        ),
        body: FutureBuilder<_PlanDetailData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const EmptyState(
                message: 'Unable to load this plan.',
                icon: Icons.error_outline,
              );
            }
            final data = snapshot.data!;
            final days = (data.week['days'] as List? ?? const [])
                .cast<Map<String, dynamic>>();
            final exercises = (data.detail['exercises'] as List? ?? const [])
                .cast<Map<String, dynamic>>();
            final hasAnyAssignment = days.any(
              (day) => (day['assignments'] as List? ?? const []).isNotEmpty,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  (data.detail['name'] as String?) ?? 'Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if ((data.detail['description'] as String?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.detail['description'] as String,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Weekly schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final day in days) _WeekdayCard(day: day),
                if (!hasAnyAssignment && exercises.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'All exercises in this plan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (final exercise in exercises)
                          ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(
                              (exercise['name'] as String?) ?? 'Exercise',
                            ),
                            subtitle: Text(
                              (exercise['body_part'] as String?) ?? '',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.push('/exercise/${exercise['id']}'),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.day});

  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final weekday = (day['weekday'] as num?)?.toInt() ?? 0;
    final assignments = (day['assignments'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _weekdayLabels[weekday.clamp(0, 6)],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (assignments.isEmpty)
              const Text(
                'Rest day',
                style: TextStyle(color: AppTheme.mut),
              )
            else
              for (final assignment in assignments)
                InkWell(
                  onTap: () =>
                      context.push('/exercise/${assignment['exercise']}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (assignment['exercise_name'] as String?) ??
                                'Exercise',
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.mut, size: 18),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PlanDetailData {
  const _PlanDetailData({required this.detail, required this.week});

  final Map<String, dynamic> detail;
  final Map<String, dynamic> week;
}
