import '../models/project.dart';
import '../models/task.dart';

class CachingService {
  static final CachingService _instance = CachingService._internal();

  factory CachingService() {
    return _instance;
  }

  CachingService._internal();

  List<Project> projects = [];
  List<Task> tasks = [];

  void setProjects(List<Project> projects) {
    this.projects = projects;
    this.projects.sort((a, b) => a.order.compareTo(b.order));
  }

  void setTasks(List<Task> tasks) {
    this.tasks = tasks;
    this.tasks.sort((a, b) => a.order.compareTo(b.order));
  }

  void addProject(Project project) {
    projects.add(project);
    projects.sort((a, b) => a.order.compareTo(b.order));
  }

  void updateProject(Project project) {
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      projects.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  void deleteProject(int projectId) {
    projects.removeWhere((p) => p.id == projectId);
  }

  void addTask(Task task) {
    tasks.add(task);
    tasks.sort((a, b) => a.order.compareTo(b.order));
  }

  void updateTask(Task task) {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      tasks.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  void deleteTask(int taskId) {
    tasks.removeWhere((t) => t.id == taskId);
  }
}
