import 'package:flutter/material.dart';
import 'package:dimaist/models/project.dart';
import 'package:dimaist/widgets/custom_view_widget.dart';
import 'package:dimaist/widgets/project_list_widget.dart';

class LeftBar extends StatelessWidget {
  final List<Project> projects;
  final int selectedIndex;
  final Function(int) onProjectSelected;
  final Function(int, int) onReorder;
  final Function(Project) onEdit;
  final Function(int) onDelete;
  final VoidCallback onAddProject;

  const LeftBar({
    super.key,
    required this.projects,
    required this.selectedIndex,
    required this.onProjectSelected,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
    required this.onAddProject,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Projects',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onAddProject,
                  ),
                ],
              ),
            ),
            CustomViewWidget(
              selectedIndex: selectedIndex,
              onSelected: onProjectSelected,
            ),
            if (projects.isNotEmpty)
              ProjectList(
                projects: projects,
                selectedIndex: selectedIndex,
                onProjectSelected: onProjectSelected,
                onReorder: onReorder,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
