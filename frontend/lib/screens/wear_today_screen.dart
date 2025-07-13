import 'package:flutter/material.dart';
import 'package:dimaist/models/task.dart';
import 'package:dimaist/services/app_database.dart';

class WearTodayScreen extends StatefulWidget {
  const WearTodayScreen({super.key});

  @override
  State<WearTodayScreen> createState() => _WearTodayScreenState();
}

class _WearTodayScreenState extends State<WearTodayScreen> {
  final AppDatabase _db = AppDatabase();
  late Future<List<Task>> _todayTasks;

  @override
  void initState() {
    super.initState();
    _todayTasks = _db.getTodayTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
      ),
      body: FutureBuilder<List<Task>>(
        future: _todayTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks for today.'));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.description),
                subtitle: task.dueDate != null
                    ? Text(
                        'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}')
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/recording');
        },
        child: const Icon(Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
