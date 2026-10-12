typedef ModelSerializer<T> = Map<String, dynamic> Function(T model);
typedef ModelDeserializer<T> = T Function(Map<String, dynamic> map);

/// Schema metadata for a Model class.
class ModelSchema<T> {
  final Type modelType;
  final String tableName;
  final String primaryKey;
  final String? softDeleteColumn;
  final String? createdAtColumn;
  final String? updatedAtColumn;
  final Map<String, ColumnMeta> columns;
  final ModelSerializer<T> toMap;
  final ModelDeserializer<T> fromMap;
  final List<AssociationMeta> associations;

  ModelSchema({
    required this.modelType,
    required this.tableName,
    this.primaryKey = 'id',
    this.softDeleteColumn = 'deleted_at',
    this.createdAtColumn = 'created_at',
    this.updatedAtColumn = 'updated_at',
    required this.columns,
    required this.toMap,
    required this.fromMap,
    this.associations = const [],
  });

  /// Generates the SQL `CREATE TABLE IF NOT EXISTS` statement.
  String generateCreateTableSql() {
    final colDefs = <String>[];
    for (final entry in columns.entries) {
      colDefs.add(entry.value.toSqlDefinition());
    }
    return 'CREATE TABLE IF NOT EXISTS "$tableName" (${colDefs.join(', ')});';
  }

  /// Generates SQL create index statements if any columns specify indexes.
  List<String> generateIndexSql() {
    final stmts = <String>[];
    for (final entry in columns.entries) {
      final col = entry.value;
      if (col.index != null) {
        stmts.add('CREATE INDEX IF NOT EXISTS "${col.index}" ON "$tableName" ("${col.name}");');
      }
    }
    return stmts;
  }
}

/// Metadata for a single column.
class ColumnMeta {
  final String name;
  final String sqlType; // INTEGER, TEXT, REAL, BLOB
  final bool isPrimaryKey;
  final bool autoIncrement;
  final bool isNullable;
  final bool isUnique;
  final String? defaultValue;
  final String? index;
  final String? foreignKey;

  ColumnMeta({
    required this.name,
    required this.sqlType,
    this.isPrimaryKey = false,
    this.autoIncrement = false,
    this.isNullable = true,
    this.isUnique = false,
    this.defaultValue,
    this.index,
    this.foreignKey,
  });

  String toSqlDefinition() {
    final sb = StringBuffer('"$name" $sqlType');
    if (isPrimaryKey) {
      sb.write(' PRIMARY KEY');
      if (autoIncrement) {
        sb.write(' AUTOINCREMENT');
      }
    }
    if (!isNullable && !isPrimaryKey) {
      sb.write(' NOT NULL');
    }
    if (isUnique) {
      sb.write(' UNIQUE');
    }
    if (defaultValue != null) {
      sb.write(' DEFAULT $defaultValue');
    }
    if (foreignKey != null) {
      sb.write(' REFERENCES $foreignKey');
    }
    return sb.toString();
  }
}

/// Metadata for associations.
enum AssociationType { hasMany, belongsTo, manyToMany }

class AssociationMeta {
  final String fieldName;
  final Type targetType;
  final AssociationType type;
  final String foreignKey;
  final String? joinTable;
  final String? targetForeignKey;

  AssociationMeta({
    required this.fieldName,
    required this.targetType,
    required this.type,
    required this.foreignKey,
    this.joinTable,
    this.targetForeignKey,
  });
}

/// Global registry holding schema definitions for registered models.
class SchemaRegistry {
  static final Map<Type, ModelSchema<dynamic>> _schemas = {};

  static void register<T>(ModelSchema<T> schema) {
    _schemas[T] = schema;
  }

  static ModelSchema<T>? get<T>() {
    return _schemas[T] as ModelSchema<T>?;
  }

  static ModelSchema<dynamic>? getByType(Type type) {
    return _schemas[type];
  }

  static Iterable<ModelSchema<dynamic>> get allSchemas => _schemas.values;
}
