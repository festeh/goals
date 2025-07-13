import 'package:dimaist/models/note.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:dimaist/widgets/note_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotesTab extends StatefulWidget {
  final Function(Note) onNoteSelected;

  const NotesTab({super.key, required this.onNoteSelected});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final AppDatabase _db = AppDatabase();
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _db.allNotes;
    if (mounted) {
      setState(() {
        _notes = notes;
      });
    }
  }

  void _addNote() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('HH:mm, dd MMM').format(now);
    final newNote = await ApiService.createNote(Note(
      title: formattedDate,
      content: "",
      createdAt: now,
      updatedAt: now,
    ));
    await _db.insertNote(newNote);
    _loadNotes();
  }

  void _deleteNote(int id) async {
    await ApiService.deleteNote(id);
    await _db.deleteNote(id);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return NoteWidget(
                note: note,
                onDelete: () => _deleteNote(note.id!),
                onTap: () => widget.onNoteSelected(note),
              );
            },
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Align(
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addNote,
              tooltip: 'Add Note',
            ),
          ),
        ),
      ],
    );
  }
}
