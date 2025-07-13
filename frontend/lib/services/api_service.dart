import 'dart:convert';
import 'package:dimaist/models/note.dart';
import 'package:dimaist/models/project.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../utils/value_wrapper.dart';
import 'app_database.dart';
import 'logging_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  static final _logger = LoggingService.logger;
  static final AppDatabase _db = AppDatabase();

  static Future<void> syncData() async {
    _logger.info('Syncing data...');
    final prefs = await SharedPreferences.getInstance();
    final syncToken = prefs.getString('sync_token');

    Uri uri = Uri.parse('$baseUrl/sync');
    if (syncToken != null) {
      uri = uri.replace(queryParameters: {'sync_token': syncToken});
      _logger.info('Syncing with token: $syncToken');
    } else {
      _logger.info('No sync token found, performing full sync.');
    }

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('ApiService.syncData: Response body: ${response.body}');
        final data = json.decode(response.body);
        print('ApiService.syncData: Parsed data: $data');
        
        final projectsData = data['projects'] as List?;
        print('ApiService.syncData: Projects data: $projectsData');
        final projects = (projectsData ?? []).map((p) {
          print('ApiService.syncData: Processing project: $p');
          try {
            return Project.fromJson(p);
          } catch (e) {
            print('ApiService.syncData: Error processing project $p: $e');
            rethrow;
          }
        }).toList();
        
        final tasksData = data['tasks'] as List?;
        print('ApiService.syncData: Tasks data: $tasksData');
        print('ApiService.syncData: Processing ${tasksData?.length ?? 0} tasks...');
        final tasks = (tasksData ?? []).map((t) {
          print('ApiService.syncData: Processing task: $t');
          try {
            return Task.fromJson(t);
          } catch (e) {
            print('ApiService.syncData: Error processing task $t: $e');
            rethrow;
          }
        }).toList();
        
        final newSyncToken = data['sync_token'];
        print('ApiService.syncData: New sync token: $newSyncToken');

        _logger.info(
          'Received ${projects.length} projects and ${tasks.length} tasks.',
        );

        print('ApiService.syncData: Upserting ${projects.length} projects...');
        for (var project in projects) {
          print('ApiService.syncData: Upserting project: $project');
          await _db.upsertProject(project);
        }
        
        print('ApiService.syncData: Upserting ${tasks.length} tasks...');
        for (var task in tasks) {
          print('ApiService.syncData: Upserting task: $task');
          await _db.upsertTask(task);
        }

        print('ApiService.syncData: Saving sync token: $newSyncToken');
        await prefs.setString('sync_token', newSyncToken);
        _logger.info('Sync completed. New sync token saved.');
      } else {
        _logger.severe('Failed to sync data: ${response.statusCode}');
        throw Exception('Failed to sync data');
      }
    } catch (e) {
      _logger.severe('Error during sync: $e');
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
        await _db.insertTask(newTask);
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
      await _db.updateTask(task);
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
      await _db.deleteTask(id);
      _logger.info('Task $id deleted successfully.');
    } catch (e) {
      _logger.severe('Error deleting task $id: $e');
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
        await _db.insertProject(newProject);
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
      await _db.updateProject(project);
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
      await _db.deleteProject(id);
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
          'Failed to reorder tasks for project $projectId: ${response.statusCode}',
        );
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
        final task = await _db.getTaskById(id);
        if (task == null) throw Exception('Task not found');
        final updatedTask = task.copyWith(
          completedAt: ValueWrapper(DateTime.now()),
        );
        await _db.updateTask(updatedTask);
      } else {
        _logger.warning('Failed to complete task $id: ${response.statusCode}');
        throw Exception('Failed to complete task');
      }
    } catch (e) {
      _logger.severe('Error completing task $id: $e');
      rethrow;
    }
  }

  static Future<Note> sendAudio(List<int> audioBytes) async {
    _logger.info('Sending audio...');
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai/audio'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'audio.wav',
        ),
      );
      final response = await request.send();
      if (response.statusCode == 200) {
        _logger.info('Audio sent successfully.');
        final responseBody = await response.stream.bytesToString();
        return Note.fromJson(json.decode(responseBody));
      } else {
        _logger.warning('Failed to send audio: ${response.statusCode}');
        throw Exception('Failed to send audio');
      }
    } catch (e) {
      _logger.severe('Error sending audio: $e');
      rethrow;
    }
  }

  static Future<List<Note>> getNotes() async {
    _logger.info('Fetching notes...');
    try {
      final response = await http.get(Uri.parse('$baseUrl/notes'));
      if (response.statusCode == 200) {
        final notes = (json.decode(response.body) as List)
            .map((data) => Note.fromJson(data))
            .toList();
        _logger.info('Notes fetched successfully.');
        return notes;
      } else {
        _logger.warning('Failed to fetch notes: ${response.statusCode}');
        throw Exception('Failed to fetch notes');
      }
    } catch (e) {
      _logger.severe('Error fetching notes: $e');
      rethrow;
    }
  }

  static Future<Note> createNote(Note note) async {
    _logger.info('Creating note...');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(note.toJson()),
      );
      if (response.statusCode == 200) {
        _logger.info('Note created successfully.');
        return Note.fromJson(json.decode(response.body));
      } else {
        _logger.warning('Failed to create note: ${response.statusCode}');
        throw Exception('Failed to create note');
      }
    } catch (e) {
      _logger.severe('Error creating note: $e');
      rethrow;
    }
  }

  static Future<void> updateNote(int id, Note note) async {
    _logger.info('Updating note $id...');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(note.toJson()),
      );
      if (response.statusCode != 200) {
        _logger.warning('Failed to update note $id: ${response.statusCode}');
        throw Exception('Failed to update note');
      }
      _logger.info('Note $id updated successfully.');
    } catch (e) {
      _logger.severe('Error updating note $id: $e');
      rethrow;
    }
  }

  static Future<void> deleteNote(int id) async {
    _logger.info('Deleting note $id...');
    try {
      final response = await http.delete(Uri.parse('$baseUrl/notes/$id'));
      if (response.statusCode != 200) {
        _logger.warning('Failed to delete note $id: ${response.statusCode}');
        throw Exception('Failed to delete note');
      }
      _logger.info('Note $id deleted successfully.');
    } catch (e) {
      _logger.severe('Error deleting note $id: $e');
      rethrow;
    }
  }
}
