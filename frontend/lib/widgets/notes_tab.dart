import 'package:dimaist/models/note.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:dimaist/widgets/edit_note_dialog.dart';
import 'package:dimaist/widgets/note_widget.dart';
import 'package:flutter/material.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

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
    final newNote =
        await ApiService.createNote(Note(title: "", content: ""));
    await _db.insertNote(newNote);
    _loadNotes();
  }

  void _editNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => EditNoteDialog(
        note: note,
        onSave: (updatedNote) async {
          await ApiService.updateNote(updatedNote.id!, updatedNote);
          await _db.updateNote(updatedNote);
          _loadNotes();
        },
      ),
    );
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
                onEdit: () => _editNote(note),
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
