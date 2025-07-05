import 'package:flutter/material.dart';
import 'package:frontend/widgets/error_dialog.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/caching_service.dart';

class TaskScreen extends StatefulWidget {
  final Project? project;

  TaskScreen({required this.project});

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

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        projects: _cachingService.projects,
        selectedProject: widget.project,
        onTaskAdded: () {
          setState(() {});
        },
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
              itemCount: _tasksForProject.length,
              itemBuilder: (context, index) {
                final task = _tasksForProject[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
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
                );
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

class AddTaskDialog extends StatefulWidget {
  final List<Project> projects;
  final Project? selectedProject;
  final VoidCallback onTaskAdded;

  AddTaskDialog(
      {required this.projects,
      this.selectedProject,
      required this.onTaskAdded});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _labelsController = TextEditingController();
  int? _selectedProjectId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final CachingService _cachingService = CachingService();

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.selectedProject?.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: 'Project'),
                items: widget.projects.map((project) {
                  return DropdownMenuItem<int>(
                    value: project.id,
                    child: Text(project.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProjectId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Due', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Text(_selectedDate?.toLocal().toString().split(' ')[0] ?? 'Select Date'),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    child: Text(_selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Select Time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelsController,
                decoration: const InputDecoration(
                  labelText: 'Labels (comma-separated)',
                  hintText: 'urgent, work, personal',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final labels = _labelsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final tasksForProject = _cachingService.tasks
                    .where((task) => task.projectId == _selectedProjectId)
                    .toList();
                final newOrder = (tasksForProject.isNotEmpty
                        ? tasksForProject
                            .map((t) => t.order)
                            .reduce((a, b) => a > b ? a : b)
                        : 0) +
                    1;

                DateTime? dateTime;
                if (_selectedDate != null && _selectedTime != null) {
                  dateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );
                }

                final task = Task(
                  description: _descriptionController.text,
                  projectId: _selectedProjectId!,
                  dueDate: dateTime,
                  labels: labels,
                  order: newOrder,
                );

                await ApiService.createTask(task);
                Navigator.of(context).pop();
                widget.onTaskAdded();
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    error: 'Error creating task: $e',
                    onSync: () async {
                      try {
                        await ApiService.getTasks();
                      } catch (e) {
                        // ignore
                      }
                    },
                  ),
                );
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

