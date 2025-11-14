import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/providers/tracking_provider.dart';
import 'package:project_tracking/widgets/project_list.dart';
import 'package:project_tracking/widgets/active_tracking_panel.dart';
import 'package:project_tracking/widgets/new_project_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Tracking'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Active tracking panel (if instance is active)
          Consumer<TrackingProvider>(
            builder: (context, provider, child) {
              if (provider.hasActiveInstance) {
                return const ActiveTrackingPanel();
              }
              return const SizedBox.shrink();
            },
          ),
          // Project list
          const Expanded(
            child: ProjectList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );
  }
}
