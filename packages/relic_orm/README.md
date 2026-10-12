# Relic 🛋️

A fluent, GORM-inspired ORM for Flutter and Dart. Designed for rapid development with auto-migrations, an expressive query builder, lifecycle hooks, zero-boilerplate code generation, and structured SQL console logging.

---

## ✨ Features

- ⚡ **GORM-like Developer Experience**: Intuitive chainable queries (`where`, `or`, `not`, `order`, `limit`, `pluck`, `count`, etc.).
- 🚀 **Auto-Migration**: Automatically inspects, creates, and aligns SQLite tables with your Dart models via `db.autoMigrate([User])`.
- 🔍 **Aggregated Auto-Discovery**: Run `build_runner` once and call `initRelic()` to register all models in the project automatically.
- 🪵 **Structured SQL Logger**: Real-time ANSI-colored query execution latency (`ms`), rows affected, parameters, and slow query warnings.
- 🗑️ **Soft Deletes**: Native `deletedAt` filtering with `unscoped()` override.
- 🪝 **Lifecycle Hooks**: `beforeCreate`, `afterCreate`, `beforeUpdate`, `afterUpdate`, `beforeDelete`, `afterDelete`.
- 💳 **ACID Transactions**: Full transaction support with automatic rollbacks on exceptions.

---

## 📦 Installation

Add `relic` and `relic_orm_generator` to your `pubspec.yaml`:

```yaml
dependencies:
  relic: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.8
  relic_orm_generator: ^0.1.0
```

---

## 🚀 Quick Start

### 1. Define a Model

Create your model in `lib/models/user.dart`:

```dart
import 'package:relic_orm/relic_orm.dart';

part 'user.g.dart';

@RelicEntity()
class User extends RelicModel with RelicHooks {
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

Run the builder to generate serialization mappers and the aggregated `relic.init.dart` registry:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Initialize & Query

```dart
import 'package:relic_orm/relic_orm.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'relic.init.dart';
import 'models/user.dart';

void main() async {
  // 1. One-line auto-discovery: registers all @RelicEntity models
  initRelic();

  // 2. Open database with structured logger
  final dbPath = join(await getDatabasesPath(), 'app.db');
  final db = await Relic.open(
    dbPath,
    options: RelicOpenOptions(logger: RelicLogger.standard),
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

## 🔗 Foreign Keys & Relationships

### 1. Foreign Key Constraint (`@RelicColumn`)
Enforce SQLite foreign keys directly on a column:
```dart
@RelicEntity()
class Post extends RelicModel with RelicHooks {
  String title;

  @RelicColumn(foreignKey: 'users(id)', nullable: false)
  int userId;

  Post({super.id, required this.title, required this.userId});

  factory Post.fromMap(Map<String, dynamic> map) => _$PostFromMap(map);
}
```

### 2. Associations (`@HasMany` & `@BelongsTo`)
Define relational mappings for eager loading (`preload`) and joins:
```dart
@RelicEntity()
class User extends RelicModel with RelicHooks {
  String name;

  @Ignore()
  @HasMany(Post, foreignKey: 'user_id')
  List<Post>? posts;

  User({super.id, required this.name, this.posts});

  factory User.fromMap(Map<String, dynamic> map) => _$UserFromMap(map);
}
```

### 3. Querying Relationships
```dart
// Preload associated records
final usersWithPosts = await db.model<User>().preload('posts').find();

// Joins
final postsByUser = await db
    .model<Post>()
    .joins('users', 'users.id = posts.user_id')
    .where('users.name = ?', ['Alice'])
    .find();
```


---

## 🪵 Structured SQL Logger

Relic includes a built-in GORM-style console logger:

```text
[RELIC] (0.83ms)  CREATE TABLE IF NOT EXISTS "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT, ...);
[RELIC] (6.88ms) [rows: 1] INSERT INTO "users" ("name", "age") VALUES (?, ?) | params: [Alice, 25]
[RELIC] (0.73ms) [rows: 2] SELECT * FROM "users" WHERE age >= ? AND "deleted_at" IS NULL | params: [21]
[RELIC:SLOW QUERY] (245.10ms) [rows: 1200] SELECT * FROM "audit_logs"
```

To silence output in production:
```dart
final db = await Relic.open(
  dbPath,
  options: RelicOpenOptions(logger: RelicLogger.silent),
);
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
