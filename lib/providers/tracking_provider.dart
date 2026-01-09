import 'package:flutter/foundation.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';
import 'package:project_tracking/models/time_display_mode.dart';
import 'package:project_tracking/services/database_service.dart';
import 'package:project_tracking/services/file_logging_service.dart';

/// Central state management for tracking operations.
/// Coordinates database and file logging in sync.
class TrackingProvider with ChangeNotifier {
  final DatabaseService dbService;
  final FileLoggingService fileService;

  List<Project> _projects = [];
  Instance? _activeInstance;
  Project? _activeProject;
  List<Note> _currentNotes = [];
  TimeDisplayMode _timeDisplayMode = TimeDisplayMode.project;

  TrackingProvider({required this.dbService, required this.fileService}) {
    _initialize();
  }

  List<Project> get projects => _projects;
  Instance? get activeInstance => _activeInstance;
  Project? get activeProject => _activeProject;
  List<Note> get currentNotes => _currentNotes;
  bool get hasActiveInstance => _activeInstance != null;
  TimeDisplayMode get timeDisplayMode => _timeDisplayMode;

  Future<void> _initialize() async {
    await loadProjects();
    await _loadActiveInstance();
  }

  Future<void> loadProjects() async {
    _projects = await dbService.getAllProjects();
    notifyListeners();
  }

  Future<void> _loadActiveInstance() async {
    _activeInstance = await dbService.getActiveInstance();
    if (_activeInstance != null) {
      _activeProject = await dbService.getProject(_activeInstance!.projectId);
      _currentNotes = await dbService.getNotesForInstance(_activeInstance!.id!);
    }
    notifyListeners();
  }

  /// Create a new project
  Future<void> createProject(String name) async {
    final project = Project(name: name);
    await dbService.insertProject(project);
    await loadProjects();
  }

  /// Start tracking a project - ends previous instance automatically
  Future<void> startProject(Project project) async {
    // End current instance if exists
    if (_activeInstance != null) {
      await endCurrentInstance();
    }

    // Create new instance
    final instance = Instance(projectId: project.id!);
    final instanceId = await dbService.insertInstance(instance);

    _activeInstance = instance.copyWith(id: instanceId);
    _activeProject = project;
    _currentNotes = [];

    // Update project last active time
    final updatedProject = project.copyWith(lastActiveAt: DateTime.now());
    await dbService.updateProject(updatedProject);

    // Log to file
    await fileService.logInstanceStart(project, _activeInstance!);

    await loadProjects();
    notifyListeners();
  }

  /// End current instance and accumulate time
  /// Accepts optional [customEndTime] to allow time corrections
  Future<void> endCurrentInstance({DateTime? customEndTime}) async {
    if (_activeInstance == null || _activeProject == null) return;

    final endTime = (customEndTime ?? DateTime.now());
    // Compute duration using UTC on both sides to avoid timezone skew
    final duration = endTime
      .toUtc()
      .difference(_activeInstance!.startTime.toUtc())
      .inMinutes;

    // Update instance
    final completedInstance = _activeInstance!.copyWith(
      endTime: endTime,
      durationMinutes: duration,
    );
    await dbService.updateInstance(completedInstance);

    // Update project total time
    final updatedProject = _activeProject!.copyWith(
      totalMinutes: _activeProject!.totalMinutes + duration,
      lastActiveAt: endTime,
    );
    await dbService.updateProject(updatedProject);

    // Log to file with all notes
    await fileService.logInstanceEnd(
      _activeProject!,
      completedInstance,
      _currentNotes,
    );

    _activeInstance = null;
    _activeProject = null;
    _currentNotes = [];

    await loadProjects();
    notifyListeners();
  }

  /// Add note to current instance (only if not empty)
  Future<void> addNote(String content) async {
    if (_activeInstance == null || content.trim().isEmpty) return;

    final note = Note(
      instanceId: _activeInstance!.id!,
      content: content.trim(),
    );

    final noteId = await dbService.insertNote(note);
    final savedNote = note.copyWith(id: noteId);
    _currentNotes.add(savedNote);

    // Log note to file
    await fileService.logNote(_activeProject!, _activeInstance!, savedNote);

    notifyListeners();
  }

  /// Get duration of current active instance in minutes
  int getCurrentDuration() {
    if (_activeInstance == null) return 0;
    return DateTime.now()
        .toUtc()
        .difference(_activeInstance!.startTime.toUtc())
        .inMinutes;
  }

  /// Set the time display mode
  void setTimeDisplayMode(TimeDisplayMode mode) {
    _timeDisplayMode = mode;
    notifyListeners();
  }

  /// Get display time for a project based on current display mode
  Future<int> getDisplayTimeForProject(Project project) async {
    // Ensure project has a valid ID
    if (project.id == null) return 0;

    switch (_timeDisplayMode) {
      case TimeDisplayMode.instance:
        // Show current instance duration if this is the active project
        if (_activeProject?.id == project.id && _activeInstance != null) {
          return getCurrentDuration();
        }
        return 0;

      case TimeDisplayMode.day:
        final today = DateTime.now();
        return await dbService.getProjectMinutesForDate(project.id!, today);

      case TimeDisplayMode.week:
        final bounds = _getWeekBounds();
        return await dbService.getProjectMinutesInRange(
          project.id!,
          bounds.start,
          bounds.end,
        );

      case TimeDisplayMode.month:
        final bounds = _getMonthBounds();
        return await dbService.getProjectMinutesInRange(
          project.id!,
          bounds.start,
          bounds.end,
        );

      case TimeDisplayMode.project:
        return project.totalMinutes;
    }
  }

  /// Get start and end dates for the current week (Monday-Sunday)
  _DateBounds _getWeekBounds() {
    final now = DateTime.now();
    // In Dart, DateTime.monday is 1. So, we subtract (weekday - 1) days.
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endDate = startDate.add(const Duration(days: 7));
    return _DateBounds(startDate, endDate);
  }

  /// Get start and end dates for the current month
  _DateBounds _getMonthBounds() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return _DateBounds(startOfMonth, endOfMonth);
  }
}

/// Helper class to hold date range bounds
class _DateBounds {
  final DateTime start;
  final DateTime end;

  _DateBounds(this.start, this.end);
}

extension NoteCopyWith on Note {
  Note copyWith({
    int? id,
    int? instanceId,
    String? content,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
