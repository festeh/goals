import 'package:dimaist/widgets/completed_task_widget.dart';
import 'package:dimaist/widgets/custom_view_widget.dart';
import 'package:dimaist/widgets/task_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:dimaist/widgets/error_dialog.dart';
import 'package:dimaist/widgets/task_widget.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/app_database.dart';
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
  final AppDatabase _db = AppDatabase();

  void showAddTaskDialog() {
    _showAddTaskDialog();
  }

  Future<List<Task>> get _tasks async {
    if (widget.project != null && widget.project!.id != null) {
      return await _db.getTasksByProject(widget.project!.id!);
    } else if (widget.customView?.name == 'Today') {
      return await _db.getTodayTasks();
    } else if (widget.customView?.name == 'Upcoming') {
      return await _db.getUpcomingTasks();
    } else if (widget.customView?.name == 'Next') {
      return await _db.getTasksByLabel('next');
    }
    return [];
  }

  // These getters are now handled directly in the FutureBuilder

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

  void _showAddTaskDialog() async {
    Project? selectedProject = widget.project;
    DateTime? defaultDueDate;

    if (widget.customView?.name == 'Today') {
      final projects = await _db.allProjects;
      final inboxProject = projects.firstWhere(
        (p) => p.name == 'Inbox',
        orElse: () => projects.first,
      );
      selectedProject = inboxProject;
      defaultDueDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Project>>(
        future: _db.allProjects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox.shrink());
          }
          return TaskFormDialog(
            projects: snapshot.data ?? [],
            selectedProject: selectedProject,
            defaultDueDate: defaultDueDate,
            onSave: (task) async {
              await ApiService.createTask(task);
              setState(() {});
            },
            title: 'Add New Task',
            submitButtonText: 'Add',
          );
        },
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Project>>(
        future: _db.allProjects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox.shrink());
          }
          return TaskFormDialog(
            task: task,
            projects: snapshot.data ?? [],
            onSave: (updatedTask) async {
              await ApiService.updateTask(task.id!, updatedTask);
              setState(() {});
            },
            title: 'Edit Task',
            submitButtonText: 'Save',
          );
        },
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
    return FutureBuilder<List<Task>>(
      future: _tasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const SizedBox.shrink(),
            floatingActionButton: FloatingActionButton(
              onPressed: _showAddTaskDialog,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        final tasks = snapshot.data ?? [];
        final nonCompletedTasks = tasks.where((task) => task.completedAt == null).toList();
        final completedTasks = widget.customView?.name == 'Today' 
            ? <Task>[]
            : tasks.where((task) => task.completedAt != null).toList();
        completedTasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: tasks.isEmpty
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
                  itemCount: nonCompletedTasks.length +
                      (completedTasks.isNotEmpty ? completedTasks.length + 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < nonCompletedTasks.length) {
                      final task = nonCompletedTasks[index];
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
                    } else if (index == nonCompletedTasks.length &&
                        completedTasks.isNotEmpty) {
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
                          completedTasks[index - nonCompletedTasks.length - 1];
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
                    if (oldIndex >= nonCompletedTasks.length ||
                        newIndex > nonCompletedTasks.length) {
                      return;
                    }

                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }

                    final reorderableTasks = List<Task>.from(nonCompletedTasks);
                    final task = reorderableTasks.removeAt(oldIndex);
                    reorderableTasks.insert(newIndex, task);

                    final newlyOrderedTasks = reorderableTasks + completedTasks;

                    for (int i = 0; i < newlyOrderedTasks.length; i++) {
                      final taskToUpdate = newlyOrderedTasks[i];
                      if (taskToUpdate.order != i) {
                        await _db.updateTask(taskToUpdate.copyWith(order: i));
                      }
                    }

                    try {
                      final allProjectTaskIds = await _db.getTaskIdsByProject(widget.project!.id!);
                      await ApiService.reorderTasks(
                          widget.project!.id!, allProjectTaskIds);
                    } catch (e) {
                      _showErrorDialog('Error reordering tasks: $e');
                    }
                    setState(() {});
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskDialog,
            tooltip: 'Add Task',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

