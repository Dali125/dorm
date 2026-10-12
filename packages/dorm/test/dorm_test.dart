import 'package:flutter_test/flutter_test.dart';
import 'package:dorm/dorm.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Example User model implementing DormModel and DormHooks.
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
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );

  // Hook test counter
  static int beforeCreateCount = 0;

  @override
  void beforeCreate(Map<String, dynamic> data) {
    beforeCreateCount++;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();

    // Register User schema
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
  });

  test('AutoMigrate creates table and DORM CRUD operations', () async {
    final db = await Dorm.openInMemory();

    // 1. AutoMigrate
    await db.autoMigrate([User]);

    // 2. Create single record
    final id1 = await db.create(User(name: 'Alice', age: 25, email: 'alice@example.com'));
    expect(id1, isPositive);
    expect(User.beforeCreateCount, 1);

    // 3. Create batch
    final batchIds = await db.createInBatches([
      User(name: 'Bob', age: 30, email: 'bob@example.com'),
      User(name: 'Charlie', age: 20, email: 'charlie@example.com'),
    ]);
    expect(batchIds.length, 2);

    // 4. Find with Where & Order
    final adults = await db
        .model<User>()
        .where('age >= ?', [21])
        .order('age', ascending: false)
        .find();

    expect(adults.length, 2);
    expect(adults.first.name, 'Bob');
    expect(adults.last.name, 'Alice');

    // 5. First, Take, Last
    final firstUser = await db.model<User>().first();
    expect(firstUser?.name, 'Alice');

    final lastUser = await db.model<User>().last();
    expect(lastUser?.name, 'Charlie');

    // 6. Count
    final count = await db.model<User>().where('age > ?', [18]).count();
    expect(count, 3);

    // 7. Pluck
    final names = await db.model<User>().order('name', ascending: true).pluck('name');
    expect(names, ['Alice', 'Bob', 'Charlie']);

    // 8. Update & Updates
    await db.model<User>().where('name = ?', ['Alice']).update('age', 26);
    final updatedAlice = await db.model<User>().where('name = ?', ['Alice']).first();
    expect(updatedAlice?.age, 26);

    // 9. Soft Delete
    final deletedCount = await db.model<User>().where('name = ?', ['Charlie']).delete();
    expect(deletedCount, 1);

    // Finding normally excludes Charlie
    final usersAfterDelete = await db.model<User>().find();
    expect(usersAfterDelete.any((u) => u.name == 'Charlie'), isFalse);

    // Unscoped includes Charlie
    final allUsersUnscoped = await db.model<User>().unscoped().find();
    expect(allUsersUnscoped.any((u) => u.name == 'Charlie'), isTrue);

    // 10. Transactions
    await db.transaction((tx) async {
      await tx.create(User(name: 'Diana', age: 28, email: 'diana@example.com'));
    });

    final diana = await db.model<User>().where('name = ?', ['Diana']).first();
    expect(diana, isNotNull);
  });
}
