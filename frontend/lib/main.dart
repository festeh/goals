import 'package:flutter/material.dart';
import 'package:frontend/models/project.dart';
import 'package:frontend/widgets/edit_project_dialog.dart';
import 'package:frontend/widgets/error_dialog.dart';
import 'widgets/add_project_dialog.dart';
import 'widgets/project_list_widget.dart';
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
      title: 'My Goals',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6200EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.dark,
          secondary: const Color(0xFF03DAC6),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
        ),
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

  Future<void> _sync() async {
    setState(() {
      _isLoading = true;
    });
    await _loadInitialData();
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onSync: _sync,
      ),
    );
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
      _showErrorDialog('Error loading initial data: $e');
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

  void _showEditProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(
        project: project,
        onProjectUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteProject(int id) async {
    try {
      await ApiService.deleteProject(id);
      setState(() {
        if (_cachingService.projects.isNotEmpty) {
          _selectedIndex = 0;
        } else {
          _selectedIndex = -1;
        }
      });
    } catch (e) {
      _showErrorDialog('Error deleting project: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Projects',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _showAddProjectDialog,
                        ),
                      ],
                    ),
                  ),
                  if (_cachingService.projects.isNotEmpty)
                    ProjectList(
                      projects: _cachingService.projects,
                      selectedIndex: _selectedIndex,
                      onProjectSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      onReorder: (oldIndex, newIndex) async {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final project =
                              _cachingService.projects.removeAt(oldIndex);
                          _cachingService.projects.insert(newIndex, project);
                        });
                        try {
                          await ApiService.reorderProjects(_cachingService
                              .projects
                              .map((p) => p.id!)
                              .toList());
                        } catch (e) {
                          _showErrorDialog('Error reordering projects: $e');
                        }
                      },
                      onEdit: _showEditProjectDialog,
                      onDelete: _deleteProject,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cachingService.projects.isEmpty
                    ? Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No projects yet!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click the "+" button to add your first project.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ))
                    : TaskScreen(
                        project: _cachingService.projects.isNotEmpty
                            ? _cachingService.projects[_selectedIndex]
                            : null),
          ),
        ],
      ),
    );
  }
}
