// GENERATED CODE - DO NOT MODIFY BY HAND
// **************************************************************************
// RelicInitBuilder - Aggregated Auto-Discovery Registry
// **************************************************************************

import 'models/todo.dart';

/// Automatically registers all @RelicEntity models into SchemaRegistry.
/// Call this once before calling `relicDb.autoMigrate()`.
void initRelic() {
  registerTodoSchema();
}

/// Backwards compatibility alias for [initRelic].
void initGorm() => initRelic();

