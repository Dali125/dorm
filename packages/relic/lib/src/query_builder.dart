import 'clauses.dart';
import 'schema.dart';

/// Fluent query builder for GORM querying and mutations.
class QueryBuilder<T> {
  final ModelSchema<T>? schema;
  String _table;
  final List<String> _selectColumns = [];
  bool _distinct = false;
  final WhereBuilder _where = WhereBuilder();
  final List<JoinClause> _joins = [];
  final List<OrderClause> _orders = [];
  final List<String> _groupBy = [];
  Clause? _having;
  int? _limit;
  int? _offset;
  bool _unscoped = false;
  final List<String> _preloads = [];

  QueryBuilder({this.schema, String? tableName})
      : _table = tableName ?? schema?.tableName ?? '';

  String get tableName => _table;
  bool get isUnscoped => _unscoped;
  List<String> get preloads => _preloads;

  /// Clones the current query builder state for immutable chaining.
  QueryBuilder<T> clone() {
    final q = QueryBuilder<T>(schema: schema, tableName: _table);
    q._selectColumns.addAll(_selectColumns);
    q._distinct = _distinct;
    q._where.clauses.addAll(_where.clauses);
    q._joins.addAll(_joins);
    q._orders.addAll(_orders);
    q._groupBy.addAll(_groupBy);
    q._having = _having;
    q._limit = _limit;
    q._offset = _offset;
    q._unscoped = _unscoped;
    q._preloads.addAll(_preloads);
    return q;
  }

  /// Changes the target table.
  QueryBuilder<T> table(String name) {
    final q = clone();
    q._table = name;
    return q;
  }

  /// Sets SELECT columns.
  QueryBuilder<T> select(List<String> columns) {
    final q = clone();
    q._selectColumns.clear();
    q._selectColumns.addAll(columns);
    return q;
  }

  /// Sets DISTINCT query.
  QueryBuilder<T> distinct([bool isDistinct = true]) {
    final q = clone();
    q._distinct = isDistinct;
    return q;
  }

  /// Adds WHERE clause condition.
  /// Example: where('age > ?', [18])
  /// or where({'name': 'John', 'active': 1})
  QueryBuilder<T> where(dynamic query, [List<dynamic>? args]) {
    final q = clone();
    if (query is String) {
      q._where.add(query, args);
    } else if (query is Map<String, dynamic>) {
      for (final entry in query.entries) {
        if (entry.value == null) {
          q._where.add('"${entry.key}" IS NULL');
        } else {
          q._where.add('"${entry.key}" = ?', [entry.value]);
        }
      }
    }
    return q;
  }

  /// Adds OR condition.
  QueryBuilder<T> or(String condition, [List<dynamic>? args]) {
    final q = clone();
    q._where.addOr(condition, args);
    return q;
  }

  /// Adds NOT condition.
  QueryBuilder<T> not(String condition, [List<dynamic>? args]) {
    final q = clone();
    q._where.add('NOT ($condition)', args);
    return q;
  }

  /// Adds JOIN clause.
  QueryBuilder<T> joins(String table, String onCondition, {String type = 'INNER JOIN'}) {
    final q = clone();
    q._joins.add(JoinClause(type, table, onCondition));
    return q;
  }

  /// Adds ORDER BY clause.
  QueryBuilder<T> order(String column, {bool ascending = true}) {
    final q = clone();
    q._orders.add(OrderClause(column, ascending));
    return q;
  }

  /// Adds GROUP BY columns.
  QueryBuilder<T> group(String column) {
    final q = clone();
    q._groupBy.add(column);
    return q;
  }

  /// Adds HAVING condition.
  QueryBuilder<T> having(String condition, [List<dynamic>? args]) {
    final q = clone();
    q._having = Clause(condition, args ?? []);
    return q;
  }

  /// Sets LIMIT clause.
  QueryBuilder<T> limit(int count) {
    final q = clone();
    q._limit = count;
    return q;
  }

  /// Sets OFFSET clause.
  QueryBuilder<T> offset(int count) {
    final q = clone();
    q._offset = count;
    return q;
  }

  /// Queries including soft-deleted records.
  QueryBuilder<T> unscoped() {
    final q = clone();
    q._unscoped = true;
    return q;
  }

  /// Preload association (Eager loading).
  QueryBuilder<T> preload(String associationName) {
    final q = clone();
    q._preloads.add(associationName);
    return q;
  }

  /// Compiles SQL SELECT statement and bound parameters.
  Clause buildSelect() {
    final sb = StringBuffer('SELECT ');
    if (_distinct) sb.write('DISTINCT ');

    if (_selectColumns.isEmpty) {
      sb.write('*');
    } else {
      sb.write(_selectColumns.join(', '));
    }

    sb.write(' FROM "$_table"');

    for (final j in _joins) {
      sb.write(' ${j.toSql()}');
    }

    // Handle soft delete if not unscoped
    final effectiveWhere = WhereBuilder();
    effectiveWhere.clauses.addAll(_where.clauses);

    if (!_unscoped && schema?.softDeleteColumn != null) {
      effectiveWhere.add('"${schema!.softDeleteColumn}" IS NULL');
    }

    final whereClause = effectiveWhere.build();
    final params = <dynamic>[];

    if (whereClause.sql.isNotEmpty) {
      sb.write(' WHERE ${whereClause.sql}');
      params.addAll(whereClause.params);
    }

    if (_groupBy.isNotEmpty) {
      sb.write(' GROUP BY ${_groupBy.join(', ')}');
    }

    if (_having != null) {
      sb.write(' HAVING ${_having!.sql}');
      params.addAll(_having!.params);
    }

    if (_orders.isNotEmpty) {
      sb.write(' ORDER BY ${_orders.map((o) => o.toSql()).join(', ')}');
    }

    if (_limit != null) {
      sb.write(' LIMIT $_limit');
    }

    if (_offset != null) {
      sb.write(' OFFSET $_offset');
    }

    return Clause(sb.toString(), params);
  }

  /// Compiles SQL COUNT statement.
  Clause buildCount() {
    final sb = StringBuffer('SELECT COUNT(*) as count FROM "$_table"');

    final effectiveWhere = WhereBuilder();
    effectiveWhere.clauses.addAll(_where.clauses);

    if (!_unscoped && schema?.softDeleteColumn != null) {
      effectiveWhere.add('"${schema!.softDeleteColumn}" IS NULL');
    }

    final whereClause = effectiveWhere.build();
    final params = <dynamic>[];

    if (whereClause.sql.isNotEmpty) {
      sb.write(' WHERE ${whereClause.sql}');
      params.addAll(whereClause.params);
    }

    return Clause(sb.toString(), params);
  }

  /// Compiles SQL UPDATE statement.
  Clause buildUpdate(Map<String, dynamic> data) {
    final sb = StringBuffer('UPDATE "$_table" SET ');
    final updates = <String>[];
    final params = <dynamic>[];

    data.forEach((key, value) {
      updates.add('"$key" = ?');
      params.add(value);
    });

    sb.write(updates.join(', '));

    final effectiveWhere = WhereBuilder();
    effectiveWhere.clauses.addAll(_where.clauses);

    if (!_unscoped && schema?.softDeleteColumn != null) {
      effectiveWhere.add('"${schema!.softDeleteColumn}" IS NULL');
    }

    final whereClause = effectiveWhere.build();
    if (whereClause.sql.isNotEmpty) {
      sb.write(' WHERE ${whereClause.sql}');
      params.addAll(whereClause.params);
    }

    return Clause(sb.toString(), params);
  }

  /// Compiles SQL DELETE statement.
  Clause buildDelete({bool forceHardDelete = false}) {
    if (!forceHardDelete && schema?.softDeleteColumn != null) {
      // Soft delete: UPDATE table SET deleted_at = CURRENT_TIMESTAMP
      final now = DateTime.now().toIso8601String();
      return buildUpdate({schema!.softDeleteColumn!: now});
    }

    final sb = StringBuffer('DELETE FROM "$_table"');
    final whereClause = _where.build();
    final params = <dynamic>[];

    if (whereClause.sql.isNotEmpty) {
      sb.write(' WHERE ${whereClause.sql}');
      params.addAll(whereClause.params);
    }

    return Clause(sb.toString(), params);
  }
}
