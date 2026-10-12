import 'package:meta/meta.dart';

/// Marks a class as a database model representing a table in GORM.
@immutable
class Table {
  /// Custom table name. If null, a snake_case plural of the class name is used.
  final String? name;

  const Table({this.name});
}

/// Primary annotation to trigger the RELIC code generator on a model class.
@immutable
class RelicEntity {
  /// Optional custom table name. If not specified, snake_case plural is used.
  final String? tableName;

  const RelicEntity({this.tableName});
}

/// Backwards compatibility alias for [RelicEntity].
typedef GormEntity = RelicEntity;

/// Marks a field to be ignored/excluded from database mapping.
@immutable
class Ignore {
  const Ignore();
}

/// Relic model base class providing id, createdAt, updatedAt, and deletedAt fields.
class RelicModel {
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  RelicModel({this.id, this.createdAt, this.updatedAt, this.deletedAt});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
        if (deletedAt != null) 'deleted_at': deletedAt?.toIso8601String(),
      };
}

/// Backwards compatibility alias for [RelicModel].
typedef GormModel = RelicModel;

/// Marks a field with RELIC column configuration.
@immutable
class RelicColumn {
  /// Column name in the table. If null, field name is snake_cased.
  final String? name;

  /// Custom SQL data type (e.g. 'TEXT', 'INTEGER', 'REAL', 'BLOB').
  final String? type;

  /// Whether this column is the primary key.
  final bool primaryKey;

  /// Whether this column auto increments.
  final bool autoIncrement;

  /// Whether this column can be NULL.
  final bool nullable;

  /// Whether this column has a UNIQUE constraint.
  final bool unique;

  /// Default value as SQL string or literal.
  final String? defaultValue;

  /// Index name if this column should be indexed.
  final String? index;

  /// Foreign key definition (e.g. 'users(id)').
  final String? foreignKey;

  const RelicColumn({
    this.name,
    this.type,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.nullable = true,
    this.unique = false,
    this.defaultValue,
    this.index,
    this.foreignKey,
  });
}

/// Backwards compatibility alias for [RelicColumn].
typedef Column = RelicColumn;

/// Primary key column shorthand.
@immutable
class PrimaryKey extends Column {
  const PrimaryKey({
    super.name,
    super.type = 'INTEGER',
    super.autoIncrement = true,
  }) : super(primaryKey: true, nullable: false);
}

/// Soft-delete column annotation.
@immutable
class DeletedAt {
  final String name;
  const DeletedAt({this.name = 'deleted_at'});
}

/// CreatedAt column annotation.
@immutable
class CreatedAt {
  final String name;
  const CreatedAt({this.name = 'created_at'});
}

/// UpdatedAt column annotation.
@immutable
class UpdatedAt {
  final String name;
  const UpdatedAt({this.name = 'updated_at'});
}

/// One-to-Many association annotation.
@immutable
class HasMany {
  final Type target;
  final String foreignKey;

  const HasMany(this.target, {required this.foreignKey});
}

/// Belongs-To association annotation.
@immutable
class BelongsTo {
  final Type target;
  final String foreignKey;

  const BelongsTo(this.target, {required this.foreignKey});
}

/// Many-to-Many association annotation.
@immutable
class ManyToMany {
  final Type target;
  final String joinTable;
  final String foreignKey;
  final String targetForeignKey;

  const ManyToMany(
    this.target, {
    required this.joinTable,
    required this.foreignKey,
    required this.targetForeignKey,
  });
}
