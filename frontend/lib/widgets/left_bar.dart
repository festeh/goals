import 'package:flutter/material.dart';
import 'package:dimaist/widgets/custom_view_widget.dart';

class LeftBar extends StatelessWidget {
  final String? selectedView;
  final Function(String) onCustomViewSelected;
  final VoidCallback onAddProject;
  final Widget projectList;

  const LeftBar({
    super.key,
    required this.selectedView,
    required this.onCustomViewSelected,
    required this.onAddProject,
    required this.projectList,
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
                    'Dimaist',
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
              selectedView: selectedView,
              onSelected: onCustomViewSelected,
            ),
            const Divider(),
            Expanded(child: projectList),
          ],
        ),
      ),
    );
  }
}
