import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/project.dart';
import 'logging_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  static final _logger = LoggingService.logger;

  static Future<List<Task>> getTasks() async {
    _logger.info('Fetching tasks...');
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _logger.info('Tasks fetched successfully.');
        return data.map((json) => Task.fromJson(json)).toList();
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
        return Task.fromJson(json.decode(response.body));
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
      _logger.info('Task $id deleted successfully.');
    } catch (e) {
      _logger.severe('Error deleting task $id: $e');
      rethrow;
    }
  }

  static Future<List<Project>> getProjects() async {
    _logger.info('Fetching projects...');
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _logger.info('Projects fetched successfully.');
        return data.map((json) => Project.fromJson(json)).toList();
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
        return Project.fromJson(json.decode(response.body));
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
      _logger.info('Project $id deleted successfully.');
    } catch (e) {
      _logger.severe('Error deleting project $id: $e');
      rethrow;
    }
  }
}
