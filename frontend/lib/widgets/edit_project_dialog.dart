import 'package:flutter/material.dart';
import 'package:dimaist/models/project.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/utils/color_utils.dart';

class EditProjectDialog extends StatefulWidget {
  final Project project;
  final VoidCallback onProjectUpdated;

  const EditProjectDialog(
      {super.key, required this.project, required this.onProjectUpdated});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _selectedColor = widget.project.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a project name';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(labelText: 'Color'),
              items: colorMap.keys.map((String colorName) {
                return DropdownMenuItem<String>(
                  value: colorName,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorMap[colorName],
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedColor = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a color';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final updatedProject = Project(
                  id: widget.project.id,
                  name: _nameController.text,
                  color: _selectedColor!,
                  order: widget.project.order,
                );
                await ApiService.updateProject(
                    widget.project.id!, updatedProject);
                Navigator.of(context).pop();
                widget.onProjectUpdated();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating project: $e')),
                );
              }
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}