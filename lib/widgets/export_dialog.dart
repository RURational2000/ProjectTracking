import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/services/export_service.dart';

/// Dialog for exporting project data with preview
class ExportDialog extends StatefulWidget {
  final Project project;
  final ExportService exportService;

  const ExportDialog({
    super.key,
    required this.project,
    required this.exportService,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _selectedFormat = 'time_log_csv';
  String _previewText = 'Loading preview...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String preview;
      if (_selectedFormat == 'time_log_csv') {
        preview = await widget.exportService.generatePreviewText(widget.project, 'csv');
      } else {
        preview = await widget.exportService.generatePreviewText(widget.project, 'notes');
      }

      setState(() {
        _previewText = preview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _previewText = 'Error loading preview: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Export: ${widget.project.name}'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select export format:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedFormat,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'time_log_csv',
                  child: Text('Time Log (CSV)'),
                ),
                DropdownMenuItem(
                  value: 'notes_text',
                  child: Text('Notes (Text)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFormat = value;
                  });
                  _loadPreview();
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          _previewText,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _exportAndSave(context),
          child: const Text('Export'),
        ),
      ],
    );
  }

  Future<void> _exportAndSave(BuildContext context) async {
    try {
      String content;
      String extension;
      String formatName;

      if (_selectedFormat == 'time_log_csv') {
        content = await widget.exportService.exportTimeLogAsCsv(widget.project);
        extension = 'csv';
        formatName = 'Time Log';
      } else {
        content = await widget.exportService.exportNotesAsText(widget.project);
        extension = 'txt';
        formatName = 'Notes';
      }

      // Save file
      final success = await _saveFile(content, extension);

      if (context.mounted) {
        Navigator.of(context).pop();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$formatName exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final message = kIsWeb
              ? 'Export not supported on web platform. Please use desktop or mobile app.'
              : 'Failed to export file';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _saveFile(String content, String extension) async {
    try {
      if (kIsWeb) {
        // Web platform: download functionality not implemented
        // Show specific message to user
        debugPrint('Export not supported on web platform');
        return false;
      }

      // Get appropriate directory based on platform
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return false;

      // Create exports subdirectory
      final exportsDir = Directory(path.join(directory.path, 'ProjectTrackingExports'));
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = '${widget.project.name}_$timestamp.$extension';
      final filePath = path.join(exportsDir.path, filename);

      // Write file
      final file = File(filePath);
      await file.writeAsString(content);

      debugPrint('File exported to: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return false;
    }
  }
}
