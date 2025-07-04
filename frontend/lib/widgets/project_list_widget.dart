import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/color_utils.dart';

class ProjectList extends StatelessWidget {
  final List<Project> projects;
  final int selectedIndex;
  final Function(int) onProjectSelected;

  const ProjectList({
    super.key,
    required this.projects,
    required this.selectedIndex,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: getColor(project.color),
              radius: 10,
            ),
            title: Text(project.name),
            selected: selectedIndex == index,
            onTap: () => onProjectSelected(index),
          );
        },
      ),
    );
  }
}
