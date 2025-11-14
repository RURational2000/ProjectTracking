import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/providers/tracking_provider.dart';

class ActiveTrackingPanel extends StatefulWidget {
  const ActiveTrackingPanel({super.key});

  @override
  State<ActiveTrackingPanel> createState() => _ActiveTrackingPanelState();
}

class _ActiveTrackingPanelState extends State<ActiveTrackingPanel> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, provider, child) {
        if (!provider.hasActiveInstance) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.all(8),
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking: ${provider.activeProject?.name ?? "Unknown"}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StreamBuilder(
                            stream: Stream.periodic(const Duration(seconds: 30)),
                            builder: (context, snapshot) {
                              final duration = provider.getCurrentDuration();
                              return Text(
                                'Duration: ${_formatDuration(duration)}',
                                style: TextStyle(color: Colors.grey.shade700),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _endTracking(context, provider),
                      icon: const Icon(Icons.stop),
                      label: const Text('End'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Notes (${provider.currentNotes.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Display existing notes
                if (provider.currentNotes.isNotEmpty)
                  ...provider.currentNotes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${note.content}'),
                      )),
                const SizedBox(height: 8),
                // Add note input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'Add a note...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.blue,
                      onPressed: () => _addNote(context, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<void> _addNote(BuildContext context, TrackingProvider provider) async {
    final content = _noteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty')),
      );
      return;
    }

    await provider.addNote(content);
    _noteController.clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added')),
      );
    }
  }

  Future<void> _endTracking(BuildContext context, TrackingProvider provider) async {
    final projectName = provider.activeProject?.name ?? 'Unknown';
    
    await provider.endCurrentInstance();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ended tracking: $projectName')),
      );
    }
  }
}
