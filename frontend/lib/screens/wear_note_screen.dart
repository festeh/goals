import 'package:flutter/material.dart';
import 'package:dimaist/models/note.dart';

class WearNoteScreen extends StatelessWidget {
  final Note note;

  const WearNoteScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      // title: Text(
      //   note.title.isEmpty ? "Note" : note.title,
      //   overflow: TextOverflow.ellipsis,
      // ),
      // backgroundColor: Colors.black,
      // ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty)
              Text(
                note.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (note.title.isNotEmpty) const SizedBox(height: 16),
            Text(note.content, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
