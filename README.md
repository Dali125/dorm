# Dorm 🛋️

A fluent, GORM-inspired ORM for Flutter and Dart. Designed for rapid development with auto-migrations, an expressive query builder, lifecycle hooks, zero-boilerplate code generation, and structured SQL console logging.

---

## 📁 Repository Structure

```
dorm/
├── packages/
│   ├── dorm/            # Core ORM runtime library
│   └── dorm_generator/  # Code generator for serialization & schema registry
└── example/             # Full Flutter Todo app demonstrating Dorm
```

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

## 📦 Packages

| Package | Description | Version |
| :--- | :--- | :--- |
| [`dorm`](packages/dorm) | Core fluent ORM runtime for Flutter and Dart | `^0.1.0` |
| [`dorm_generator`](packages/dorm_generator) | Builder for code generation and auto-discovery | `^0.1.0` |

---

## 🚀 Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  dorm: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.8
  dorm_generator: ^0.1.0
```

### 2. Define a Model

```dart
import 'package:dorm/dorm.dart';

part 'todo.g.dart';

@DormEntity()
class Todo extends DormModel with DormHooks {
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
import 'package:dorm/dorm.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dorm.init.dart';
import 'models/todo.dart';

void main() async {
  // 1. Auto-discover all models
  initDorm();

  // 2. Open DB with logger enabled
  final dbPath = join(await getDatabasesPath(), 'todos.db');
  final db = await Dorm.open(
    dbPath,
    options: DormOpenOptions(logger: DormLogger.standard),
  );

  // 3. AutoMigrate
  await db.autoMigrate([Todo]);

  // 4. Create & Query
  await db.create(Todo(title: 'Build awesome Flutter apps with Dorm'));
  final items = await db.model<Todo>().find();
}
```

---

## 📱 Interactive Example App

Check out the complete Flutter demo app under [`example/`](example/).

---

## 📄 License

MIT License. See [LICENSE](packages/dorm/LICENSE) for details.
