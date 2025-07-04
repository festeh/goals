import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/color_utils.dart';

class ProjectList extends StatelessWidget {
  final List<Project> projects;
  final int selectedIndex;
  final Function(int) onProjectSelected;
  final Function(int, int) onReorder;
  final Function(Project) onEdit;
  final Function(int) onDelete;

  const ProjectList({
    super.key,
    required this.projects,
    required this.selectedIndex,
    required this.onProjectSelected,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ReorderableListView(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        onReorder: onReorder,
        children: List.generate(projects.length, (index) {
          final project = projects[index];
          return ReorderableDragStartListener(
            index: index,
            key: Key(project.id.toString()),
            child: Card(
              elevation: selectedIndex == index ? 8 : 2,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: selectedIndex == index
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: getColor(project.color),
                  radius: 12,
                ),
                title: Text(
                  project.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: selectedIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
                onTap: () => onProjectSelected(index),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(project);
                    } else if (value == 'delete') {
                      onDelete(project.id!);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
