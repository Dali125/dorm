// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// DormGenerator
// **************************************************************************

/// Generated DORM Schema for [Todo]
final todoDormSchema = ModelSchema<Todo>(
  modelType: Todo,
  tableName: 'todos',
  primaryKey: 'id',
  softDeleteColumn: 'deleted_at',
  createdAtColumn: 'created_at',
  updatedAtColumn: 'updated_at',
  columns: {
    'id': ColumnMeta(
        name: 'id',
        sqlType: 'INTEGER',
        isPrimaryKey: true,
        autoIncrement: true),
    'created_at': ColumnMeta(name: 'created_at', sqlType: 'TEXT'),
    'updated_at': ColumnMeta(name: 'updated_at', sqlType: 'TEXT'),
    'deleted_at': ColumnMeta(name: 'deleted_at', sqlType: 'TEXT'),
    'title': ColumnMeta(name: 'title', sqlType: 'TEXT', isNullable: false),
    'is_completed':
        ColumnMeta(name: 'is_completed', sqlType: 'INTEGER', isNullable: false),
  },
  toMap: (model) => model.toMap(),
  fromMap: (map) => Todo.fromMap(map),
);

/// Extension providing DORM serialization & helpers for [Todo]
extension TodoDormExtension on Todo {
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
        if (deletedAt != null) 'deleted_at': deletedAt?.toIso8601String(),
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
      };
}

/// Deserializes a [Todo] from a SQLite map row.
Todo _$TodoFromMap(Map<String, dynamic> map) {
  final instance = Todo(
    title: map['title'] as String? ?? '',
    isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
  );
  instance.id = map['id'] as int?;
  instance.createdAt = map['created_at'] != null
      ? DateTime.tryParse(map['created_at'] as String)
      : null;
  instance.updatedAt = map['updated_at'] != null
      ? DateTime.tryParse(map['updated_at'] as String)
      : null;
  instance.deletedAt = map['deleted_at'] != null
      ? DateTime.tryParse(map['deleted_at'] as String)
      : null;
  return instance;
}

/// Auto-registers [Todo] into SchemaRegistry.
void registerTodoSchema() {
  SchemaRegistry.register<Todo>(todoDormSchema);
}
