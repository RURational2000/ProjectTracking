import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';

/// File logging service for timestamp and note verification.
/// Creates human-readable log files parallel to the database for audit trail.
class FileLoggingService {
  String? _logDirectory;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _logDirectory = path.join(appDir.path, 'ProjectTrackingLogs');
    await Directory(_logDirectory!).create(recursive: true);
  }

  String get logDirectory => _logDirectory ?? '';

  /// Logs instance start event
  Future<void> logInstanceStart(Project project, Instance instance) async {
    final timestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(instance.startTime);
    final content = '''
================================================================================
PROJECT: ${project.name} (ID: ${project.id})
INSTANCE START
Started: $timestamp
Instance ID: ${instance.id}
================================================================================

''';
    await _appendToLog(project.name, content);
  }

  /// Logs instance end event with duration
  Future<void> logInstanceEnd(
    Project project,
    Instance instance,
    List<Note> notes,
  ) async {
    if (instance.endTime == null) return;

    final startFormat = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(instance.startTime);
    final endFormat = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(instance.endTime!);
    final duration = _formatDuration(instance.durationMinutes);

    final buffer = StringBuffer();
    buffer.writeln('INSTANCE END');
    buffer.writeln('Started:  $startFormat');
    buffer.writeln('Ended:    $endFormat');
    buffer.writeln('Duration: $duration');
    buffer.writeln('Instance ID: ${instance.id}');

    if (notes.isNotEmpty) {
      buffer.writeln('\nNOTES (${notes.length}):');
      for (int i = 0; i < notes.length; i++) {
        final noteTime = DateFormat('HH:mm:ss').format(notes[i].createdAt);
        buffer.writeln('  [$noteTime] ${notes[i].content}');
      }
    }

    buffer.writeln(
      '================================================================================\n',
    );

    await _appendToLog(project.name, buffer.toString());
  }

  /// Logs a note addition
  Future<void> logNote(Project project, Instance instance, Note note) async {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(note.createdAt);
    final content = '''
NOTE ADDED
Time: $timestamp
Instance ID: ${instance.id}
Content: ${note.content}
--------------------------------------------------------------------------------

''';
    await _appendToLog(project.name, content);
  }

  /// Appends content to project-specific log file
  Future<void> _appendToLog(String projectName, String content) async {
    // Sanitize project name for filename
    final sanitized =
        projectName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final filename = '${sanitized}_log.txt';
    final file = File(path.join(_logDirectory!, filename));

    await file.writeAsString(content, mode: FileMode.append);
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  /// Get all log files for viewing
  Future<List<FileSystemEntity>> getLogFiles() async {
    final dir = Directory(_logDirectory!);
    return dir.list().toList();
  }
}
