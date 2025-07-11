import 'package:flutter/material.dart';
import 'package:dimaist/widgets/custom_view_widget.dart';

class LeftBar extends StatefulWidget {
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
                  Column(
                    children: [
                      CustomViewWidget(
                        selectedView: widget.selectedView,
                        onSelected: widget.onCustomViewSelected,
                      ),
                      const Divider(),
                      Expanded(child: widget.projectList),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: widget.onAddProject,
                            tooltip: 'Add Project',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(), // Empty container for Notes tab
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
