import 'package:flutter_test/flutter_test.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'mocks/fake_database_service.dart';
import 'mocks/fake_file_logging_service.dart';

void main() {
  group('Project Management Operations', () {
    late FakeDatabaseService dbService;
    late FakeFileLoggingService fileService;
    late TrackingProvider provider;

    setUp(() {
      dbService = FakeDatabaseService();
      fileService = FakeFileLoggingService();
      provider = TrackingProvider(
        dbService: dbService,
        fileService: fileService,
      );
    });

    test('archiveProject marks project as archived', () async {
      // Create a project
      await provider.createProject('Test Project');
      await Future.delayed(const Duration(milliseconds: 100));

      final projects = provider.projects;
      expect(projects.length, 1);
      expect(projects[0].isArchived, false);

      // Archive the project
      await provider.archiveProject(projects[0]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Project should no longer appear in the list
      expect(provider.projects.length, 0);

      // Verify the project is actually archived in the database
      final archivedProject = await dbService.getProject(projects[0].id!);
      expect(archivedProject?.isArchived, true);
    });

    test('archiveProject ends active instance before archiving', () async {
      // Create and start a project
      await provider.createProject('Active Project');
      await Future.delayed(const Duration(milliseconds: 100));

      final project = provider.projects[0];
      await provider.startProject(project);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.hasActiveInstance, true);
      expect(provider.activeProject?.id, project.id);

      // Archive the active project
      await provider.archiveProject(project);
      await Future.delayed(const Duration(milliseconds: 100));

      // Active instance should be ended
      expect(provider.hasActiveInstance, false);
      expect(provider.activeProject, null);
    });

    test('deleteProject removes project permanently', () async {
      // Create a project
      await provider.createProject('Project to Delete');
      await Future.delayed(const Duration(milliseconds: 100));

      final projects = provider.projects;
      expect(projects.length, 1);
      final projectId = projects[0].id!;

      // Delete the project
      await provider.deleteProject(projects[0]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Project should not appear in the list
      expect(provider.projects.length, 0);

      // Project should not exist in the database
      final deletedProject = await dbService.getProject(projectId);
      expect(deletedProject, null);
    });

    test('deleteProject ends active instance before deleting', () async {
      // Create and start a project
      await provider.createProject('Active Project to Delete');
      await Future.delayed(const Duration(milliseconds: 100));

      final project = provider.projects[0];
      await provider.startProject(project);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.hasActiveInstance, true);

      // Delete the active project
      await provider.deleteProject(project);
      await Future.delayed(const Duration(milliseconds: 100));

      // Active instance should be ended
      expect(provider.hasActiveInstance, false);
      expect(provider.activeProject, null);
    });

    test('renameProject updates project name', () async {
      // Create a project
      await provider.createProject('Old Name');
      await Future.delayed(const Duration(milliseconds: 100));

      final projects = provider.projects;
      expect(projects.length, 1);
      expect(projects[0].name, 'Old Name');

      // Rename the project
      await provider.renameProject(projects[0], 'New Name');
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify the name was updated
      final updatedProjects = provider.projects;
      expect(updatedProjects.length, 1);
      expect(updatedProjects[0].name, 'New Name');
    });

    test('renameProject updates active project reference', () async {
      // Create and start a project
      await provider.createProject('Active Project');
      await Future.delayed(const Duration(milliseconds: 100));

      final project = provider.projects[0];
      await provider.startProject(project);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.activeProject?.name, 'Active Project');

      // Rename the active project
      await provider.renameProject(project, 'Renamed Active Project');
      await Future.delayed(const Duration(milliseconds: 100));

      // Active project reference should be updated
      expect(provider.activeProject?.name, 'Renamed Active Project');
    });

    test('renameProject does nothing with empty name', () async {
      // Create a project
      await provider.createProject('Test Project');
      await Future.delayed(const Duration(milliseconds: 100));

      final project = provider.projects[0];
      final originalName = project.name;

      // Try to rename with empty name
      await provider.renameProject(project, '   ');
      await Future.delayed(const Duration(milliseconds: 100));

      // Name should remain unchanged
      expect(provider.projects[0].name, originalName);
    });

    test('FakeDatabaseService deleteProject removes instances', () async {
      // Create a project and start an instance
      final projectId = await dbService.insertProject(
        Project(name: 'Project with Instances'),
      );
      
      await dbService.insertInstance(
        Instance(projectId: projectId),
      );

      // Verify instance exists
      final instances = await dbService.getInstancesForProject(projectId);
      expect(instances.length, greaterThan(0));

      // Delete the project
      await dbService.deleteProject(projectId);

      // Project should be deleted
      final deletedProject = await dbService.getProject(projectId);
      expect(deletedProject, null);

      // Instances should be cleaned up
      final remainingInstances = await dbService.getInstancesForProject(projectId);
      expect(remainingInstances.length, 0);
    });

    test('FakeDatabaseService renameProject throws on empty name', () async {
      final projectId = await dbService.insertProject(
        Project(name: 'Test Project'),
      );

      expect(
        () => dbService.renameProject(projectId, ''),
        throwsArgumentError,
      );
    });

    test('archived projects do not appear in getAllProjects', () async {
      // Create two projects
      final project1Id = await dbService.insertProject(
        Project(name: 'Active Project'),
      );
      final project2Id = await dbService.insertProject(
        Project(name: 'To Be Archived'),
      );

      // Verify both appear
      var allProjects = await dbService.getAllProjects();
      expect(allProjects.length, 2);

      // Archive one project
      final project2 = await dbService.getProject(project2Id);
      await dbService.updateProject(project2!.copyWith(isArchived: true));

      // Only active project should appear
      allProjects = await dbService.getAllProjects();
      expect(allProjects.length, 1);
      expect(allProjects[0].name, 'Active Project');
    });
  });
}
