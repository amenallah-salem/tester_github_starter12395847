import 'package:drift/drift.dart';

import 'package:gym_app/core/database/app_database.dart';

part 'plan_dao.g.dart';

@DriftAccessor(tables: [CachedPlans])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  /// Insert or replace the cached plan for its [planId].
  Future<void> upsert(CachedPlansCompanion row) =>
      into(cachedPlans).insertOnConflictUpdate(row);

  /// Most recently cached plan, or null if none has been generated.
  Future<CachedPlan?> getLatest() async {
    final rows = await (select(cachedPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.firstOrNull;
  }

  Future<void> clear() => delete(cachedPlans).go();
}
