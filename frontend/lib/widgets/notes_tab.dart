import 'package:dimaist/models/note.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:dimaist/widgets/note_detail_view.dart';
import 'package:dimaist/widgets/note_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final AppDatabase _db = AppDatabase();
  List<Note> _notes = [];
  Note? _selectedNote;

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
        if (_selectedNote != null) {
          final updatedSelectedNote = notes.firstWhere(
            (note) => note.id == _selectedNote!.id,
            orElse: () => notes.isNotEmpty ? notes.first : _selectedNote!,
          );
          _selectedNote = updatedSelectedNote;
        } else if (notes.isNotEmpty) {
          _selectedNote = notes.first;
        }
      });
    }
  }

  void _addNote() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('HH:mm, dd MMM').format(now);
    final newNote =
        await ApiService.createNote(Note(title: formattedDate, content: ""));
    await _db.insertNote(newNote);
    await _loadNotes();
    setState(() {
      _selectedNote = newNote;
    });
  }

  void _deleteNote(int id) async {
    await ApiService.deleteNote(id);
    await _db.deleteNote(id);
    _loadNotes();
  }

  void _selectNote(Note note) {
    setState(() {
      _selectedNote = note;
    });
  }

  void _saveNote(Note note) async {
    await ApiService.updateNote(note.id!, note);
    await _db.updateNote(note);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 248,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return NoteWidget(
                      note: note,
                      onDelete: () => _deleteNote(note.id!),
                      onTap: () => _selectNote(note),
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
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedNote != null
              ? NoteDetailView(
                  note: _selectedNote!,
                  onSave: _saveNote,
                )
              : const Center(
                  child: Text('Select a note to view'),
                ),
        ),
      ],
    );
  }
}
