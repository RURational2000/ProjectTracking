import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// No-op web implementation of FileLoggingService.
/// On web, local file system access is not available, so all methods are safe no-ops.
class FileLoggingService {
  Future<void> initialize() async {}

  String get logDirectory => '';

  Future<void> logInstanceStart(Project project, Instance instance) async {}

  Future<void> logInstanceEnd(
    Project project,
    Instance instance,
    List<Note> notes,
  ) async {}

  Future<void> logNote(Project project, Instance instance, Note note) async {}
}
