import 'package:flutter/material.dart';

const Map<String, Color> colorMap = {
  'gray': Colors.grey,
  'Grey': Colors.grey,
  'Red': Colors.red,
  'Pink': Colors.pink,
  'Purple': Colors.purple,
  'Deep Purple': Colors.deepPurple,
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'Brown': Colors.brown,
};

Color getColor(String colorStr) {
  return colorMap[colorStr] ?? Colors.transparent;
}
