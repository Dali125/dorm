# Dorm Generator ⚙️

Code generator for [Dorm](https://pub.dev/packages/dorm).

Automatically generates:
- `ModelSchema<T>` schema column mappings and auto-migration metadata.
- `toMap()` extensions and `_$ModelFromMap()` deserialization factories.
- `registerXSchema()` registration hooks.
- `lib/dorm.init.dart` aggregated auto-discovery registry with a single `initDorm()` call.

---

## 📦 Installation

Add `dorm_generator` under `dev_dependencies` in your `pubspec.yaml`:

```yaml
dependencies:
  dorm: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.8
  dorm_generator: ^0.1.0
```

---

## 🚀 Usage

1. Mark your model with `@DormEntity()` and include the `part` directive:
```dart
import 'package:dorm/dorm.dart';

part 'user.g.dart';

@DormEntity()
class User extends DormModel with DormHooks {
  String name;
  int age;

  User({super.id, required this.name, required this.age});

  factory User.fromMap(Map<String, dynamic> map) => _$UserFromMap(map);
}
```

2. Run the generator:
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Initialize in your app:
```dart
import 'dorm.init.dart';

void main() async {
  initDorm(); // Auto-registers all @DormEntity models!
  ...
}
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
