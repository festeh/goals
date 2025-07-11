import 'package:flutter/material.dart';
import 'package:dimaist/screens/wear_today_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goals - Wear',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.compact,
      ),
      home: const WearTodayScreen(),
    );
  }
}
