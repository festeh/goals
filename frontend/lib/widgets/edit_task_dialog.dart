import 'package:flutter/material.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/error_dialog.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final List<Project> projects;
  final VoidCallback onTaskUpdated;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.projects,
    required this.onTaskUpdated,
  });

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _labelsController;
  late int? _selectedProjectId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.task.description);
    _labelsController = TextEditingController(text: widget.task.labels.join(', '));
    _selectedProjectId = widget.task.projectId;
    if (widget.task.dueDate != null) {
      _selectedDate = widget.task.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
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
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

                DateTime? dateTime;
                if (_selectedDate != null) {
                  dateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime?.hour ?? 0,
                    _selectedTime?.minute ?? 0,
                  );
                }

                final updatedTask = widget.task.copyWith(
                  description: _descriptionController.text,
                  projectId: _selectedProjectId!,
                  dueDate: dateTime,
                  labels: labels,
                  completedAtIsNull: dateTime == null && widget.task.dueDate != null,
                );

                await ApiService.updateTask(widget.task.id!, updatedTask);
                Navigator.of(context).pop();
                widget.onTaskUpdated();
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    error: 'Error updating task: $e',
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
