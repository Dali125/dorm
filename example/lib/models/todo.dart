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
