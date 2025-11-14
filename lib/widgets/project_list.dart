import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/models/project.dart';

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
                subtitle: Text(_formatTime(project.totalMinutes)),
                trailing: isActive
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () => _startProject(context, provider, project),
                      ),
                onTap: isActive ? null : () => _startProject(context, provider, project),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return 'Total: ${hours}h ${mins}m';
    }
    return 'Total: ${mins}m';
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
}
