import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// Core database service using SQLite for cross-platform persistence.
/// Manages Projects, Instances (work sessions), and Notes with time accumulation.
class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'project_tracking.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Projects table with accumulated time
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        totalMinutes INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        lastActiveAt TEXT
      )
    ''');

    // Instances table - work sessions with start/end times
    await db.execute('''
      CREATE TABLE instances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Notes table - multiple notes per instance
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        instanceId INTEGER NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (instanceId) REFERENCES instances (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_instances_projectId ON instances(projectId)');
    await db.execute('CREATE INDEX idx_notes_instanceId ON notes(instanceId)');
  }

  // Project operations
  Future<int> insertProject(Project project) async {
    final db = await database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final maps =
        await db.query('projects', orderBy: 'lastActiveAt DESC, name ASC');
    return maps.map((map) => Project.fromMap(map)).toList();
  }

  Future<Project?> getProject(int id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update('projects', project.toMap(),
        where: 'id = ?', whereArgs: [project.id]);
  }

  // Instance operations
  Future<int> insertInstance(Instance instance) async {
    final db = await database;
    return await db.insert('instances', instance.toMap());
  }

  Future<Instance?> getActiveInstance() async {
    final db = await database;
    final maps = await db.query(
      'instances',
      where: 'endTime IS NULL',
      orderBy: 'startTime DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Instance.fromMap(maps.first);
  }

  Future<List<Instance>> getInstancesForProject(int projectId) async {
    final db = await database;
    final maps = await db.query(
      'instances',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => Instance.fromMap(map)).toList();
  }

  Future<void> updateInstance(Instance instance) async {
    final db = await database;
    await db.update('instances', instance.toMap(),
        where: 'id = ?', whereArgs: [instance.id]);
  }

  // Note operations - only saved when not empty
  Future<int> insertNote(Note note) async {
    if (note.content.trim().isEmpty) {
      throw ArgumentError('Note content cannot be empty');
    }
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotesForInstance(int instanceId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'instanceId = ?',
      whereArgs: [instanceId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Get total minutes for a project on a specific date
  Future<int> getProjectMinutesForDate(int projectId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT SUM(durationMinutes) as total
      FROM instances
      WHERE projectId = ?
        AND endTime IS NOT NULL
        AND startTime >= ?
        AND startTime < ?
    ''', [projectId, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return _extractTotalMinutes(result);
  }

  /// Get total minutes for a project in a date range
  Future<int> getProjectMinutesInRange(
    int projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT SUM(durationMinutes) as total
      FROM instances
      WHERE projectId = ?
        AND endTime IS NOT NULL
        AND startTime >= ?
        AND startTime < ?
    ''', [projectId, startDate.toIso8601String(), endDate.toIso8601String()]);

    return _extractTotalMinutes(result);
  }

  /// Helper method to extract total minutes from query result
  int _extractTotalMinutes(List<Map<String, Object?>> result) {
    if (result.isEmpty) return 0;
    final total = result.first['total'];
    return total != null ? (total as num).toInt() : 0;
  }
}
