import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String error;
  final VoidCallback onSync;

  const ErrorDialog({super.key, required this.error, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('An Error Occurred'),
      content: Text(error),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSync();
          },
          child: const Text('Sync'),
        ),
      ],
    );
  }
}
