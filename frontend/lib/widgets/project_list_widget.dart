import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/color_utils.dart';

class ProjectList extends StatelessWidget {
  final List<Project> projects;
  final int selectedIndex;
  final Function(int) onProjectSelected;
  final Function(int, int) onReorder;

  const ProjectList({
    super.key,
    required this.projects,
    required this.selectedIndex,
    required this.onProjectSelected,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ReorderableListView(
        onReorder: onReorder,
        children: List.generate(projects.length, (index) {
          final project = projects[index];
          return ListTile(
            key: Key(project.id.toString()),
            leading: CircleAvatar(
              backgroundColor: getColor(project.color),
              radius: 10,
            ),
            title: Text(project.name),
            selected: selectedIndex == index,
            onTap: () => onProjectSelected(index),
          );
        }),
      ),
    );
  }
}
