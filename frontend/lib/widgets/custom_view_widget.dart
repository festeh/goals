import 'package:dimaist/widgets/dynamic_calendar_icon.dart';
import 'package:flutter/material.dart';

class CustomView {
  final String name;
  final IconData icon;

  const CustomView({required this.name, required this.icon});
}

class CustomViewWidget extends StatelessWidget {
  static const List<CustomView> customViews = [
    CustomView(name: 'Today', icon: Icons.today),
  ];

  final String? selectedView;
  final Function(String) onSelected;

  const CustomViewWidget({
    super.key,
    required this.selectedView,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: customViews.map((view) {
        final isSelected = selectedView == view.name;
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).highlightColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => onSelected(view.name),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  if (view.name == 'Today')
                    const DynamicCalendarIcon()
                  else
                    Icon(view.icon, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      view.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
