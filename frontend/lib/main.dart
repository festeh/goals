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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading initial data: $e')));
    }
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProjectDialog(
        onProjectAdded: () {
          setState(() {});
        },
      ),
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
                      Text(
                        'My Projects',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _showAddProjectDialog,
                      ),
                    ],
                  ),
                ),
                if (_cachingService.projects.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cachingService.projects.length,
                      itemBuilder: (context, index) {
                        final project = _cachingService.projects[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(project.color),
                            radius: 10,
                          ),
                          title: Text(project.name),
                          selected: _selectedIndex == index,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        );
                      },
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
                : TaskScreen(project: _cachingService.projects[_selectedIndex]),
          ),
        ],
      ),
    );
  }
}

Color _getColor(String colorStr) {
  switch (colorStr.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'pink':
      return Colors.pink;
    case 'purple':
      return Colors.purple;
    case 'deep purple':
      return Colors.deepPurple;
    case 'indigo':
      return Colors.indigo;
    case 'blue':
      return Colors.blue;
    case 'teal':
      return Colors.teal;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    default:
      return Colors.transparent;
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
  String? _selectedColor;

  final Map<String, Color> _colorMap = {
    'Grey': Colors.grey,
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Deep Purple': Colors.deepPurple,
    'Indigo': Colors.indigo,
    'Blue': Colors.blue,
    'Teal': Colors.teal,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Brown': Colors.brown,
  };

  @override
  void initState() {
    super.initState();
    _selectedColor = _colorMap.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Project Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a project name';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: InputDecoration(labelText: 'Color'),
              items: _colorMap.keys.map((String colorName) {
                return DropdownMenuItem<String>(
                  value: colorName,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _colorMap[colorName],
                        radius: 10,
                      ),
                      SizedBox(width: 10),
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
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final project = Project(
                  name: _nameController.text,
                  color: _selectedColor!,
                );
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
