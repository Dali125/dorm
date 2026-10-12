import 'dart:async';

/// Hooks / Lifecycle callbacks analogous to RELIC's Hook interface.
///
/// Available Hooks:
/// - beforeSave / afterSave
/// - beforeCreate / afterCreate
/// - beforeUpdate / afterUpdate
/// - beforeDelete / afterDelete
/// - afterFind
mixin RelicHooks {
  FutureOr<void> beforeCreate(Map<String, dynamic> data) {}
  FutureOr<void> afterCreate(Map<String, dynamic> data) {}

  FutureOr<void> beforeUpdate(Map<String, dynamic> data) {}
  FutureOr<void> afterUpdate(Map<String, dynamic> data) {}

  FutureOr<void> beforeSave(Map<String, dynamic> data) {}
  FutureOr<void> afterSave(Map<String, dynamic> data) {}

  FutureOr<void> beforeDelete(Map<String, dynamic> data) {}
  FutureOr<void> afterDelete(Map<String, dynamic> data) {}

  FutureOr<void> afterFind(Map<String, dynamic> data) {}
}

/// Backwards compatibility alias for [RelicHooks].
typedef GormHooks = RelicHooks;

