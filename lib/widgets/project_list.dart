import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/models/time_display_mode.dart';
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

            // For Instance mode with active project, use StreamBuilder for live updates
            if (provider.timeDisplayMode == TimeDisplayMode.instance && isActive) {
              return StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 30)),
                builder: (context, snapshot) {
                  return FutureBuilder<int>(
                    future: provider.getDisplayTimeForProject(project),
                    builder: (context, snapshot) {
                      final minutes = snapshot.data ?? 0;
                      return _buildProjectCard(context, provider, project, isActive, minutes);
                    },
                  );
                },
              );
            }

            return FutureBuilder<int>(
              future: provider.getDisplayTimeForProject(project),
              builder: (context, snapshot) {
                final minutes = snapshot.data ?? 0;
                return _buildProjectCard(context, provider, project, isActive, minutes);
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
            : IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () => _startProject(context, provider, project),
              ),
        onTap: isActive ? null : () => _startProject(context, provider, project),
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
}
