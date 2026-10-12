/// Representation of SQL expressions, conditions, and clauses.
class Clause {
  final String sql;
  final List<dynamic> params;

  Clause(this.sql, [this.params = const []]);

  @override
  String toString() => 'Clause($sql, $params)';
}

/// Helper for building SQL WHERE conditions.
class WhereBuilder {
  final List<Clause> clauses = [];

  void add(String condition, [List<dynamic>? args]) {
    clauses.add(Clause(condition, args ?? []));
  }

  void addOr(String condition, [List<dynamic>? args]) {
    if (clauses.isEmpty) {
      clauses.add(Clause(condition, args ?? []));
    } else {
      clauses.add(Clause('OR $condition', args ?? []));
    }
  }

  bool get isEmpty => clauses.isEmpty;

  Clause build() {
    if (clauses.isEmpty) return Clause('');
    final sb = StringBuffer();
    final allParams = <dynamic>[];

    for (var i = 0; i < clauses.length; i++) {
      final c = clauses[i];
      if (i > 0) {
        if (!c.sql.trimLeft().toUpperCase().startsWith('OR ') &&
            !c.sql.trimLeft().toUpperCase().startsWith('AND ')) {
          sb.write(' AND ');
        } else {
          sb.write(' ');
        }
      }
      sb.write(c.sql);
      allParams.addAll(c.params);
    }

    return Clause(sb.toString(), allParams);
  }
}

/// SQL Join clause
class JoinClause {
  final String type; // INNER JOIN, LEFT JOIN, etc.
  final String table;
  final String onCondition;

  JoinClause(this.type, this.table, this.onCondition);

  String toSql() => '$type "$table" ON $onCondition';
}

/// SQL Order clause
class OrderClause {
  final String column;
  final bool ascending;

  OrderClause(this.column, [this.ascending = true]);

  String toSql() => '$column ${ascending ? 'ASC' : 'DESC'}';
}
