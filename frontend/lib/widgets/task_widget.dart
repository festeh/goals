import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskWidget extends StatelessWidget {
  final Task task;
  final Function(Task) onToggleComplete;
  final Function(int) onDelete;
  final Function(Task) onEdit;

  const TaskWidget({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onEdit(task),
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: ListTile(
          leading: Checkbox(
            value: task.completedAt != null,
            onChanged: (value) => onToggleComplete(task),
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
                      'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}')
                else if (task.dueDatetime != null)
                  Text(
                      'Due: ${task.dueDatetime!.toLocal().toString().split(' ')[0]} ${TimeOfDay.fromDateTime(task.dueDatetime!).format(context)}'),
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
                                    .withAlpha(51),
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
            onPressed: () => onDelete(task.id!),
          ),
        ),
      ),
    );
  }
}
