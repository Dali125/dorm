import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:relic/relic.dart' hide Column;

import 'relic.init.dart';
import 'models/todo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Relic schema discovery
  initRelic();

  // 2. Open SQLite Database
  final dbPath = join(await getDatabasesPath(), 'relic_example.db');
  final db = await Relic.open(
    dbPath,
    options: RelicOpenOptions(logger: RelicLogger.standard),
  );

  // 3. AutoMigrate tables
  await db.autoMigrate([Todo]);

  runApp(RelicExampleApp(db: db));
}

class RelicExampleApp extends StatelessWidget {
  final RelicDB db;

  const RelicExampleApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relic Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: TodoListPage(db: db),
    );
  }
}

class TodoListPage extends StatefulWidget {
  final RelicDB db;

  const TodoListPage({super.key, required this.db});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _controller = TextEditingController();
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    final results = await widget.db
        .model<Todo>()
        .order('id', ascending: false)
        .find();
    setState(() {
      _todos = results;
      _isLoading = false;
    });
  }

  Future<void> _addTodo() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    await widget.db.create(Todo(title: title));
    _controller.clear();
    await _loadTodos();
  }

  Future<void> _toggleTodo(Todo todo) async {
    final newStatus = !todo.isCompleted;
    await widget.db
        .model<Todo>()
        .where('id = ?', [todo.id])
        .update('is_completed', newStatus ? 1 : 0);
    await _loadTodos();
  }

  Future<void> _deleteTodo(Todo todo) async {
    await widget.db.model<Todo>().where('id = ?', [todo.id]).delete();
    await _loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relic Todos 🛋️'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'New Todo',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todos.isEmpty
                    ? const Center(child: Text('No todos yet. Add one!'))
                    : ListView.builder(
                        itemCount: _todos.length,
                        itemBuilder: (context, index) {
                          final todo = _todos[index];
                          return ListTile(
                            leading: Checkbox(
                              value: todo.isCompleted,
                              onChanged: (_) => _toggleTodo(todo),
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteTodo(todo),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
