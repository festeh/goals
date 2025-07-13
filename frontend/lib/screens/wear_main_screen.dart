import 'package:flutter/material.dart';

class WearMainScreen extends StatelessWidget {
  const WearMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/recording');
          },
          backgroundColor: Colors.blue,
          heroTag: 'record_button',
          child: const Icon(Icons.mic, size: 40),
        ),
      ),
    );
  }
}
