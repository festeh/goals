import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dimaist/models/project.dart' as project_model;
import 'package:dimaist/models/task.dart' as task_model;

part 'app_database.g.dart';

@UseRowClass(project_model.Project)
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get order => integer()();
  BoolColumn get isInbox => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().withDefault(const Constant('grey'))();
}

@UseRowClass(task_model.Task)
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  IntColumn get projectId => integer()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get dueDatetime => dateTime().nullable()();
  TextColumn get labels => text().map(const ListOfStringConverter()).nullable()();
  IntColumn get order => integer()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get reminders => text().map(const ListOfDateTimeConverter()).nullable()();
  TextColumn get recurrence => text().nullable()();
}

class ListOfStringConverter extends TypeConverter<List<String>?, String?> {
  const ListOfStringConverter();
  @override
  List<String>? fromSql(String? fromDb) {
    if (fromDb == null) return null;
    return fromDb.split(',');
  }

  @override
  String? toSql(List<String>? value) {
    if (value == null) return null;
    return value.join(',');
  }
}

class ListOfDateTimeConverter extends TypeConverter<List<DateTime>?, String?> {
  const ListOfDateTimeConverter();
  
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    
    try {
      String processedDateStr = dateStr;
      
      // Handle invalid dates like "0001-01-01T00:53:28+00:53"
      if (dateStr.startsWith('0001-01-01')) {
        return null;
      }
      
      // Fix malformed timezone formats
      if (dateStr.contains('+') && dateStr.length > 6) {
        // Handle +00:53 format (should be +00:53:00 or just skip)
        final tzMatch = RegExp(r'\+(\d{2}):(\d{2})$').firstMatch(dateStr);
        if (tzMatch != null) {
          final minutes = tzMatch.group(2)!;
          // If it's not a standard timezone offset, convert to UTC
          if (minutes != '00' && minutes != '30' && minutes != '45') {
            processedDateStr = dateStr.replaceFirst(RegExp(r'\+\d{2}:\d{2}$'), 'Z');
          }
        }
      }
      
      // Handle RFC3339 format like "2025-07-08 23:59:00+000"
      // Convert to proper ISO 8601 format
      if (dateStr.contains('+') && !dateStr.contains('T')) {
        processedDateStr = dateStr.replaceFirst(' ', 'T');
        // Fix timezone format: +000 -> +00:00
        if (processedDateStr.endsWith('+000')) {
          processedDateStr = processedDateStr.replaceFirst('+000', '+00:00');
        }
      }
      
      return DateTime.parse(processedDateStr);
    } catch (e) {
      // Fallback: try parsing as-is
      try {
        return DateTime.parse(dateStr);
      } catch (e2) {
        return null;
      }
    }
  }
  
  @override
  List<DateTime>? fromSql(String? fromDb) {
    if (fromDb == null || fromDb.trim().isEmpty) return null;
    return fromDb.split(',')
        .map((e) => _parseDate(e.trim()))
        .where((d) => d != null)
        .cast<DateTime>()
        .toList();
  }

  @override
  String? toSql(List<DateTime>? value) {
    if (value == null) return null;
    return value.map((e) => e.toIso8601String()).join(',');
  }
}

@DriftDatabase(tables: [Projects, Tasks])
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;
  
  AppDatabase._internal() : super(_openConnection());
  
  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  // Project methods
  Future<List<project_model.Project>> get allProjects => (select(projects)..orderBy([(p) => OrderingTerm(expression: p.order)])).get();

  Future<void> insertProject(project_model.Project project) => into(projects).insert(
    ProjectsCompanion.insert(
      id: project.id != null ? Value(project.id!) : const Value.absent(),
      name: project.name,
      order: project.order,
      isInbox: Value(project.isInbox),
      color: Value(project.color),
    )
  );

  Future<void> updateProject(project_model.Project project) => (update(projects)..where((p) => p.id.equals(project.id!))).write(
    ProjectsCompanion(
      name: Value(project.name),
      order: Value(project.order),
      isInbox: Value(project.isInbox),
      color: Value(project.color),
    )
  );

  Future<void> deleteProject(int id) => (delete(projects)..where((p) => p.id.equals(id))).go();
  
  Future<void> setProjects(List<project_model.Project> projectList) async {
    for (var project in projectList) {
      await insertProject(project);
    }
  }

  // Task methods
  Future<List<task_model.Task>> get allTasks => (select(tasks)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  
  Future<List<task_model.Task>> getTasksByProject(int projectId) =>
    (select(tasks)..where((t) => t.projectId.equals(projectId))..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  
  Future<List<task_model.Task>> getTodayTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    
    return (select(tasks)
      ..where((t) => t.completedAt.isNull() & t.dueDate.isNotNull() & t.dueDate.isBetweenValues(DateTime(1900), todayEnd))
      ..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  }
  
  Future<List<task_model.Task>> getUpcomingTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysFromNow = today.add(const Duration(days: 7));
    final tomorrow = today.add(const Duration(days: 1));
    
    return (select(tasks)
      ..where((t) {
        final dueDateClause = t.dueDate.isNotNull() & t.dueDate.isBetweenValues(tomorrow, sevenDaysFromNow);
        final dueDatetimeClause = t.dueDatetime.isNotNull() & t.dueDatetime.isBetweenValues(tomorrow, sevenDaysFromNow);
        return t.completedAt.isNull() & (dueDateClause | dueDatetimeClause);
      })
      ..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  }
  
  Future<List<task_model.Task>> getTasksByLabel(String label) =>
    (select(tasks)..where((t) => t.completedAt.isNull() & t.labels.like('%$label%'))..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  
  Future<task_model.Task?> getTaskById(int id) =>
    (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<List<task_model.Task>> getIncompleteTasks() =>
    (select(tasks)..where((t) => t.completedAt.isNull())..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  
  Future<List<task_model.Task>> getCompletedTasks() =>
    (select(tasks)..where((t) => t.completedAt.isNotNull())..orderBy([(t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc)])).get();
  
  Future<List<int>> getTaskIdsByProject(int projectId) async {
    final taskList = await (select(tasks)..where((t) => t.projectId.equals(projectId))..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
    return taskList.map((t) => t.id!).toList();
  }
  
  Future<bool> hasAnyTasks() async {
    final count = await (selectOnly(tasks)..addColumns([tasks.id.count()])).getSingle();
    return count.read(tasks.id.count())! > 0;
  }

  Future<void> insertTask(task_model.Task task) => into(tasks).insert(
    TasksCompanion.insert(
      id: task.id != null ? Value(task.id!) : const Value.absent(),
      description: task.description,
      projectId: task.projectId,
      dueDate: Value(task.dueDate),
      dueDatetime: Value(task.dueDatetime),
      labels: Value(task.labels),
      order: task.order,
      completedAt: Value(task.completedAt),
      reminders: Value(task.reminders),
      recurrence: Value(task.recurrence),
    )
  );

  Future<void> updateTask(task_model.Task task) => (update(tasks)..where((t) => t.id.equals(task.id!))).write(
    TasksCompanion(
      description: Value(task.description),
      projectId: Value(task.projectId),
      dueDate: Value(task.dueDate),
      dueDatetime: Value(task.dueDatetime),
      labels: Value(task.labels),
      order: Value(task.order),
      completedAt: Value(task.completedAt),
      reminders: Value(task.reminders),
      recurrence: Value(task.recurrence),
    )
  );

  Future<void> deleteTask(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();
  
  Future<void> setTasks(List<task_model.Task> taskList) async {
    for (var task in taskList) {
      await insertTask(task);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    // Also delete the database file on start to recreate it every time.
    if (await file.exists()) {
      await file.delete();
    }
    return NativeDatabase(file);
  });
}
