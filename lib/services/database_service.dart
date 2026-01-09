export 'supabase_database_service.dart';

import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// Database service abstraction to enable mocking in tests.
abstract class DatabaseService {
	Future<void> initialize();

	// Projects
	Future<int> insertProject(Project project);
	Future<List<Project>> getAllProjects();
	Future<Project?> getProject(int id);
	Future<void> updateProject(Project project);

	// Instances
	Future<int> insertInstance(Instance instance);
	Future<Instance?> getActiveInstance();
	Future<List<Instance>> getInstancesForProject(int projectId);
	Future<void> updateInstance(Instance instance);

	// Notes
	Future<int> insertNote(Note note);
	Future<List<Note>> getNotesForInstance(int instanceId);

	// Aggregations
	Future<int> getProjectMinutesInRange(
		int projectId,
		DateTime startDate,
		DateTime endDate,
	);

	Future<int> getProjectMinutesForDate(int projectId, DateTime date);
}

// Supabase implementation is exported above for production use
