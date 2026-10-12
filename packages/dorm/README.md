# Dorm 🛋️

A fluent, GORM-inspired ORM for Flutter and Dart. Designed for rapid development with auto-migrations, an expressive query builder, lifecycle hooks, zero-boilerplate code generation, and structured SQL console logging.

---

## ✨ Features

- ⚡ **GORM-like Developer Experience**: Intuitive chainable queries (`where`, `or`, `not`, `order`, `limit`, `pluck`, `count`, etc.).
- 🚀 **Auto-Migration**: Automatically inspects, creates, and aligns SQLite tables with your Dart models via `db.autoMigrate([User])`.
- 🔍 **Aggregated Auto-Discovery**: Run `build_runner` once and call `initDorm()` to register all models in the project automatically.
- 🪵 **Structured SQL Logger**: Real-time ANSI-colored query execution latency (`ms`), rows affected, parameters, and slow query warnings.
- 🗑️ **Soft Deletes**: Native `deletedAt` filtering with `unscoped()` override.
- 🪝 **Lifecycle Hooks**: `beforeCreate`, `afterCreate`, `beforeUpdate`, `afterUpdate`, `beforeDelete`, `afterDelete`.
- 💳 **ACID Transactions**: Full transaction support with automatic rollbacks on exceptions.

---

## 📦 Installation

Add `dorm` and `dorm_generator` to your `pubspec.yaml`:

```yaml
dependencies:
  dorm: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.8
  dorm_generator: ^0.1.0
```

---

## 🚀 Quick Start

### 1. Define a Model

Create your model in `lib/models/user.dart`:

```dart
import 'package:dorm/dorm.dart';

part 'user.g.dart';

@DormEntity()
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

  factory User.fromMap(Map<String, dynamic> map) => _$UserFromMap(map);
}
```

### 2. Generate Code

Run the builder to generate serialization mappers and the aggregated `dorm.init.dart` registry:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Initialize & Query

```dart
import 'package:dorm/dorm.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dorm.init.dart';
import 'models/user.dart';

void main() async {
  // 1. One-line auto-discovery: registers all @DormEntity models
  initDorm();

  // 2. Open database with structured logger
  final dbPath = join(await getDatabasesPath(), 'app.db');
  final db = await Dorm.open(
    dbPath,
    options: DormOpenOptions(logger: DormLogger.standard),
  );

  // 3. Auto-migrate tables
  await db.autoMigrate([User]);

  // 4. Create
  final aliceId = await db.create(User(name: 'Alice', age: 25, email: 'alice@example.com'));

  // 5. Query
  final users = await db
      .model<User>()
      .where('age >= ?', [21])
      .order('age', ascending: false)
      .limit(10)
      .find();

  // 6. Update
  await db.model<User>().where('name = ?', ['Alice']).update('age', 26);

  // 7. Soft Delete
  await db.model<User>().where('name = ?', ['Alice']).delete();

  // 8. Transactions
  await db.transaction((tx) async {
    await tx.create(User(name: 'Bob', age: 30, email: 'bob@example.com'));
  });
}
```

---

## 🪵 Structured SQL Logger

Dorm includes a built-in GORM-style console logger:

```text
[DORM] (0.83ms)  CREATE TABLE IF NOT EXISTS "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, ...);
[DORM] (6.88ms) [rows: 1] INSERT INTO "users" ("name", "age") VALUES (?, ?) | params: [Alice, 25]
[DORM] (0.73ms) [rows: 2] SELECT * FROM "users" WHERE age >= ? AND "deleted_at" IS NULL | params: [21]
[DORM:SLOW QUERY] (245.10ms) [rows: 1200] SELECT * FROM "audit_logs"
```

To silence output in production:
```dart
final db = await Dorm.open(
  dbPath,
  options: DormOpenOptions(logger: DormLogger.silent),
);
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
