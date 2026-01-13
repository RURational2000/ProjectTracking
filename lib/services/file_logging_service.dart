// Facade that conditionally uses the correct implementation based on platform.
// Consumers import this file and get a stable `FileLoggingService` API.

import 'file_logging_service_io.dart'
    if (dart.library.html) 'file_logging_service_web.dart' as impl;
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

class FileLoggingService {
  final impl.FileLoggingService _inner = impl.FileLoggingService();

  Future<void> initialize() => _inner.initialize();

  String get logDirectory => _inner.logDirectory;

  Future<void> logInstanceStart(Project project, Instance instance) =>
      _inner.logInstanceStart(project, instance);

  Future<void> logInstanceEnd(
    Project project,
    Instance instance,
    List<Note> notes,
  ) =>
      _inner.logInstanceEnd(project, instance, notes);

  Future<void> logNote(Project project, Instance instance, Note note) =>
      _inner.logNote(project, instance, note);
}
