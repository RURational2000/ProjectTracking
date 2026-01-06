import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// Supabase database service for cloud-based persistence.
/// Manages Projects, Instances (work sessions), and Notes with multi-user support.
/// Requires authentication via Supabase Auth.
class SupabaseDatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Initialize service - Supabase client must be initialized in main.dart
  Future<void> initialize() async {
    // Verify we have an authenticated user
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to use Supabase database');
    }
    debugPrint('Supabase database service initialized for user: ${user.id}');
  }

  /// Get current authenticated user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // Project operations
  Future<int> insertProject(Project project) async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('projects')
          .insert({
            'user_id': userId,
            'name': project.name,
            'total_minutes': project.totalMinutes,
            'created_at': project.createdAt.toIso8601String(),
            'last_active_at': project.lastActiveAt?.toIso8601String(),
            'status': project.status,
            'is_archived': project.isArchived,
            'description': project.description,
            'parent_project_id': project.parentProjectId,
          })
          .select('id')
          .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('Error inserting project: $e');
      rethrow;
    }
  }

  Future<List<Project>> getAllProjects() async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('projects')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('last_active_at', ascending: false)
          .order('name', ascending: true);

      return (response as List)
          .map((data) => _projectFromSupabase(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      rethrow;
    }
  }

  Future<Project?> getProject(int id) async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('projects')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return _projectFromSupabase(response);
    } catch (e) {
      debugPrint('Error fetching project: $e');
      rethrow;
    }
  }

  Future<void> updateProject(Project project) async {
    final userId = _currentUserIdOrThrow();

    if (project.id == null) {
      throw ArgumentError('Project must have an ID to be updated.');
    }

    try {
      await _client
          .from('projects')
          .update({
            'name': project.name,
            'total_minutes': project.totalMinutes,
            'last_active_at': project.lastActiveAt?.toIso8601String(),
            'status': project.status,
            'is_archived': project.isArchived,
            'completed_at': project.completedAt?.toIso8601String(),
            'description': project.description,
            'parent_project_id': project.parentProjectId,
          })
          .eq('id', project.id!)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating project: $e');
      rethrow;
    }
  }

  // Instance operations
  Future<int> insertInstance(Instance instance) async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('instances')
          .insert({
            'project_id': instance.projectId,
            'user_id': userId,
            'start_time': instance.startTime.toIso8601String(),
            'end_time': instance.endTime?.toIso8601String(),
            'duration_minutes': instance.durationMinutes,
          })
          .select('id')
          .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('Error inserting instance: $e');
      rethrow;
    }
  }

  Future<Instance?> getActiveInstance() async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('instances')
          .select()
          .eq('user_id', userId)
          .isFilter('end_time', null)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return _instanceFromSupabase(response);
    } catch (e) {
      debugPrint('Error fetching active instance: $e');
      rethrow;
    }
  }

  Future<List<Instance>> getInstancesForProject(int projectId) async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('instances')
          .select()
          .eq('project_id', projectId)
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      return (response as List)
          .map((data) => _instanceFromSupabase(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching instances: $e');
      rethrow;
    }
  }

  Future<void> updateInstance(Instance instance) async {
    final userId = _currentUserIdOrThrow();

    try {
      await _client
          .from('instances')
          .update({
            'end_time': instance.endTime?.toIso8601String(),
            'duration_minutes': instance.durationMinutes,
          })
          .eq('id', instance.id!)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating instance: $e');
      rethrow;
    }
  }

  // Note operations - only saved when not empty
  Future<int> insertNote(Note note) async {
    if (note.content.trim().isEmpty) {
      throw ArgumentError('Note content cannot be empty');
    }

    try {
      final response = await _client
          .from('notes')
          .insert({
            'instance_id': note.instanceId,
            'content': note.content,
            'created_at': note.createdAt.toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as int;
    } catch (e) {
      debugPrint('Error inserting note: $e');
      rethrow;
    }
  }

  Future<List<Note>> getNotesForInstance(int instanceId) async {
    final userId = _currentUserIdOrThrow();
    try {
      final response = await _client
          .from('notes')
          .select('*, instances!inner(user_id)')
          .eq('instance_id', instanceId)
          .eq('instances.user_id', userId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((data) => _noteFromSupabase(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      rethrow;
    }
  }

  /// Get total minutes for a project in a date range
  Future<int> getProjectMinutesInRange(
    int projectId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _currentUserIdOrThrow();

    try {
      final response = await _client
          .from('instances')
          .select('duration_minutes')
          .eq('project_id', projectId)
          .eq('user_id', userId)
          .not('end_time', 'is', null)
          .gte('start_time', startDate.toIso8601String())
          .lt('start_time', endDate.toIso8601String());

      if (response.isEmpty) return 0;

      int total = 0;
      for (final instance in response) {
        total += (instance['duration_minutes'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      debugPrint('Error calculating project minutes: $e');
      rethrow;
    }
  }

  /// Get total minutes for a project on a specific date
  Future<int> getProjectMinutesForDate(int projectId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getProjectMinutesInRange(projectId, startOfDay, endOfDay);
  }

  // Helper methods

  /// Verify user is authenticated and return their ID
  String _currentUserIdOrThrow() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User must be authenticated to perform this action');
    }
    return userId;
  }

  /// Convert Supabase project response to Project model
  Project _projectFromSupabase(Map<String, dynamic> data) {
    return Project(
      id: data['id'] as int?,
      name: data['name'] as String,
      totalMinutes: data['total_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(data['created_at'] as String),
      lastActiveAt: data['last_active_at'] != null
          ? DateTime.parse(data['last_active_at'] as String)
          : null,
      status: data['status'] as String? ?? 'active',
      isArchived: data['is_archived'] as bool? ?? false,
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'] as String)
          : null,
      description: data['description'] as String?,
      parentProjectId: data['parent_project_id'] as int?,
    );
  }

  /// Convert Supabase instance response to Instance model
  Instance _instanceFromSupabase(Map<String, dynamic> data) {
    return Instance(
      id: data['id'] as int?,
      projectId: data['project_id'] as int,
      startTime: DateTime.parse(data['start_time'] as String),
      endTime: data['end_time'] != null
          ? DateTime.parse(data['end_time'] as String)
          : null,
      durationMinutes: data['duration_minutes'] as int? ?? 0,
    );
  }

  /// Convert Supabase note response to Note model
  Note _noteFromSupabase(Map<String, dynamic> data) {
    return Note(
      id: data['id'] as int?,
      instanceId: data['instance_id'] as int,
      content: data['content'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}
