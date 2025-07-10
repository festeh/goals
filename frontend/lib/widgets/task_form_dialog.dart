import 'package:flutter/material.dart';
import 'package:dimaist/models/project.dart';
import 'package:dimaist/models/task.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:dimaist/widgets/error_dialog.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task;
  final List<Project> projects;
  final Project? selectedProject;
  final DateTime? defaultDueDate;
  final Function(Task) onSave;
  final String title;
  final String submitButtonText;

  const TaskFormDialog({
    super.key,
    this.task,
    required this.projects,
    this.selectedProject,
    this.defaultDueDate,
    required this.onSave,
    required this.title,
    required this.submitButtonText,
  });

  @override
  TaskFormDialogState createState() => TaskFormDialogState();
}

class TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _labelsController;
  late TextEditingController _recurrenceController;
  int? _selectedProjectId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final AppDatabase _db = AppDatabase();
  List<String> _selectedReminders = [];

  final List<String> _reminderOptions = [
    '5 minutes',
    '30 minutes',
    '1 hour',
    '12 hours',
    '1 day',
    '1 week',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _labelsController = TextEditingController(
      text: task?.labels?.join(', ') ?? '',
    );
    _recurrenceController = TextEditingController(
      text: task?.recurrence ?? '',
    );
    _selectedProjectId = task?.projectId ?? widget.selectedProject?.id;
    if (task != null) {
      if (task.dueDatetime != null) {
        _selectedDate = task.dueDatetime;
        _selectedTime = TimeOfDay.fromDateTime(task.dueDatetime!);
      } else if (task.dueDate != null) {
        _selectedDate = task.dueDate;
      }
      if (task.reminders != null) {
        _selectedReminders = task.reminders!
            .map(
              (e) => _reminderStringFromDateTime(
                e,
                task.dueDatetime ?? task.dueDate!,
              ),
            )
            .toList();
      }
    } else if (widget.defaultDueDate != null) {
      _selectedDate = widget.defaultDueDate;
    }
  }

  String _reminderStringFromDateTime(DateTime reminder, DateTime dueDate) {
    final difference = dueDate.difference(reminder);
    if (difference.inDays >= 7) {
      return '${difference.inDays ~/ 7} week';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour';
    } else if (difference.inMinutes >= 30) {
      return '30 minutes';
    } else {
      return '5 minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                autofocus: true,
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
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                child: Text(
                  'Due',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Text(
                      _selectedDate?.toLocal().toString().split(' ')[0] ??
                          'Select Date',
                    ),
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
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                          _selectedDate ??= DateTime.now();
                        });
                      }
                    },
                    child: Text(
                      _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select Time',
                    ),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear date and time',
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _selectedTime = null;
                          _selectedReminders.clear();
                        });
                      },
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _recurrenceController,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  hintText: 'daily, weekly, etc.',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reminders',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _reminderOptions.map((reminder) {
                  final isEnabled = _selectedDate != null;
                  return FilterChip(
                    label: Text(reminder),
                    selected:
                        isEnabled && _selectedReminders.contains(reminder),
                    onSelected: isEnabled
                        ? (selected) {
                            setState(() {
                              if (selected) {
                                _selectedReminders.add(reminder);
                              } else {
                                _selectedReminders.remove(reminder);
                              }
                            });
                          }
                        : null,
                  );
                }).toList(),
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

                DateTime? dueDate;
                DateTime? dueDatetime;
                if (_selectedDate != null) {
                  if (_selectedTime != null) {
                    dueDatetime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );
                  } else {
                    dueDate = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      23,
                      59,
                    );
                  }
                }

                final tasksForProject = await _db.getTasksByProject(_selectedProjectId!);
                final newOrder =
                    (tasksForProject.isNotEmpty
                        ? tasksForProject
                              .map((t) => t.order)
                              .reduce((a, b) => a > b ? a : b)
                        : 0) +
                    1;

                List<DateTime> reminders = [];
                if (dueDatetime != null) {
                  for (final reminderString in _selectedReminders) {
                    reminders.add(
                      dueDatetime.subtract(_getDuration(reminderString)),
                    );
                  }
                } else if (dueDate != null) {
                  for (final reminderString in _selectedReminders) {
                    reminders.add(
                      dueDate.subtract(_getDuration(reminderString)),
                    );
                  }
                }

                final task = Task(
                  id: widget.task?.id,
                  description: _descriptionController.text,
                  projectId: _selectedProjectId!,
                  dueDate: dueDate,
                  dueDatetime: dueDatetime,
                  labels: labels,
                  order: widget.task?.order ?? newOrder,
                  completedAt: widget.task?.completedAt,
                  reminders: reminders,
                  recurrence: _recurrenceController.text,
                );

                await widget.onSave(task);
                Navigator.of(context).pop();
              } catch (e) {
                showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    error: 'Error saving task: $e',
                    onSync: () async {
                      try {
                        await ApiService.syncData();
                      } catch (e) {
                        // ignore
                      }
                    },
                  ),
                );
              }
            }
          },
          child: Text(widget.submitButtonText),
        ),
      ],
    );
  }

  Duration _getDuration(String reminderString) {
    final parts = reminderString.split(' ');
    final value = int.parse(parts[0]);
    final unit = parts[1];

    switch (unit) {
      case 'minutes':
        return Duration(minutes: value);
      case 'hour':
        return Duration(hours: value);
      case 'hours':
        return Duration(hours: value);
      case 'day':
        return Duration(days: value);
      case 'week':
        return Duration(days: value * 7);
      default:
        return Duration.zero;
    }
  }
}
