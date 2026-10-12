# Relic 🛋️

A fluent, GORM-inspired ORM for Flutter and Dart. Designed for rapid development with auto-migrations, an expressive query builder, lifecycle hooks, zero-boilerplate code generation, and structured SQL console logging.

---

## 📁 Repository Structure

```
relic/
├── packages/
│   ├── relic/            # Core ORM runtime library
│   └── relic_orm_generator/  # Code generator for serialization & schema registry
└── example/              # Full Flutter Todo app demonstrating Relic
```

---

## ✨ Features

- ⚡ **GORM-like Developer Experience**: Intuitive chainable queries (`where`, `or`, `not`, `order`, `limit`, `pluck`, `count`, etc.).
- 🚀 **Auto-Migration**: Automatically inspects, creates, and aligns SQLite tables with your Dart models via `db.autoMigrate([User])`.
- 🔍 **Aggregated Auto-Discovery**: Run `build_runner` once and call `initRelic()` to register all models in the project automatically.
- 🪵 **Structured SQL Logger**: Real-time ANSI-colored query execution latency (`ms`), rows affected, parameters, and slow query warnings.
- 🔗 **Foreign Keys & Associations**: First-class support for `@RelicColumn(foreignKey: ...)`, `@HasMany`, `@BelongsTo`, and `preload()`.
- 🗑️ **Soft Deletes**: Native `deletedAt` filtering with `unscoped()` override.
- 🪝 **Lifecycle Hooks**: `beforeCreate`, `afterCreate`, `beforeUpdate`, `afterUpdate`, `beforeDelete`, `afterDelete`.
- 💳 **ACID Transactions**: Full transaction support with automatic rollbacks on exceptions.

---

## 📦 Packages

| Package | Description | Version |
| :--- | :--- | :--- |
| [`relic`](packages/relic) | Core fluent ORM runtime for Flutter and Dart | `^0.1.0` |
| [`relic_orm_generator`](packages/relic_orm_generator) | Builder for code generation and auto-discovery | `^0.1.0` |

---

## 🚀 Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  relic: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.8
  relic_orm_generator: ^0.1.0
```

### 2. Define a Model

```dart
import 'package:relic_orm/relic_orm.dart';

part 'todo.g.dart';

@RelicEntity()
class Todo extends RelicModel with RelicHooks {
  String title;
  bool isCompleted;

  Todo({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    required this.title,
    this.isCompleted = false,
  });

  factory Todo.fromMap(Map<String, dynamic> map) => _$TodoFromMap(map);
}
```

### 3. Generate Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Initialize and Query

```dart
import 'package:relic_orm/relic_orm.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'relic.init.dart';
import 'models/todo.dart';

void main() async {
  // 1. Auto-discover all models
  initRelic();

  // 2. Open DB with logger enabled
  final dbPath = join(await getDatabasesPath(), 'todos.db');
  final db = await Relic.open(
    dbPath,
    options: RelicOpenOptions(logger: RelicLogger.standard),
  );

  // 3. AutoMigrate
  await db.autoMigrate([Todo]);

  // 4. Create & Query
  await db.create(Todo(title: 'Build awesome Flutter apps with Relic'));
  final items = await db.model<Todo>().find();
}
```

---

## 🔗 Foreign Keys & Relationships

### Foreign Key Constraints (`@RelicColumn`)
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

### Associations (`@HasMany` & `@BelongsTo`)
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

Querying associated records:
```dart
// Preload eager-loading
final usersWithPosts = await db.model<User>().preload('posts').find();

// SQL Joins
final postsByUser = await db
    .model<Post>()
    .joins('users', 'users.id = posts.user_id')
    .where('users.name = ?', ['Alice'])
    .find();
```

---

## 📱 Interactive Example App

Check out the complete Flutter demo app under [`example/`](example/).

---

## 📄 License

MIT License. See [LICENSE](packages/relic/LICENSE) for details.
