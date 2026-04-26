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
    final Directory appDir;

    // Use platform-specific storage locations for better accessibility
    if (Platform.isAndroid) {
      // Android: Use external storage directory for user-accessible files
      // This directory is accessible via file managers and "Files" app
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        // Fail loudly if the user-accessible external storage is not available.
        // Falling back to the internal directory would be confusing for users
        // who expect to find the logs in a specific, accessible location.
        throw const FileSystemException(
            "External storage directory not available on this device.");
      }
      appDir = externalDir;
    } else {
      // iOS, Windows, Linux, macOS: Use application documents directory
      // iOS: Accessible via Files app with proper Info.plist configuration
      // Desktop: Already accessible via system file explorer
      appDir = await getApplicationDocumentsDirectory();
    }

    _logDirectory = path.join(appDir.path, 'ProjectTrackingLogs');
    await Directory(_logDirectory!).create(recursive: true);
  }

  String get logDirectory => _logDirectory ?? '';

  /// Logs instance start event
  Future<void> logInstanceStart(Project project, Instance instance) async {
    final timestamp = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(instance.startTime);

    // Adjust the number of '=' characters to maintain 70 characters.
    final baseCharacterQuantity =
        timestamp.length + instance.id.toString().length + 28;
    var endingEquals = '=';
    if (baseCharacterQuantity < 70) {
      endingEquals = '=' * (70 - baseCharacterQuantity);
    }
    final content = '''
==START-^: $timestamp Instance ID: ${instance.id} -^$endingEquals
''';
    await _addToLog(project, content, insert: true);
  }

  /// Logs instance end event with duration
  Future<void> logInstanceEnd(
    Project project,
    Instance instance,
    List<Note> notes,
  ) async {
    if (instance.endTime == null) return;

    final endFormat = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(instance.endTime!);
    final duration = _formatDuration(instance.durationMinutes);

    // Adjust the number of '=' characters to maintain 70 characters.
    final baseCharacterQuantity =
        endFormat.length + instance.id.toString().length + duration.length + 30;
    var endingEquals = '=';
    if (baseCharacterQuantity < 70) {
      endingEquals = '=' * (70 - baseCharacterQuantity);
    }
    final content = '''
====END-v: $endFormat Instance ID: ${instance.id}, $duration -v$endingEquals
''';

    await _addToLog(project, content, insert: true);
  }

  /// Logs a note addition
  Future<void> logNote(Project project, Instance instance, Note note) async {
    final timestamp = DateFormat('h:mma M/d/yyyy EEEE').format(note.createdAt);
    final content = '''
[$timestamp, Note ID: ${note.id}]
${note.content}
''';
    await _addToLog(project, content, insert: true);
  }

  /// Adds formatted content to project-specific log file
  Future<void> _addToLog(Project project, String content,
      {bool insert = false}) async {
    // Sanitize project name for filename
    final sanitized =
        project.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final projectId = project.id ?? 'unknown';
    final filename = '${sanitized}_log-ID$projectId.txt';
    final file = File(path.join(_logDirectory!, filename));

    /// Insert or append content to the log file.
    /// If insert is true, the new content is added at the top of the file, otherwise it is appended to the end.
    if (insert && await file.exists()) {
      final existingContent = await file.readAsString();
      content = '$content\n$existingContent';
      await file.writeAsString(content);
      return;
    }

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
