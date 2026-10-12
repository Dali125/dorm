import 'dart:async';
import 'package:sqflite_common/sqlite_api.dart';

import 'hooks.dart';
import 'logger.dart';
import 'query_builder.dart';
import 'schema.dart';

/// Core RELIC database instance for Flutter.
class RelicDB {
  final DatabaseExecutor _executor;
  final bool isTransaction;
  final RelicLogger logger;

  RelicDB(
    this._executor, {
    this.isTransaction = false,
    RelicLogger? logger,
  }) : logger = logger ?? RelicLogger.standard;

  DatabaseExecutor get executor => _executor;

  /// Helper to execute query with structured timing and logging.
  Future<R> _measure<R>(
    String sql,
    List<dynamic>? params,
    Future<R> Function() action, {
    int Function(R result)? rowsExtractor,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final res = await action();
      sw.stop();
      final rows = rowsExtractor != null ? rowsExtractor(res) : null;
      logger.logQuery(
        sql: sql,
        params: params,
        duration: sw.elapsed,
        rowsAffected: rows,
      );
      return res;
    } catch (e) {
      sw.stop();
      logger.logQuery(
        sql: sql,
        params: params,
        duration: sw.elapsed,
        error: e,
      );
      rethrow;
    }
  }

  /// Starts a query chain scoped to Model type [T].
  RelicScope<T> model<T>() {
    final schema = SchemaRegistry.get<T>();
    if (schema == null) {
      throw ArgumentError('Model $T is not registered in SchemaRegistry');
    }
    return RelicScope<T>(this, QueryBuilder<T>(schema: schema));
  }

  /// Starts a query chain targeting a specific raw table name.
  RelicScope<Map<String, dynamic>> table(String tableName) {
    return RelicScope<Map<String, dynamic>>(
      this,
      QueryBuilder<Map<String, dynamic>>(tableName: tableName),
    );
  }

  /// Automatically creates or migrates tables for registered model schemas.
  /// If [modelTypes] is omitted or empty, all registered schemas are migrated.
  Future<void> autoMigrate([List<Type>? modelTypes]) async {
    final typesToMigrate = (modelTypes != null && modelTypes.isNotEmpty)
        ? modelTypes
        : SchemaRegistry.allSchemas.map((s) => s.modelType).toList();

    for (final type in typesToMigrate) {
      final schema = SchemaRegistry.getByType(type);
      if (schema == null) {
        throw ArgumentError('Schema for $type not found in SchemaRegistry');
      }

      // 1. Create table if not exists
      final createSql = schema.generateCreateTableSql();
      await _measure(createSql, null, () => _executor.execute(createSql));

      // 2. Generate indexes
      for (final idxSql in schema.generateIndexSql()) {
        await _measure(idxSql, null, () => _executor.execute(idxSql));
      }

      // 3. Auto-add missing columns (Migration)
      final existingCols = await _getTableColumns(schema.tableName);
      for (final entry in schema.columns.entries) {
        final col = entry.value;
        if (!existingCols.contains(col.name.toLowerCase())) {
          final addColSql = 'ALTER TABLE "${schema.tableName}" ADD COLUMN ${col.toSqlDefinition()};';
          await _measure(addColSql, null, () => _executor.execute(addColSql));
        }
      }
    }
  }

  Future<Set<String>> _getTableColumns(String tableName) async {
    try {
      final pragma = await _executor.rawQuery('PRAGMA table_info("$tableName");');
      return pragma.map((row) => (row['name'] as String).toLowerCase()).toSet();
    } catch (_) {
      return {};
    }
  }

  /// Creates a single model record in database.
  Future<int> create<T>(T item) async {
    final schema = SchemaRegistry.get<T>();
    if (schema == null) {
      throw ArgumentError('Model $T is not registered in SchemaRegistry');
    }

    final data = Map<String, dynamic>.from(schema.toMap(item));

    // Call hooks if supported
    if (item is GormHooks) {
      await item.beforeCreate(data);
      await item.beforeSave(data);
    }

    // Auto-populate timestamps
    final now = DateTime.now().toIso8601String();
    if (schema.createdAtColumn != null && data[schema.createdAtColumn] == null) {
      data[schema.createdAtColumn!] = now;
    }
    if (schema.updatedAtColumn != null && data[schema.updatedAtColumn] == null) {
      data[schema.updatedAtColumn!] = now;
    }

    // Filter out null primary keys for autoincrement
    if (data[schema.primaryKey] == null) {
      data.remove(schema.primaryKey);
    }

    final keys = data.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    final sql = 'INSERT INTO "${schema.tableName}" ($keys) VALUES ($placeholders)';
    final values = data.values.toList();

    final id = await _measure(
      sql,
      values,
      () => _executor.insert(schema.tableName, data),
      rowsExtractor: (res) => 1,
    );

    if (item is GormHooks) {
      data[schema.primaryKey] = id;
      await item.afterCreate(data);
      await item.afterSave(data);
    }

    return id;
  }

  /// Batch inserts records in chunks.
  Future<List<int>> createInBatches<T>(List<T> items, {int batchSize = 100}) async {
    final ids = <int>[];
    for (var i = 0; i < items.length; i += batchSize) {
      final chunk = items.sublist(i, (i + batchSize > items.length) ? items.length : i + batchSize);
      for (final item in chunk) {
        ids.add(await create<T>(item));
      }
    }
    return ids;
  }

  /// Runs raw SQL query returning list of rows.
  Future<List<Map<String, dynamic>>> raw(String sql, [List<dynamic>? arguments]) async {
    return await _measure(
      sql,
      arguments,
      () => _executor.rawQuery(sql, arguments),
      rowsExtractor: (rows) => rows.length,
    );
  }

  /// Executes raw SQL command (e.g. INSERT, UPDATE, DDL).
  Future<void> exec(String sql, [List<dynamic>? arguments]) async {
    if (arguments != null && arguments.isNotEmpty) {
      await _measure(
        sql,
        arguments,
        () => _executor.rawInsert(sql, arguments),
        rowsExtractor: (id) => 1,
      );
    } else {
      await _measure(sql, null, () => _executor.execute(sql));
    }
  }

  /// Runs function inside an isolated database transaction.
  Future<R> transaction<R>(Future<R> Function(RelicDB tx) action) async {
    final exec = _executor;
    if (exec is! Database) {
      // Already inside a transaction executor
      return await action(this);
    }

    return await exec.transaction<R>((txn) async {
      final txRelic = RelicDB(txn, isTransaction: true, logger: logger);
      return await action(txRelic);
    });
  }
}

/// Backwards compatibility alias for [RelicDB].
typedef GormDB = RelicDB;

/// Fluent query scope representing an active RELIC query chain for model [T].
class RelicScope<T> {
  final RelicDB _db;
  final QueryBuilder<T> _builder;

  RelicScope(this._db, this._builder);

  QueryBuilder<T> get builder => _builder;

  /// Changes target table name.
  RelicScope<T> table(String name) => RelicScope<T>(_db, _builder.table(name));

  /// SELECT specific columns.
  RelicScope<T> select(List<String> columns) => RelicScope<T>(_db, _builder.select(columns));

  /// SELECT DISTINCT.
  RelicScope<T> distinct([bool isDistinct = true]) => RelicScope<T>(_db, _builder.distinct(isDistinct));

  /// Adds WHERE condition.
  RelicScope<T> where(dynamic query, [List<dynamic>? args]) =>
      RelicScope<T>(_db, _builder.where(query, args));

  /// Adds OR condition.
  RelicScope<T> or(String condition, [List<dynamic>? args]) =>
      RelicScope<T>(_db, _builder.or(condition, args));

  /// Adds NOT condition.
  RelicScope<T> not(String condition, [List<dynamic>? args]) =>
      RelicScope<T>(_db, _builder.not(condition, args));

  /// Adds JOIN clause.
  RelicScope<T> joins(String table, String onCondition, {String type = 'INNER JOIN'}) =>
      RelicScope<T>(_db, _builder.joins(table, onCondition, type: type));

  /// Sets ORDER BY.
  RelicScope<T> order(String column, {bool ascending = true}) =>
      RelicScope<T>(_db, _builder.order(column, ascending: ascending));

  /// Sets GROUP BY.
  RelicScope<T> group(String column) => RelicScope<T>(_db, _builder.group(column));

  /// Sets HAVING condition.
  RelicScope<T> having(String condition, [List<dynamic>? args]) =>
      RelicScope<T>(_db, _builder.having(condition, args));

  /// Sets LIMIT.
  RelicScope<T> limit(int count) => RelicScope<T>(_db, _builder.limit(count));

  /// Sets OFFSET.
  RelicScope<T> offset(int count) => RelicScope<T>(_db, _builder.offset(count));

  /// Unscoped disables soft-delete filtering.
  RelicScope<T> unscoped() => RelicScope<T>(_db, _builder.unscoped());

  /// Eager-loads relationship.
  RelicScope<T> preload(String association) => RelicScope<T>(_db, _builder.preload(association));

  /// Finds all matching records.
  Future<List<T>> find() async {
    final clause = _builder.buildSelect();
    final rows = await _db._measure(
      clause.sql,
      clause.params,
      () => _db._executor.rawQuery(clause.sql, clause.params),
      rowsExtractor: (r) => r.length,
    );

    if (_builder.schema == null) {
      return rows.map((r) => r as T).toList();
    }

    final results = <T>[];
    for (final row in rows) {
      final mutableRow = Map<String, dynamic>.from(row);
      final item = _builder.schema!.fromMap(mutableRow);
      if (item is GormHooks) {
        await item.afterFind(mutableRow);
      }
      results.add(item);
    }

    // Handle preloads
    for (final preloadName in _builder.preloads) {
      await _handlePreload(results, preloadName);
    }

    return results;
  }

  /// Finds the first record ordered by primary key.
  Future<T?> first() async {
    final pk = _builder.schema?.primaryKey ?? 'id';
    final scope = order(pk, ascending: true).limit(1);
    final list = await scope.find();
    return list.isNotEmpty ? list.first : null;
  }

  /// Takes any record matching conditions without ordered guarantee.
  Future<T?> take() async {
    final list = await limit(1).find();
    return list.isNotEmpty ? list.first : null;
  }

  /// Finds the last record ordered by primary key DESC.
  Future<T?> last() async {
    final pk = _builder.schema?.primaryKey ?? 'id';
    final scope = order(pk, ascending: false).limit(1);
    final list = await scope.find();
    return list.isNotEmpty ? list.first : null;
  }

  /// Counts matching records.
  Future<int> count() async {
    final clause = _builder.buildCount();
    final rows = await _db._measure(
      clause.sql,
      clause.params,
      () => _db._executor.rawQuery(clause.sql, clause.params),
      rowsExtractor: (r) => r.length,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Queries a single column as a list (analogous to GORM Pluck).
  Future<List<dynamic>> pluck(String column) async {
    final res = await select([column]).find();
    if (_builder.schema != null) {
      return res.map((item) {
        final m = _builder.schema!.toMap(item);
        return m[column];
      }).toList();
    } else {
      return res.map((r) => (r as Map<String, dynamic>)[column]).toList();
    }
  }

  /// Updates columns matching the current query with [data].
  Future<int> updates(Map<String, dynamic> data) async {
    final mutableData = Map<String, dynamic>.from(data);

    if (_builder.schema?.updatedAtColumn != null) {
      mutableData[_builder.schema!.updatedAtColumn!] = DateTime.now().toIso8601String();
    }

    final clause = _builder.buildUpdate(mutableData);
    return await _db._measure(
      clause.sql,
      clause.params,
      () => _db._executor.rawUpdate(clause.sql, clause.params),
      rowsExtractor: (rows) => rows,
    );
  }

  /// Updates a single column with a value.
  Future<int> update(String column, dynamic value) {
    return updates({column: value});
  }

  /// Saves / Upserts a full model object.
  Future<int> save(T item) async {
    final schema = _builder.schema;
    if (schema == null) {
      throw ArgumentError('Model $T has no schema');
    }

    final data = Map<String, dynamic>.from(schema.toMap(item));
    final pkVal = data[schema.primaryKey];

    if (item is GormHooks) {
      await item.beforeSave(data);
    }

    final now = DateTime.now().toIso8601String();
    if (schema.updatedAtColumn != null) {
      data[schema.updatedAtColumn!] = now;
    }

    if (pkVal == null) {
      // Insert
      return await _db.create<T>(item);
    } else {
      // Update
      if (item is GormHooks) {
        await item.beforeUpdate(data);
      }
      final count = await where('"${schema.primaryKey}" = ?', [pkVal]).updates(data);
      if (item is GormHooks) {
        await item.afterUpdate(data);
        await item.afterSave(data);
      }
      return count;
    }
  }

  /// Deletes matching records (soft-delete if deleted_at exists and not unscoped).
  Future<int> delete({bool forceHardDelete = false}) async {
    final clause = _builder.buildDelete(forceHardDelete: forceHardDelete);
    if (clause.sql.startsWith('UPDATE')) {
      return await _db._measure(
        clause.sql,
        clause.params,
        () => _db._executor.rawUpdate(clause.sql, clause.params),
        rowsExtractor: (rows) => rows,
      );
    } else {
      return await _db._measure(
        clause.sql,
        clause.params,
        () => _db._executor.rawDelete(clause.sql, clause.params),
        rowsExtractor: (rows) => rows,
      );
    }
  }

  Future<void> _handlePreload(List<T> items, String associationName) async {
    if (items.isEmpty || _builder.schema == null) return;
    final assoc = _builder.schema!.associations.firstWhere(
      (a) => a.fieldName == associationName,
      orElse: () => throw ArgumentError('Association $associationName not found on ${_builder.schema!.modelType}'),
    );

    final targetSchema = SchemaRegistry.getByType(assoc.targetType);
    if (targetSchema == null) return;

    if (assoc.type == AssociationType.hasMany) {
      final pks = items
          .map((i) => _builder.schema!.toMap(i)[_builder.schema!.primaryKey])
          .where((k) => k != null)
          .toList();

      if (pks.isEmpty) return;

      final placeholders = List.filled(pks.length, '?').join(', ');
      final targetScope = _db.model().where('"${assoc.foreignKey}" IN ($placeholders)', pks);
      await targetScope.find();
    }
  }
}

/// Backwards compatibility alias for [RelicScope].
typedef GormScope<T> = RelicScope<T>;

