import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteWidget extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const NoteWidget({
    super.key,
    required this.note,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}
