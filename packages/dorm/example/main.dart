import 'package:dorm/dorm.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// In a real project with code generation, these would be generated in `user.g.dart`:
class User extends DormModel with DormHooks {
  String name;
  int age;
  String email;

  User({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    required this.name,
    required this.age,
    required this.email,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'name': name,
        'age': age,
        'email': email,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        age: map['age'] as int? ?? 0,
        email: map['email'] as String? ?? '',
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
        deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
      );
}

void main() async {
  sqfliteFfiInit();

  // 1. Register model schema (usually done automatically by initDorm())
  SchemaRegistry.register<User>(
    ModelSchema<User>(
      modelType: User,
      tableName: 'users',
      primaryKey: 'id',
      softDeleteColumn: 'deleted_at',
      createdAtColumn: 'created_at',
      updatedAtColumn: 'updated_at',
      columns: {
        'id': ColumnMeta(name: 'id', sqlType: 'INTEGER', isPrimaryKey: true, autoIncrement: true),
        'name': ColumnMeta(name: 'name', sqlType: 'TEXT', isNullable: false),
        'age': ColumnMeta(name: 'age', sqlType: 'INTEGER'),
        'email': ColumnMeta(name: 'email', sqlType: 'TEXT', isUnique: true),
        'created_at': ColumnMeta(name: 'created_at', sqlType: 'TEXT'),
        'updated_at': ColumnMeta(name: 'updated_at', sqlType: 'TEXT'),
        'deleted_at': ColumnMeta(name: 'deleted_at', sqlType: 'TEXT'),
      },
      toMap: (u) => u.toMap(),
      fromMap: (m) => User.fromMap(m),
    ),
  );

  // 2. Open SQLite database with standard GORM/DORM logger enabled
  final db = await Dorm.openInMemory(
    options: DormOpenOptions(logger: DormLogger.standard),
  );

  // 3. Auto-migrate schema
  await db.autoMigrate([User]);

  // 4. Create records
  await db.create(User(name: 'Alice', age: 25, email: 'alice@example.com'));
  await db.createInBatches([
    User(name: 'Bob', age: 30, email: 'bob@example.com'),
    User(name: 'Charlie', age: 19, email: 'charlie@example.com'),
  ]);

  // 5. Query records
  final adults = await db
      .model<User>()
      .where('age >= ?', [21])
      .order('age', ascending: false)
      .find();

  // ignore: avoid_print
  print('Found ${adults.length} adult users.');

  // 6. Update
  await db.model<User>().where('name = ?', ['Alice']).update('age', 26);

  // 7. Soft Delete
  await db.model<User>().where('name = ?', ['Charlie']).delete();

  // 8. Transaction
  await db.transaction((tx) async {
    await tx.create(User(name: 'Diana', age: 28, email: 'diana@example.com'));
  });
}
