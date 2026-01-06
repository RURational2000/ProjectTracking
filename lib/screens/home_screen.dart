import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_tracking/models/time_display_mode.dart';
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
        actions: [
          Consumer<TrackingProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<TimeDisplayMode>(
                icon: const Icon(Icons.access_time),
                tooltip: 'Time Display Mode',
                onSelected: (mode) => provider.setTimeDisplayMode(mode),
                itemBuilder: (context) => TimeDisplayMode.values.map((mode) {
                  return PopupMenuItem<TimeDisplayMode>(
                    value: mode,
                    child: Row(
                      children: [
                        if (provider.timeDisplayMode == mode)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(mode.label),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign out failed: $e')),
                );
              }
            },
          ),
        ],
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
