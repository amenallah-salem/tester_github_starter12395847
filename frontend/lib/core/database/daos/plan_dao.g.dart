// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedPlansTable get cachedPlans => attachedDatabase.cachedPlans;
  PlanDaoManager get managers => PlanDaoManager(this);
}

class PlanDaoManager {
  final _$PlanDaoMixin _db;
  PlanDaoManager(this._db);
  $$CachedPlansTableTableManager get cachedPlans =>
      $$CachedPlansTableTableManager(_db.attachedDatabase, _db.cachedPlans);
}
