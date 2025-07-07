import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/project.dart';
import '../utils/value_wrapper.dart';
import 'caching_service.dart';
import 'logging_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  static final _logger = LoggingService.logger;
  static final CachingService _cachingService = CachingService();

  static Future<List<Task>> getTasks() async {
    _logger.info('Fetching tasks...');
    final cachedTasks = await _cachingService.tasks;
    if (cachedTasks.isNotEmpty) {
      _logger.info('Tasks loaded from cache.');
      return cachedTasks;
    }
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final tasks = data.map((json) => Task.fromJson(json)).toList();
        _cachingService.setTasks(tasks);
        return tasks;
      } else {
        _logger.warning('Failed to load tasks: ${response.statusCode}');
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      _logger.severe('Error fetching tasks: $e');
      rethrow;
    }
  }

  static Future<Task> createTask(Task task) async {
    _logger.info('Creating task...');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      );
      if (response.statusCode == 200) {
        _logger.info('Task created successfully.');
        final newTask = Task.fromJson(json.decode(response.body));
        _cachingService.addTask(newTask);
        return newTask;
      } else {
        _logger.warning('Failed to create task: ${response.statusCode}');
        throw Exception('Failed to create task');
      }
    } catch (e) {
      _logger.severe('Error creating task: $e');
      rethrow;
    }
  }

  static Future<void> updateTask(int id, Task task) async {
    _logger.info('Updating task $id...');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      );
      if (response.statusCode != 200) {
        _logger.warning('Failed to update task $id: ${response.statusCode}');
        throw Exception('Failed to update task');
      }
      _cachingService.updateTask(task);
      _logger.info('Task $id updated successfully.');
    } catch (e) {
      _logger.severe('Error updating task $id: $e');
      rethrow;
    }
  }

  static Future<void> deleteTask(int id) async {
    _logger.info('Deleting task $id...');
    try {
      final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));
      if (response.statusCode != 200) {
        _logger.warning('Failed to delete task $id: ${response.statusCode}');
        throw Exception('Failed to delete task');
      }
      _cachingService.deleteTask(id);
      _logger.info('Task $id deleted successfully.');
    } catch (e) {
      _logger.severe('Error deleting task $id: $e');
      rethrow;
    }
  }

  static Future<List<Project>> getProjects() async {
    _logger.info('Fetching projects...');
    final cachedProjects = await _cachingService.projects;
    if (cachedProjects.isNotEmpty) {
      _logger.info('Projects loaded from cache.');
      return cachedProjects;
    }
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _logger.info('Projects fetched successfully. data: $data');
        final projects = data.map((json) => Project.fromJson(json)).toList();
        _cachingService.setProjects(projects);
        return projects;
      } else {
        _logger.warning('Failed to load projects: ${response.statusCode}');
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      _logger.severe('Error fetching projects: $e');
      rethrow;
    }
  }

  static Future<Project> createProject(Project project) async {
    _logger.info('Creating project...');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(project.toJson()),
      );
      if (response.statusCode == 200) {
        _logger.info('Project created successfully.');
        final newProject = Project.fromJson(json.decode(response.body));
        _cachingService.addProject(newProject);
        return newProject;
      } else {
        _logger.warning('Failed to create project: ${response.statusCode}');
        throw Exception('Failed to create project');
      }
    } catch (e) {
      _logger.severe('Error creating project: $e');
      rethrow;
    }
  }

  static Future<void> updateProject(int id, Project project) async {
    _logger.info('Updating project $id...');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/projects/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(project.toJson()),
      );
      if (response.statusCode != 200) {
        _logger.warning('Failed to update project $id: ${response.statusCode}');
        throw Exception('Failed to update project');
      }
      _cachingService.updateProject(project);
      _logger.info('Project $id updated successfully.');
    } catch (e) {
      _logger.severe('Error updating project $id: $e');
      rethrow;
    }
  }

  static Future<void> deleteProject(int id) async {
    _logger.info('Deleting project $id...');
    try {
      final response = await http.delete(Uri.parse('$baseUrl/projects/$id'));
      if (response.statusCode != 200) {
        _logger.warning('Failed to delete project $id: ${response.statusCode}');
        throw Exception('Failed to delete project');
      }
      _cachingService.deleteProject(id);
      _logger.info('Project $id deleted successfully.');
    } catch (e) {
      _logger.severe('Error deleting project $id: $e');
      rethrow;
    }
  }

  static Future<void> reorderProjects(List<int> projectIds) async {
    _logger.info('Reordering projects...', projectIds);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/projects-reorder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(projectIds),
      );
      if (response.statusCode != 200) {
        _logger.warning('Failed to reorder projects: ${response.statusCode}');
        throw Exception('Failed to reorder projects');
      }
      _logger.info('Projects reordered successfully.');
    } catch (e) {
      _logger.severe('Error reordering projects: $e');
      rethrow;
    }
  }

  static Future<void> reorderTasks(int projectId, List<int> taskIds) async {
    _logger.info('Reordering tasks for project $projectId...', taskIds);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/projects/$projectId/tasks/reorder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(taskIds),
      );
      if (response.statusCode != 200) {
        _logger.warning(
            'Failed to reorder tasks for project $projectId: ${response.statusCode}');
        throw Exception('Failed to reorder tasks');
      }
      _logger.info('Tasks for project $projectId reordered successfully.');
    } catch (e) {
      _logger.severe('Error reordering tasks for project $projectId: $e');
      rethrow;
    }
  }

  static Future<void> completeTask(int id) async {
    _logger.info('Completing task $id...');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$id/complete'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        _logger.info('Task $id completed successfully.');
        final tasks = await _cachingService.tasks;
        final task = tasks.firstWhere((task) => task.id == id);
        final updatedTask = task.copyWith(completedAt: ValueWrapper(DateTime.now()));
        await _cachingService.updateTask(updatedTask);
      } else {
        _logger.warning('Failed to complete task $id: ${response.statusCode}');
        throw Exception('Failed to complete task');
      }
    } catch (e) {
      _logger.severe('Error completing task $id: $e');
      rethrow;
    }
  }
}
