import 'package:flutter/material.dart';

class CustomViewWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const CustomViewWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selectedIndex == -1
            ? Theme.of(context).highlightColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => onSelected(-1),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            children: [
              const Icon(Icons.today, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Today',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: selectedIndex == -1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
