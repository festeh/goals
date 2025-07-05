import 'package:frontend/widgets/task_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/error_dialog.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/caching_service.dart';

class TaskScreen extends StatefulWidget {
  final Project? project;

  const TaskScreen({super.key, required this.project});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final CachingService _cachingService = CachingService();

  List<Task> get _tasksForProject {
    if (widget.project == null) {
      return [];
    }
    return _cachingService.tasks
        .where((task) => task.projectId == widget.project!.id)
        .toList();
  }

  List<Task> get _completedTasks {
    final tasks =
        _tasksForProject.where((task) => task.completedAt != null).toList();
    tasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return tasks;
  }

  List<Task> get _nonCompletedTasks {
    return _tasksForProject.where((task) => task.completedAt == null).toList();
  }

  Future<void> _sync() async {
    try {
      await ApiService.getTasks();
      setState(() {});
    } catch (e) {
      _showErrorDialog('Error syncing tasks: $e');
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onSync: _sync,
      ),
    );
  }

  Future<void> _deleteTask(int id) async {
    try {
      await ApiService.deleteTask(id);
      setState(() {});
    } catch (e) {
      _showErrorDialog('Error deleting task: $e');
    }
  }

  Future<void> _toggleComplete(Task task) async {
    final originalTask = task;
    final isCompleted = task.completedAt != null;
    final updatedTask = task.copyWith(
      completedAt: isCompleted ? null : DateTime.now(),
      completedAtIsNull: isCompleted,
    );

    _cachingService.updateTask(updatedTask);
    setState(() {});

    try {
      if (isCompleted) {
        await ApiService.updateTask(task.id!, updatedTask);
      } else {
        await ApiService.completeTask(task.id!);
      }
    } catch (e) {
      _cachingService.updateTask(originalTask);
      setState(() {});
      _showErrorDialog('Error toggling task completion: $e');
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        projects: _cachingService.projects,
        selectedProject: widget.project,
        onSave: (task) async {
          await ApiService.createTask(task);
          setState(() {});
        },
        title: 'Add New Task',
        submitButtonText: 'Add',
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        task: task,
        projects: _cachingService.projects,
        onSave: (updatedTask) async {
          await ApiService.updateTask(task.id!, updatedTask);
          setState(() {});
        },
        title: 'Edit Task',
        submitButtonText: 'Save',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.project == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_special, size: 64),
              const SizedBox(height: 16),
              Text(
                'No Project Selected',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a project to see the tasks.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tasks for ${widget.project!.name}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _tasksForProject.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click the "+" button to add your first task.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _nonCompletedTasks.length +
                  (_completedTasks.isNotEmpty ? _completedTasks.length + 1 : 0),
              itemBuilder: (context, index) {
                if (index < _nonCompletedTasks.length) {
                  final task = _nonCompletedTasks[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _showEditTaskDialog(task),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.completedAt != null,
                          onChanged: (value) => _toggleComplete(task),
                        ),
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.dueDate != null)
                                Text(
                                    'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}'),
                              if (task.labels.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: task.labels
                                        .map((label) => Chip(
                                              label: Text(label),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                side: BorderSide(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTask(task.id!),
                        ),
                      ),
                    ),
                  );
                } else if (index == _nonCompletedTasks.length &&
                    _completedTasks.isNotEmpty) {
                  return Column(
                    children: const [
                      Divider(
                        height: 32,
                        thickness: 2,
                        indent: 16,
                        endIndent: 16,
                      ),
                      Text('Completed tasks'),
                    ],
                  );
                } else {
                  final task =
                      _completedTasks[index - _nonCompletedTasks.length - 1];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _showEditTaskDialog(task),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.completedAt != null,
                          onChanged: (value) => _toggleComplete(task),
                        ),
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          task.description,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.dueDate != null)
                                Text(
                                    'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}'),
                              if (task.labels.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: task.labels
                                        .map((label) => Chip(
                                              label: Text(label),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                side: BorderSide(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTask(task.id!),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

