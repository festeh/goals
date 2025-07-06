import 'package:dimaist/widgets/completed_task_widget.dart';
import 'package:dimaist/widgets/custom_view_widget.dart';
import 'package:dimaist/widgets/task_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:dimaist/widgets/error_dialog.dart';
import 'package:dimaist/widgets/task_widget.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/caching_service.dart';
import '../utils/value_wrapper.dart';

class TaskScreen extends StatefulWidget {
  final Project? project;
  final CustomView? customView;

  const TaskScreen({super.key, this.project, this.customView})
      : assert(project != null || customView != null);

  @override
  TaskScreenState createState() => TaskScreenState();
}

class TaskScreenState extends State<TaskScreen> {
  final CachingService _cachingService = CachingService();

  List<Task> get _tasks {
    if (widget.project != null) {
      return _cachingService.tasks
          .where((task) => task.projectId == widget.project!.id)
          .toList();
    } else if (widget.customView?.name == 'Today') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return _cachingService.tasks.where((task) {
        if (task.dueDate == null || task.completedAt != null) return false;
        final taskDueDate =
            DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return taskDueDate.isAtSameMomentAs(today);
      }).toList();
    } else if (widget.customView?.name == 'Next') {
      return _cachingService.tasks
          .where(
              (task) => task.labels.contains('next') && task.completedAt == null)
          .toList();
    }
    return [];
  }

  List<Task> get _completedTasks {
    if (widget.customView?.name == 'Today') {
      return [];
    }
    final tasks = _tasks.where((task) => task.completedAt != null).toList();
    tasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return tasks;
  }

  List<Task> get _nonCompletedTasks {
    return _tasks.where((task) => task.completedAt == null).toList();
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
    try {
      if (task.completedAt != null) {
        final updatedTask = task.copyWith(
          completedAt: const ValueWrapper(null),
        );
        await ApiService.updateTask(task.id!, updatedTask);
      } else {
        await ApiService.completeTask(task.id!);
      }
    } catch (e) {
      _showErrorDialog('Error toggling task completion: $e');
    } finally {
      setState(() {});
    }
  }

  void _showAddTaskDialog() {
    Project? selectedProject = widget.project;
    DateTime? defaultDueDate;

    if (widget.customView?.name == 'Today') {
      final inboxProject = _cachingService.projects.firstWhere(
        (p) => p.name == 'Inbox',
        orElse: () => _cachingService.projects.first,
      );
      selectedProject = inboxProject;
      defaultDueDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        projects: _cachingService.projects,
        selectedProject: selectedProject,
        defaultDueDate: defaultDueDate,
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

  String get _title {
    if (widget.project != null) {
      return 'Tasks for ${widget.project!.name}';
    }
    if (widget.customView != null) {
      return widget.customView!.name;
    }
    return 'Tasks';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    widget.customView?.name == 'Today'
                        ? 'No tasks for today'
                        : 'No tasks yet!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (widget.customView?.name != 'Today')
                    Text(
                      'Click the "+" button to add your first task.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                ],
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.all(8.0),
              itemCount: _nonCompletedTasks.length +
                  (_completedTasks.isNotEmpty ? _completedTasks.length + 1 : 0),
              itemBuilder: (context, index) {
                if (index < _nonCompletedTasks.length) {
                  final task = _nonCompletedTasks[index];
                  return ReorderableDragStartListener(
                    key: Key(task.id.toString()),
                    index: index,
                    child: TaskWidget(
                      task: task,
                      onToggleComplete: _toggleComplete,
                      onDelete: _deleteTask,
                      onEdit: _showEditTaskDialog,
                    ),
                  );
                } else if (index == _nonCompletedTasks.length &&
                    _completedTasks.isNotEmpty) {
                  return Column(
                    key: const Key('completed_tasks_header'),
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
                  return CompletedTaskWidget(
                    key: Key(task.id.toString()),
                    task: task,
                    onToggleComplete: _toggleComplete,
                    onDelete: _deleteTask,
                    onEdit: _showEditTaskDialog,
                  );
                }
              },
              onReorder: (oldIndex, newIndex) async {
                if (widget.project == null) return;
                if (oldIndex >= _nonCompletedTasks.length ||
                    newIndex > _nonCompletedTasks.length) {
                  return;
                }

                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }

                setState(() {
                  final reorderableTasks = _nonCompletedTasks;
                  final task = reorderableTasks.removeAt(oldIndex);
                  reorderableTasks.insert(newIndex, task);

                  final completedTasks = _completedTasks;
                  final newlyOrderedTasks = reorderableTasks + completedTasks;

                  for (int i = 0; i < newlyOrderedTasks.length; i++) {
                    final taskToUpdate = newlyOrderedTasks[i];
                    if (taskToUpdate.order != i) {
                      _cachingService
                          .updateTask(taskToUpdate.copyWith(order: i));
                    }
                  }
                });

                try {
                  final allProjectTaskIds = _cachingService.tasks
                      .where((t) => t.projectId == widget.project!.id)
                      .map((t) => t.id!)
                      .toList();
                  await ApiService.reorderTasks(
                      widget.project!.id!, allProjectTaskIds);
                } catch (e) {
                  _showErrorDialog('Error reordering tasks: $e');
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

