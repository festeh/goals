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
        onReorder: onReorder,
        children: List.generate(projects.length, (index) {
          final project = projects[index];
          return ReorderableDragStartListener(
            index: index,
            key: Key(project.id.toString()),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: getColor(project.color),
                radius: 10,
              ),
              title: Text(project.name),
              selected: selectedIndex == index,
              onTap: () => onProjectSelected(index),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(project);
                  } else if (value == 'delete') {
                    onDelete(project.id!);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
          );
        }),
      ),
    );
  }
}
