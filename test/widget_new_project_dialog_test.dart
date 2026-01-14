import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/widgets/new_project_dialog.dart';
import 'mocks/fake_database_service.dart';
import 'mocks/fake_file_logging_service.dart';

void main() {
  testWidgets('NewProjectDialog creates project and shows snackbar',
      (WidgetTester tester) async {
    final db = FakeDatabaseService();
    final file = FakeFileLoggingService();

    final provider = TrackingProvider(dbService: db, fileService: file);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Home')),
          ),
        ),
      ),
    );

    // Open the dialog
    showDialog(
      context: tester.element(find.text('Home')),
      builder: (_) => const NewProjectDialog(),
    );
    await tester.pumpAndSettle();

    // Enter project name and submit
    await tester.enterText(find.byType(TextFormField), 'My Test Project');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Expect snackbar confirmation
    expect(find.text('Created project: My Test Project'), findsOneWidget);

    // Provider should have the new project after load
    final projects = await db.getAllProjects();
    expect(projects.any((p) => p.name == 'My Test Project'), isTrue);
  });
}
