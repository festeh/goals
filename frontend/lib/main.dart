import 'package:flutter/material.dart';
import 'models/project.dart';
import 'services/caching_service.dart';
import 'screens/task_screen.dart';
import 'services/api_service.dart';
import 'services/logging_service.dart';

void main() {
  LoggingService.setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goals App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final CachingService _cachingService = CachingService();
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await ApiService.getProjects();
      await ApiService.getTasks();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading initial data: $e')),
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
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Projects',
                          style: Theme.of(context).textTheme.headlineSmall),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _showAddProjectDialog,
                      ),
                    ],
                  ),
                ),
                if (_cachingService.projects.isNotEmpty)
                  Expanded(
                    child: NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations:
                          _cachingService.projects.map((project) {
                        return NavigationRailDestination(
                          icon: Icon(Icons.folder),
                          label: Text(project.name),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _cachingService.projects.isEmpty
                    ? Center(child: Text('No projects'))
                    : TaskScreen(
                        project: _cachingService.projects[_selectedIndex],
                      ),
          ),
        ],
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

