import 'package:intl/intl.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/models/instance.dart';
import 'package:project_tracking/models/note.dart';
import 'package:project_tracking/services/database_service.dart';

/// Service for exporting project data in various formats
class ExportService {
  final DatabaseService dbService;

  ExportService({required this.dbService});

  /// Export time log for a project as CSV
  /// Returns CSV string with instances in descending order, summarized by week and month
  Future<String> exportTimeLogAsCsv(Project project) async {
    if (project.id == null) {
      throw ArgumentError('Project must have an ID to export');
    }

    // Fetch all instances for the project
    final instances = await dbService.getInstancesForProject(project.id!);
    
    // Filter out instances without end time (active instances)
    final completedInstances = instances.where((i) => i.endTime != null).toList();
    
    // Sort by start time descending (most recent first)
    completedInstances.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Fetch notes for all instances
    final Map<int, List<Note>> instanceNotes = {};
    for (final instance in completedInstances) {
      if (instance.id != null) {
        instanceNotes[instance.id!] = await dbService.getNotesForInstance(instance.id!);
      }
    }

    // Build CSV
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Start Time,End Time,Duration (minutes),Duration (hours),Description,Week,Month');
    
    // Track summaries
    final Map<String, int> weeklySummaries = {};
    final Map<String, int> monthlySummaries = {};
    
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');
    final weekFormat = DateFormat('yyyy-ww'); // ISO week number
    final monthFormat = DateFormat('yyyy-MM');
    
    for (final instance in completedInstances) {
      final date = dateFormat.format(instance.startTime);
      final startTime = timeFormat.format(instance.startTime);
      final endTime = timeFormat.format(instance.endTime!);
      final durationMinutes = instance.durationMinutes;
      final durationHours = (durationMinutes / 60.0).toStringAsFixed(2);
      
      // Get last note as description (notes are ordered by created_at ascending)
      final notes = instanceNotes[instance.id] ?? [];
      final description = notes.isNotEmpty ? _escapeCsv(notes.last.content) : '';
      
      // Calculate week and month
      final week = weekFormat.format(instance.startTime);
      final month = monthFormat.format(instance.startTime);
      
      // Add to summaries
      weeklySummaries[week] = (weeklySummaries[week] ?? 0) + durationMinutes;
      monthlySummaries[month] = (monthlySummaries[month] ?? 0) + durationMinutes;
      
      buffer.writeln('$date,$startTime,$endTime,$durationMinutes,$durationHours,"$description",$week,$month');
    }
    
    // Add summary sections
    buffer.writeln();
    buffer.writeln('Weekly Summaries');
    buffer.writeln('Week,Total Minutes,Total Hours');
    for (final entry in weeklySummaries.entries.toList()..sort((a, b) => b.key.compareTo(a.key))) {
      final hours = (entry.value / 60.0).toStringAsFixed(2);
      buffer.writeln('${entry.key},${entry.value},$hours');
    }
    
    buffer.writeln();
    buffer.writeln('Monthly Summaries');
    buffer.writeln('Month,Total Minutes,Total Hours');
    for (final entry in monthlySummaries.entries.toList()..sort((a, b) => b.key.compareTo(a.key))) {
      final hours = (entry.value / 60.0).toStringAsFixed(2);
      buffer.writeln('${entry.key},${entry.value},$hours');
    }
    
    return buffer.toString();
  }

  /// Export all notes for a project as text
  /// Returns formatted text with notes grouped by instance
  Future<String> exportNotesAsText(Project project) async {
    if (project.id == null) {
      throw ArgumentError('Project must have an ID to export');
    }

    // Fetch all instances for the project
    final instances = await dbService.getInstancesForProject(project.id!);
    
    // Filter completed instances and sort descending
    final completedInstances = instances.where((i) => i.endTime != null).toList();
    completedInstances.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Build text output
    final buffer = StringBuffer();
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    buffer.writeln('Notes Export for Project: ${project.name}');
    buffer.writeln('Generated: ${dateTimeFormat.format(DateTime.now())}');
    buffer.writeln('=' * 80);
    buffer.writeln();

    int instancesWithNotes = 0;
    for (final instance in completedInstances) {
      if (instance.id == null) continue;
      
      final notes = await dbService.getNotesForInstance(instance.id!);
      
      if (notes.isEmpty) continue; // Skip instances with no notes
      
      instancesWithNotes++;
      buffer.writeln('Instance: ${dateTimeFormat.format(instance.startTime)} - ${dateTimeFormat.format(instance.endTime!)}');
      buffer.writeln('Duration: ${_formatDuration(instance.durationMinutes)}');
      buffer.writeln('-' * 80);
      
      for (final note in notes) {
        final noteTime = DateFormat('HH:mm:ss').format(note.createdAt);
        buffer.writeln('[$noteTime] ${note.content}');
      }
      
      buffer.writeln();
    }

    if (instancesWithNotes == 0) {
      buffer.writeln('No notes found for this project.');
    }

    return buffer.toString();
  }

  /// Format duration in minutes as "Xh Ym"
  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  /// Escape CSV special characters
  String _escapeCsv(String value) {
    // Replace quotes with double quotes and handle newlines
    return value.replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', '');
  }

  /// Generate preview text for export dialog
  Future<String> generatePreviewText(Project project, String format) async {
    if (format == 'csv') {
      final csv = await exportTimeLogAsCsv(project);
      // Return first 20 lines for preview
      final lines = csv.split('\n');
      final previewLines = lines.take(20).toList();
      if (lines.length > 20) {
        previewLines.add('... (${lines.length - 20} more lines)');
      }
      return previewLines.join('\n');
    } else {
      final text = await exportNotesAsText(project);
      // Return first 30 lines for preview
      final lines = text.split('\n');
      final previewLines = lines.take(30).toList();
      if (lines.length > 30) {
        previewLines.add('... (${lines.length - 30} more lines)');
      }
      return previewLines.join('\n');
    }
  }
}
