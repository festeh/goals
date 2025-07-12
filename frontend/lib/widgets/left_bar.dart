import 'package:dimaist/models/note.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:dimaist/widgets/add_note_dialog.dart';
import 'package:dimaist/widgets/edit_note_dialog.dart';
import 'package:dimaist/widgets/note_widget.dart';
import 'package:flutter/material.dart';
import 'package:dimaist/widgets/custom_view_widget.dart';

class LeftBar extends StatefulWidget {
  final String? selectedView;
  final Function(String) onCustomViewSelected;
  final VoidCallback onAddProject;
  final Widget projectList;

  const LeftBar({
    super.key,
    required this.selectedView,
    required this.onCustomViewSelected,
    required this.onAddProject,
    required this.projectList,
  });

  @override
  State<LeftBar> createState() => _LeftBarState();
}

class _LeftBarState extends State<LeftBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppDatabase _db = AppDatabase();
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _db.allNotes;
    setState(() {
      _notes = notes;
    });
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        onSave: (note) async {
          final newNote = await ApiService.createNote(note);
          await _db.insertNote(newNote);
          _loadNotes();
        },
      ),
    );
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tasks'),
                  Tab(text: 'Notes'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      CustomViewWidget(
                        selectedView: widget.selectedView,
                        onSelected: widget.onCustomViewSelected,
                      ),
                      const Divider(),
                      Expanded(child: widget.projectList),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: widget.onAddProject,
                            tooltip: 'Add Project',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
