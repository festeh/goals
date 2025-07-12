import 'package:dimaist/widgets/custom_view_widget.dart';
import 'package:flutter/material.dart';

class TasksTab extends StatelessWidget {
  final String? selectedView;
  final Function(String) onCustomViewSelected;
  final VoidCallback onAddProject;
  final Widget projectList;

  const TasksTab({
    super.key,
    required this.selectedView,
    required this.onCustomViewSelected,
    required this.onAddProject,
    required this.projectList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomViewWidget(
          selectedView: selectedView,
          onSelected: onCustomViewSelected,
        ),
        const Divider(),
        Expanded(child: projectList),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Align(
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAddProject,
              tooltip: 'Add Project',
            ),
          ),
        ),
      ],
    );
  }
}
