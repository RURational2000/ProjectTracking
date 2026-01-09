import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/widgets/active_tracking_panel.dart';

import 'mocks/fake_database_service.dart';
import 'mocks/fake_file_logging_service.dart';

void main() {
  testWidgets(
      'Starting a new project ends previous instance and logs start/end',
      (WidgetTester tester) async {
    final db = FakeDatabaseService();
    final file = FakeFileLoggingService();
    final provider = TrackingProvider(dbService: db, fileService: file);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: ActiveTrackingPanel()),
        ),
      ),
    );

    // Create two projects
    await provider.createProject('A');
    await provider.createProject('B');
    final projects = await db.getAllProjects();
    final projectA = projects.firstWhere((p) => p.name == 'A');
    final projectB = projects.firstWhere((p) => p.name == 'B');

    // Start A
    await provider.startProject(projectA);
    await tester.pumpAndSettle();
    expect(file.instanceStartCalls.length, 1);
    expect(file.instanceEndCalls.length, 0);

    // Start B (should end A automatically)
    await provider.startProject(projectB);
    await tester.pumpAndSettle();
    expect(file.instanceStartCalls.length, 2);
    expect(file.instanceEndCalls.length, 1);

    // Verify A has a completed instance
    final instancesA = await db.getInstancesForProject(projectA.id!);
    expect(instancesA.length, 1);
    expect(instancesA.first.endTime != null, isTrue);
  });

  testWidgets('Adding a note updates UI and logs', (WidgetTester tester) async {
    final db = FakeDatabaseService();
    final file = FakeFileLoggingService();
    final provider = TrackingProvider(dbService: db, fileService: file);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: ActiveTrackingPanel()),
        ),
      ),
    );

    // Create and start a project
    final id = await db.insertProject(Project(name: 'P'));
    final project = (await db.getProject(id))!;
    await provider.loadProjects();
    await provider.startProject(project);
    await tester.pumpAndSettle();

    // Add a note through the UI
    await tester.enterText(find.byType(TextField), 'Test note');
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();

    // UI shows the note count incremented
    expect(find.textContaining('Notes (1)'), findsOneWidget);

    // Logging captured
    expect(file.noteCalls.length, 1);
    expect(file.noteCalls.first.note.content, 'Test note');
  });
}
