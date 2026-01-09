import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/services/file_logging_service.dart';

class FakeFileLoggingService extends FileLoggingService {
  final List<_StartCall> instanceStartCalls = [];
  final List<_EndCall> instanceEndCalls = [];
  final List<_NoteCall> noteCalls = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> logInstanceStart(Project project, Instance instance) async {
    instanceStartCalls.add(_StartCall(project, instance));
  }

  @override
  Future<void> logInstanceEnd(
    Project project,
    Instance instance,
    List<Note> notes,
  ) async {
    instanceEndCalls.add(_EndCall(project, instance, List.of(notes)));
  }

  @override
  Future<void> logNote(Project project, Instance instance, Note note) async {
    noteCalls.add(_NoteCall(project, instance, note));
  }
}

class _StartCall {
  final Project project;
  final Instance instance;
  _StartCall(this.project, this.instance);
}

class _EndCall {
  final Project project;
  final Instance instance;
  final List<Note> notes;
  _EndCall(this.project, this.instance, this.notes);
}

class _NoteCall {
  final Project project;
  final Instance instance;
  final Note note;
  _NoteCall(this.project, this.instance, this.note);
}
