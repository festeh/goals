import 'package:flutter/material.dart';

class DynamicCalendarIcon extends StatelessWidget {
  const DynamicCalendarIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().day;
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 24),
        Positioned(
          top: 6,
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
