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
