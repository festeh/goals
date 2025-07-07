import 'package:dimaist/services/app_database.dart' as db;
import '../models/project.dart';
import '../models/task.dart';

class CachingService {
  static final CachingService _instance = CachingService._internal();
  final db.AppDatabase _db = db.AppDatabase();

  factory CachingService() {
    return _instance;
  }

  CachingService._internal();

  Future<List<Project>> get projects => _db.allProjects;
  Future<List<Task>> get tasks => _db.allTasks;

  Future<void> loadFromDb() async {
    // No longer needed - data is queried directly from database
  }

  Future<void> setProjects(List<Project> projects) async {
    for (var project in projects) {
      await _db.insertProject(project);
    }
  }

  Future<void> setTasks(List<Task> tasks) async {
    for (var task in tasks) {
      await _db.insertTask(task);
    }
  }

  Future<void> addProject(Project project) async {
    await _db.insertProject(project);
  }

  Future<void> updateProject(Project project) async {
    await _db.updateProject(project);
  }

  Future<void> deleteProject(int projectId) async {
    await _db.deleteProject(projectId);
  }

  Future<void> addTask(Task task) async {
    await _db.insertTask(task);
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
  }

  Future<void> deleteTask(int taskId) async {
    await _db.deleteTask(taskId);
  }
}
