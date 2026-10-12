// GENERATED CODE - DO NOT MODIFY BY HAND
// **************************************************************************
// DormInitBuilder - Aggregated Auto-Discovery Registry
// **************************************************************************

import 'models/todo.dart';

/// Automatically registers all @DormEntity models into SchemaRegistry.
/// Call this once before calling `dormDb.autoMigrate()`.
void initDorm() {
  registerTodoSchema();
}

/// Backwards compatibility alias for [initDorm].
void initGorm() => initDorm();

