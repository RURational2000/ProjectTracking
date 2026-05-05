import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/models/time_display_mode.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/models/project.dart';
import 'package:project_tracking/widgets/rename_project_dialog.dart';

class ProjectList extends StatelessWidget {
  const ProjectList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, provider, child) {
        if (provider.projects.isEmpty) {
          return const Center(
            child: Text('No projects yet. Create one to get started!'),
          );
        }

        return ListView.builder(
          itemCount: provider.projects.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final project = provider.projects[index];
            final isActive = provider.activeProject?.id == project.id;

            // For Instance mode with active project, use StreamBuilder for live updates
            if (provider.timeDisplayMode == TimeDisplayMode.instance &&
                isActive) {
              return StreamBuilder<void>(
                initialData: null, // Ensures the builder runs immediately
                stream: Stream<void>.periodic(const Duration(seconds: 30)),
                builder: (context, snapshot) {
                  // Directly get current duration without database query
                  final minutes = provider.getCurrentDuration();
                  return _buildProjectCard(
                    context,
                    provider,
                    project,
                    isActive,
                    minutes,
                  );
                },
              );
            }

            return FutureBuilder<int>(
              future: provider.getDisplayTimeForProject(project),
              builder: (context, snapshot) {
                final minutes = snapshot.data ?? 0;
                return _buildProjectCard(
                  context,
                  provider,
                  project,
                  isActive,
                  minutes,
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(int minutes, TimeDisplayMode mode) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    return '${mode.label}: $timeStr';
  }

  Widget _buildProjectCard(
    BuildContext context,
    TrackingProvider provider,
    Project project,
    bool isActive,
    int minutes,
  ) {
    return Card(
      color: isActive ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey,
          child: Icon(
            isActive ? Icons.play_arrow : Icons.folder,
            color: Colors.white,
          ),
        ),
        title: Text(
          project.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(_formatTime(minutes, provider.timeDisplayMode)),
        trailing: isActive
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () => _startProject(context, provider, project),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(
                      context,
                      provider,
                      project,
                      value,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive),
                            SizedBox(width: 8),
                            Text('Archive'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Permanently',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
        onTap:
            isActive ? null : () => _startProject(context, provider, project),
      ),
    );
  }

  Future<void> _startProject(
    BuildContext context,
    TrackingProvider provider,
    Project project,
  ) async {
    await provider.startProject(project);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started tracking: ${project.name}')),
      );
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    TrackingProvider provider,
    Project project,
    String action,
  ) async {
    switch (action) {
      case 'rename':
        await _showRenameDialog(context, provider, project);
        break;
      case 'archive':
        await _confirmAndArchive(context, provider, project);
        break;
      case 'delete':
        await _confirmAndDelete(context, provider, project);
        break;
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    TrackingProvider provider,
    Project project,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => RenameProjectDialog(
        project: project,
        provider: provider,
      ),
    );
  }

  Future<void> _confirmAndArchive(
    BuildContext context,
    TrackingProvider provider,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Project'),
        content: Text(
          'Archive "${project.name}"?\n\n'
          'The project will be hidden from the list but can be restored later. '
          'All data and logs will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.archiveProject(project);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archived: ${project.name}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error archiving project: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    TrackingProvider provider,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project Permanently'),
        content: Text(
          'Permanently delete "${project.name}"?\n\n'
          'This will remove all project data from the database including all instances and notes. '
          'This action cannot be undone.\n\n'
          'Note: Text log files will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.deleteProject(project);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted: ${project.name}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting project: $e')),
          );
        }
      }
    }
  }
}
