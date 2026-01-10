import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/services/file_logging_service.dart';

class FakeFileLoggingService extends FileLoggingService {
  final List<StartCall> instanceStartCalls = [];
  final List<EndCall> instanceEndCalls = [];
  final List<NoteCall> noteCalls = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> logInstanceStart(Project project, Instance instance) async {
    instanceStartCalls.add(StartCall(project, instance));
  }

  @override
  Future<void> logInstanceEnd(
    Project project,
    Instance instance,
    List<Note> notes,
  ) async {
    instanceEndCalls.add(EndCall(project, instance, List.of(notes)));
  }

  @override
  Future<void> logNote(Project project, Instance instance, Note note) async {
    noteCalls.add(NoteCall(project, instance, note));
  }
}

class StartCall {
  final Project project;
  final Instance instance;
  StartCall(this.project, this.instance);
}

class EndCall {
  final Project project;
  final Instance instance;
  final List<Note> notes;
  EndCall(this.project, this.instance, this.notes);
}

class NoteCall {
  final Project project;
  final Instance instance;
  final Note note;
  NoteCall(this.project, this.instance, this.note);
}
