import 'package:dimaist/widgets/left_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tray_manager/tray_manager.dart';
import 'widgets/add_project_dialog.dart';
import 'widgets/custom_view_widget.dart';
import 'widgets/project_list_widget.dart';
import 'services/caching_service.dart';
import 'screens/task_screen.dart';
import 'services/api_service.dart';
import 'services/logging_service.dart';

import 'models/project.dart';
import 'widgets/edit_project_dialog.dart';
import 'widgets/error_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggingService.setup();
  await trayManager.setIcon('assets/infinite.png');
  Menu menu = Menu(
    items: [MenuItem(key: 'exit_app', label: 'Exit App')],
  );
  await trayManager.setContextMenu(menu);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dimaist',
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
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .copyWith(
              headlineSmall: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              bodyLarge: const TextStyle(fontSize: 16, color: Colors.white),
              bodyMedium: const TextStyle(fontSize: 14, color: Colors.white),
            ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'), // English, Great Britain
      ],
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
  String? _selectedCustomView = 'Today';
  int? _selectedProjectId;
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
      builder: (context) => ErrorDialog(error: error, onSync: _sync),
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
        if (_selectedProjectId == id) {
          _selectedCustomView = 'Today';
          _selectedProjectId = null;
        }
      });
    } catch (e) {
      _showErrorDialog('Error deleting project: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = _cachingService.projects;
    final selectedProjectIndex = _selectedProjectId != null
        ? projects.indexWhere((p) => p.id == _selectedProjectId)
        : -1;

    return Scaffold(
      body: Row(
        children: [
          LeftBar(
            selectedView: _selectedCustomView,
            onCustomViewSelected: (view) {
              setState(() {
                _selectedCustomView = view;
                _selectedProjectId = null;
              });
            },
            onAddProject: _showAddProjectDialog,
            projectList: ProjectList(
              projects: projects,
              selectedIndex: selectedProjectIndex,
              onProjectSelected: (index) {
                setState(() {
                  _selectedCustomView = null;
                  _selectedProjectId = projects[index].id;
                });
              },
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final project = projects.removeAt(oldIndex);
                  projects.insert(newIndex, project);
                });
                try {
                  await ApiService.reorderProjects(
                    projects.map((p) => p.id!).toList(),
                  );
                } catch (e) {
                  _showErrorDialog('Error reordering projects: $e');
                }
              },
              onEdit: _showEditProjectDialog,
              onDelete: _deleteProject,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTaskScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskScreen() {
    if (_selectedCustomView != null) {
      final view = CustomViewWidget.customViews
          .firstWhere((v) => v.name == _selectedCustomView);
      return TaskScreen(customView: view);
    }

    if (_selectedProjectId != null) {
      final project = _cachingService.projects
          .firstWhere((p) => p.id == _selectedProjectId);
      return TaskScreen(project: project);
    }

    return const Center(
      child: Text('Select a project or view'),
    );
  }
}
