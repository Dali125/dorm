import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dorm/dorm.dart';
import 'package:source_gen/source_gen.dart';

/// Generator that reads classes annotated with `@DormEntity` or `@Table`
/// and generates schema definitions, serialization (toMap / fromMap), and copyWith.
class DormGenerator extends GeneratorForAnnotation<DormEntity> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@DormEntity` can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final customTableName = annotation.peek('tableName')?.stringValue;
    final tableName = customTableName ?? _toSnakeCasePlural(className);

    // Extract fields
    final fields = _getEligibleFields(element);

    final buffer = StringBuffer();

    // 1. Generate Schema variable
    buffer.writeln('/// Generated DORM Schema for [$className]');
    buffer.writeln('final ${className.toLowerCase()}DormSchema = ModelSchema<$className>(');
    buffer.writeln('  modelType: $className,');
    buffer.writeln('  tableName: \'$tableName\',');
    buffer.writeln('  primaryKey: \'id\',');
    buffer.writeln('  softDeleteColumn: \'deleted_at\',');
    buffer.writeln('  createdAtColumn: \'created_at\',');
    buffer.writeln('  updatedAtColumn: \'updated_at\',');
    buffer.writeln('  columns: {');

    // Base DormModel columns
    buffer.writeln('    \'id\': ColumnMeta(name: \'id\', sqlType: \'INTEGER\', isPrimaryKey: true, autoIncrement: true),');
    buffer.writeln('    \'created_at\': ColumnMeta(name: \'created_at\', sqlType: \'TEXT\'),');
    buffer.writeln('    \'updated_at\': ColumnMeta(name: \'updated_at\', sqlType: \'TEXT\'),');
    buffer.writeln('    \'deleted_at\': ColumnMeta(name: \'deleted_at\', sqlType: \'TEXT\'),');

    for (final field in fields) {
      final colName = _toSnakeCase(field.name);
      final sqlType = _dartTypeToSql(field.type);
      final isNullable = field.type.nullabilitySuffix.toString().contains('question');
      buffer.writeln(
        '    \'$colName\': ColumnMeta(name: \'$colName\', sqlType: \'$sqlType\', isNullable: $isNullable),',
      );
    }

    buffer.writeln('  },');
    buffer.writeln('  toMap: (model) => model.toMap(),');
    buffer.writeln('  fromMap: (map) => $className.fromMap(map),');
    buffer.writeln(');');
    buffer.writeln();

    // 2. Generate helper extension on Model
    buffer.writeln('/// Extension providing DORM serialization & helpers for [$className]');
    buffer.writeln('extension ${className}DormExtension on $className {');

    // toMap()
    buffer.writeln('  Map<String, dynamic> toMap() => {');
    buffer.writeln('    if (id != null) \'id\': id,');
    buffer.writeln('    if (createdAt != null) \'created_at\': createdAt?.toIso8601String(),');
    buffer.writeln('    if (updatedAt != null) \'updated_at\': updatedAt?.toIso8601String(),');
    buffer.writeln('    if (deletedAt != null) \'deleted_at\': deletedAt?.toIso8601String(),');

    for (final field in fields) {
      final colName = _toSnakeCase(field.name);
      final fieldName = field.name;
      final type = field.type;

      if (_isDateTime(type)) {
        buffer.writeln('    \'$colName\': $fieldName?.toIso8601String(),');
      } else if (_isBool(type)) {
        final isNullable = type.nullabilitySuffix.toString().contains('question');
        if (isNullable) {
          buffer.writeln('    \'$colName\': $fieldName == null ? null : ($fieldName! ? 1 : 0),');
        } else {
          buffer.writeln('    \'$colName\': $fieldName ? 1 : 0,');
        }
      } else {
        buffer.writeln('    \'$colName\': $fieldName,');
      }
    }
    buffer.writeln('  };');
    buffer.writeln('}');
    buffer.writeln();

    // 3. Generate Helper factory/deserializer function
    buffer.writeln('/// Deserializes a [$className] from a SQLite map row.');
    buffer.writeln('$className _\$${className}FromMap(Map<String, dynamic> map) {');
    buffer.writeln('  final instance = $className(');

    for (final field in fields) {
      final colName = _toSnakeCase(field.name);
      final fieldName = field.name;
      final type = field.type;

      final readExpr = _generateReadExpression(colName, type);
      buffer.writeln('    $fieldName: $readExpr,');
    }

    buffer.writeln('  );');
    buffer.writeln('  instance.id = map[\'id\'] as int?;');
    buffer.writeln('  instance.createdAt = map[\'created_at\'] != null ? DateTime.tryParse(map[\'created_at\'] as String) : null;');
    buffer.writeln('  instance.updatedAt = map[\'updated_at\'] != null ? DateTime.tryParse(map[\'updated_at\'] as String) : null;');
    buffer.writeln('  instance.deletedAt = map[\'deleted_at\'] != null ? DateTime.tryParse(map[\'deleted_at\'] as String) : null;');
    buffer.writeln('  return instance;');
    buffer.writeln('}');
    buffer.writeln();

    // 4. Generate Auto-register call
    buffer.writeln('/// Auto-registers [$className] into SchemaRegistry.');
    buffer.writeln('void register${className}Schema() {');
    buffer.writeln('  SchemaRegistry.register<$className>(${className.toLowerCase()}DormSchema);');
    buffer.writeln('}');


    return buffer.toString();
  }

  List<FieldElement> _getEligibleFields(ClassElement element) {
    // Collect fields except id, createdAt, updatedAt, deletedAt, or static/ignored
    final ignoreType = const TypeChecker.fromRuntime(Ignore);
    final results = <FieldElement>[];

    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) continue;
      if (['id', 'createdAt', 'updatedAt', 'deletedAt'].contains(field.name)) continue;
      if (ignoreType.hasAnnotationOf(field)) continue;
      results.add(field);
    }

    return results;
  }

  String _generateReadExpression(String colName, DartType type) {
    if (_isInt(type)) {
      return '(map[\'$colName\'] as num?)?.toInt() ?? 0';
    } else if (_isDouble(type) || _isNum(type)) {
      return '(map[\'$colName\'] as num?)?.toDouble() ?? 0.0';
    } else if (_isString(type)) {
      return 'map[\'$colName\'] as String? ?? \'\'';
    } else if (_isBool(type)) {
      return 'map[\'$colName\'] == 1 || map[\'$colName\'] == true';
    } else if (_isDateTime(type)) {
      return 'map[\'$colName\'] != null ? DateTime.tryParse(map[\'$colName\'] as String) : null';
    } else {
      return 'map[\'$colName\']';
    }
  }

  String _dartTypeToSql(DartType type) {
    if (_isInt(type) || _isBool(type)) return 'INTEGER';
    if (_isDouble(type) || _isNum(type)) return 'REAL';
    return 'TEXT';
  }

  String _toSnakeCase(String str) {
    return str.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  String _toSnakeCasePlural(String str) {
    final snake = _toSnakeCase(str);
    if (snake.endsWith('s')) return snake;
    if (snake.endsWith('y') && !snake.endsWith('ey') && !snake.endsWith('ay')) {
      return '${snake.substring(0, snake.length - 1)}ies';
    }
    return '${snake}s';
  }

  bool _isType(DartType type, String target) {
    final name = type.element?.name ?? type.getDisplayString(withNullability: false);
    return name == target;
  }

  bool _isDateTime(DartType type) => _isType(type, 'DateTime');
  bool _isBool(DartType type) => _isType(type, 'bool');
  bool _isInt(DartType type) => _isType(type, 'int');
  bool _isDouble(DartType type) => _isType(type, 'double');
  bool _isNum(DartType type) => _isType(type, 'num');
  bool _isString(DartType type) => _isType(type, 'String');
}
