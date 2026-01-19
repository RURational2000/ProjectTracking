import 'dart:async';

import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/services/database_service.dart';

class FakeDatabaseService implements DatabaseService {
  int _projectAutoId = 1;
  int _instanceAutoId = 1;
  int _noteAutoId = 1;

  final Map<int, Project> _projects = {};
  final Map<int, Instance> _instances = {};
  final Map<int, List<Note>> _instanceNotes = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<int> insertProject(Project project) async {
    final id = _projectAutoId++;
    final now = DateTime.now();
    _projects[id] = project.copyWith(id: id, createdAt: now);
    return id;
  }

  @override
  Future<List<Project>> getAllProjects() async {
    final list = _projects.values.where((p) => !p.isArchived).toList();
    list.sort((a, b) {
      final la = a.lastActiveAt ?? a.createdAt;
      final lb = b.lastActiveAt ?? b.createdAt;
      final comp = lb.compareTo(la);
      if (comp != 0) return comp;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  @override
  Future<Project?> getProject(int id) async => _projects[id];

  @override
  Future<void> updateProject(Project project) async {
    if (project.id == null) throw ArgumentError('Project ID required');
    _projects[project.id!] = project;
  }

  @override
  Future<void> deleteProject(int id) async {
    _projects.remove(id);
    // Collect instance IDs for this project before removing instances
    final instanceIdsToRemove = _instances.entries
        .where((entry) => entry.value.projectId == id)
        .map((entry) => entry.key)
        .toList();
    
    // Remove instances for this project
    for (final instanceId in instanceIdsToRemove) {
      _instances.remove(instanceId);
      _instanceNotes.remove(instanceId);
    }
  }

  @override
  Future<void> renameProject(int id, String newName) async {
    if (newName.trim().isEmpty) {
      throw ArgumentError('Project name cannot be empty');
    }
    final project = _projects[id];
    if (project == null) throw ArgumentError('Project not found');
    _projects[id] = project.copyWith(name: newName.trim());
  }

  @override
  Future<int> insertInstance(Instance instance) async {
    final id = _instanceAutoId++;
    _instances[id] = instance.copyWith(id: id);
    return id;
  }

  @override
  Future<Instance?> getActiveInstance() async {
    // Return most recent active instance if any
    final actives = _instances.values.where((i) => i.endTime == null).toList();
    actives.sort((a, b) => b.startTime.compareTo(a.startTime));
    return actives.isEmpty ? null : actives.first;
  }

  @override
  Future<List<Instance>> getInstancesForProject(int projectId) async {
    final list = _instances.values
        .where((i) => i.projectId == projectId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  @override
  Future<void> updateInstance(Instance instance) async {
    if (instance.id == null) throw ArgumentError('Instance ID required');
    _instances[instance.id!] = instance;
  }

  @override
  Future<int> insertNote(Note note) async {
    final id = _noteAutoId++;
    final saved = Note(
      id: id,
      instanceId: note.instanceId,
      content: note.content,
      createdAt: note.createdAt,
    );
    _instanceNotes.putIfAbsent(note.instanceId, () => []).add(saved);
    return id;
  }

  @override
  Future<List<Note>> getNotesForInstance(int instanceId) async {
    return List.unmodifiable(_instanceNotes[instanceId] ?? []);
  }

  @override
  Future<int> getProjectMinutesInRange(
    int projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    int total = 0;
    for (final i in _instances.values) {
      if (i.projectId != projectId) continue;
      if (i.endTime == null) continue;
      if (i.startTime.isBefore(endDate) && !i.startTime.isBefore(startDate)) {
        total += i.durationMinutes;
      }
    }
    return total;
  }

  @override
  Future<int> getProjectMinutesForDate(int projectId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getProjectMinutesInRange(projectId, startOfDay, endOfDay);
  }
}
