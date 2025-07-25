import 'package:dimaist/models/note.dart';
import 'package:dimaist/widgets/notes_tab.dart';
import 'package:dimaist/widgets/tasks_tab.dart';
import 'package:flutter/material.dart';

class LeftBar extends StatefulWidget {
  final String? selectedView;
  final Function(String) onCustomViewSelected;
  final Function(Note) onNoteSelected;
  final VoidCallback onAddProject;
  final Widget projectList;

  const LeftBar({
    super.key,
    required this.selectedView,
    required this.onCustomViewSelected,
    required this.onNoteSelected,
    required this.onAddProject,
    required this.projectList,
  });

  @override
  State<LeftBar> createState() => _LeftBarState();
}

class _LeftBarState extends State<LeftBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
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
              padding: const EdgeInsets.only(top: 8.0),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tasks'),
                  Tab(text: 'Notes'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  TasksTab(
                    selectedView: widget.selectedView,
                    onCustomViewSelected: widget.onCustomViewSelected,
                    onAddProject: widget.onAddProject,
                    projectList: widget.projectList,
                  ),
                  NotesTab(onNoteSelected: widget.onNoteSelected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
