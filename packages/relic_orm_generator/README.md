# Relic Generator ⚙️

Code generator for [Relic](https://pub.dev/packages/relic).

Automatically generates:
- `ModelSchema<T>` schema column mappings and auto-migration metadata.
- `toMap()` extensions and `_$ModelFromMap()` deserialization factories.
- `registerXSchema()` registration hooks.
- `lib/relic.init.dart` aggregated auto-discovery registry with a single `initRelic()` call.

---

## 📦 Installation

Add `relic_orm_generator` under `dev_dependencies` in your `pubspec.yaml`:

```yaml
dependencies:
  relic: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.8
  relic_orm_generator: ^0.1.0
```

---

## 🚀 Usage

1. Mark your model with `@RelicEntity()` and include the `part` directive:
```dart
import 'package:relic_orm/relic_orm.dart';

part 'user.g.dart';

@RelicEntity()
class User extends RelicModel with RelicHooks {
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
import 'relic.init.dart';

void main() async {
  initRelic(); // Auto-registers all @RelicEntity models!
  ...
}
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
