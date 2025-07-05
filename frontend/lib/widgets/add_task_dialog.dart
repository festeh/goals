import 'package:flutter/material.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/caching_service.dart';
import 'package:frontend/widgets/error_dialog.dart';

class AddTaskDialog extends StatefulWidget {
  final List<Project> projects;
  final Project? selectedProject;
  final VoidCallback onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.projects,
    this.selectedProject,
    required this.onTaskAdded,
  });

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
