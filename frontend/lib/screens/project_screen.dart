import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/caching_service.dart';

class ProjectScreen extends StatefulWidget {
  @override
  _ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final CachingService _cachingService = CachingService();

  Future<void> _deleteProject(int id) async {
    try {
      await ApiService.deleteProject(id);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting project: $e')),
      );
    }
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProjectDialog(onProjectAdded: () {
        setState(() {});
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: _cachingService.projects.length,
        itemBuilder: (context, index) {
          final project = _cachingService.projects[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(project.name),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteProject(project.id!),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        tooltip: 'Add Project',
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddProjectDialog extends StatefulWidget {
  final VoidCallback onProjectAdded;

  AddProjectDialog({required this.onProjectAdded});

  @override
  _AddProjectDialogState createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Project'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Project Name'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a project name';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final project = Project(name: _nameController.text);
                await ApiService.createProject(project);
                Navigator.of(context).pop();
                widget.onProjectAdded();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating project: $e')),
                );
              }
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
