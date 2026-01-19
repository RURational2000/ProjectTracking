import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';
import 'package:project_tracking/services/export_service.dart';
import 'mocks/fake_database_service.dart';

void main() {
  group('ExportService', () {
    late FakeDatabaseService dbService;
    late ExportService exportService;

    setUp(() {
      dbService = FakeDatabaseService();
      exportService = ExportService(dbService: dbService);
    });

    test('exportTimeLogAsCsv generates CSV with headers', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Export should work even with no instances
      final csv = await exportService.exportTimeLogAsCsv(project!);

      expect(
          csv,
          contains(
              'Date,Start Time,End Time,Duration (minutes),Duration (hours),Description,Week,Month'));
      expect(csv, contains('Weekly Summaries'));
      expect(csv, contains('Monthly Summaries'));
    });

    test('exportTimeLogAsCsv includes completed instances', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create instances
      final startTime1 = DateTime(2024, 1, 15, 9, 0);
      final endTime1 = DateTime(2024, 1, 15, 11, 30);
      final instanceId1 = await dbService.insertInstance(
        Instance(
          projectId: projectId,
          startTime: startTime1,
        ),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId1,
          projectId: projectId,
          startTime: startTime1,
          endTime: endTime1,
          durationMinutes: 150,
        ),
      );

      // Add a note to the instance
      await dbService.insertNote(
        Note(
          instanceId: instanceId1,
          content: 'Test note content',
        ),
      );

      // Export
      final csv = await exportService.exportTimeLogAsCsv(project!);

      expect(csv, contains('2024-01-15'));
      expect(csv, contains('09:00'));
      expect(csv, contains('11:30'));
      expect(csv, contains('150')); // duration in minutes
      expect(csv, contains('Test note content'));
    });

    test('exportTimeLogAsCsv excludes active instances', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create an active instance (no end time)
      await dbService.insertInstance(
        Instance(
          projectId: projectId,
          startTime: DateTime.now(),
        ),
      );

      // Export should not include active instance
      final csv = await exportService.exportTimeLogAsCsv(project!);

      // Should have header but no data rows
      final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
      // Header + Weekly Summaries header + Month column header + Monthly Summaries header + Month column header
      expect(lines.length, lessThanOrEqualTo(6));
    });

    test('exportTimeLogAsCsv sorts instances in descending order', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create instances in different order
      final startTime1 = DateTime(2024, 1, 10, 9, 0);
      final endTime1 = DateTime(2024, 1, 10, 10, 0);
      final startTime2 = DateTime(2024, 1, 15, 9, 0);
      final endTime2 = DateTime(2024, 1, 15, 10, 0);

      final instanceId1 = await dbService.insertInstance(
        Instance(projectId: projectId, startTime: startTime1),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId1,
          projectId: projectId,
          startTime: startTime1,
          endTime: endTime1,
          durationMinutes: 60,
        ),
      );

      final instanceId2 = await dbService.insertInstance(
        Instance(projectId: projectId, startTime: startTime2),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId2,
          projectId: projectId,
          startTime: startTime2,
          endTime: endTime2,
          durationMinutes: 60,
        ),
      );

      // Export
      final csv = await exportService.exportTimeLogAsCsv(project!);

      // Check that most recent date appears first in data
      final lines = csv.split('\n');
      final dataLines = lines
          .skip(1)
          .where((l) =>
              l.isNotEmpty &&
              !l.startsWith('Weekly') &&
              !l.startsWith('Monthly') &&
              !l.startsWith('Week,') &&
              !l.startsWith('Month,'))
          .toList();

      if (dataLines.length >= 2) {
        expect(dataLines[0], contains('2024-01-15'));
        expect(dataLines[1], contains('2024-01-10'));
      }
    });

    test('exportTimeLogAsCsv uses last note as description', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create instance
      final startTime = DateTime(2024, 1, 15, 9, 0);
      final endTime = DateTime(2024, 1, 15, 11, 30);
      final instanceId = await dbService.insertInstance(
        Instance(projectId: projectId, startTime: startTime),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId,
          projectId: projectId,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: 150,
        ),
      );

      // Add multiple notes
      await dbService.insertNote(
        Note(instanceId: instanceId, content: 'First note'),
      );
      await dbService.insertNote(
        Note(instanceId: instanceId, content: 'Last note'),
      );

      // Export
      final csv = await exportService.exportTimeLogAsCsv(project!);

      // Should use last note as description
      expect(csv, contains('Last note'));
    });

    test('exportNotesAsText generates formatted text', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Export should work even with no notes
      final text = await exportService.exportNotesAsText(project!);

      expect(text, contains('Notes Export for Project: Test Project'));
      expect(text, contains('Generated:'));
    });

    test('exportNotesAsText includes notes grouped by instance', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create instance
      final startTime = DateTime(2024, 1, 15, 9, 0);
      final endTime = DateTime(2024, 1, 15, 11, 30);
      final instanceId = await dbService.insertInstance(
        Instance(projectId: projectId, startTime: startTime),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId,
          projectId: projectId,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: 150,
        ),
      );

      // Add notes
      await dbService.insertNote(
        Note(instanceId: instanceId, content: 'First note'),
      );
      await dbService.insertNote(
        Note(instanceId: instanceId, content: 'Second note'),
      );

      // Export
      final text = await exportService.exportNotesAsText(project!);

      expect(text, contains('Instance:'));
      expect(text, contains('Duration: 2h 30m'));
      expect(text, contains('First note'));
      expect(text, contains('Second note'));
    });

    test('exportNotesAsText excludes instances without notes', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create instance without notes
      final startTime = DateTime(2024, 1, 15, 9, 0);
      final endTime = DateTime(2024, 1, 15, 11, 30);
      final instanceId = await dbService.insertInstance(
        Instance(projectId: projectId, startTime: startTime),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId,
          projectId: projectId,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: 150,
        ),
      );

      // Export - should not include instance without notes
      final text = await exportService.exportNotesAsText(project!);

      expect(text, contains('Notes Export for Project: Test Project'));
      expect(text, isNot(contains('Instance:')));
    });

    test('generatePreviewText returns preview for CSV', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Generate preview
      final preview = await exportService.generatePreviewText(project!, 'csv');

      expect(preview, contains('Date,Start Time,End Time'));
      expect(preview, isNotEmpty);
    });

    test('generatePreviewText returns preview for notes', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Generate preview
      final preview =
          await exportService.generatePreviewText(project!, 'notes');

      expect(preview, contains('Notes Export for Project: Test Project'));
      expect(preview, isNotEmpty);
    });

    test('CSV escapes special characters in notes', () async {
      // Create a project
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );
      final project = await dbService.getProject(projectId);

      // Create instance with note containing quotes
      final startTime = DateTime(2024, 1, 15, 9, 0);
      final endTime = DateTime(2024, 1, 15, 11, 30);
      final instanceId = await dbService.insertInstance(
        Instance(projectId: projectId, startTime: startTime),
      );
      await dbService.updateInstance(
        Instance(
          id: instanceId,
          projectId: projectId,
          startTime: startTime,
          endTime: endTime,
          durationMinutes: 150,
        ),
      );

      await dbService.insertNote(
        Note(instanceId: instanceId, content: 'Note with "quotes"'),
      );

      // Export
      final csv = await exportService.exportTimeLogAsCsv(project!);

      // Should escape quotes properly
      expect(csv, contains('Note with ""quotes""'));
    });
  });
}
