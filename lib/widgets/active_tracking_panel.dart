import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:project_tracking/providers/tracking_provider.dart';

class ActiveTrackingPanel extends StatefulWidget {
  const ActiveTrackingPanel({super.key});

  @override
  State<ActiveTrackingPanel> createState() => _ActiveTrackingPanelState();
}

class _ActiveTrackingPanelState extends State<ActiveTrackingPanel> {
  final _noteController = TextEditingController();
  DateTime? _customEndTime;

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
                            stream: Stream.periodic(
                              const Duration(seconds: 30),
                            ),
                            builder: (context, snapshot) {
                              final duration = provider.getCurrentDuration();
                              return Text(
                                'Duration: ${_formatDuration(duration)}',
                                style: TextStyle(color: Colors.grey.shade700),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start: ${_formatDateTime(provider.activeInstance!.startTime)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
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
                const SizedBox(height: 12),
                // End time editor
                Row(
                  children: [
                    const Text(
                      'End Time:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _selectEndTime(context),
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: Text(
                        _formatDateTime(_customEndTime ?? DateTime.now()),
                        style: const TextStyle(fontSize: 14),
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
                  ...provider.currentNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${note.content}'),
                    ),
                  ),
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

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM d, y h:mm a');
    return formatter.format(dateTime);
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    if (provider.activeInstance == null) return;

    final startTime = provider.activeInstance!.startTime;
    final now = DateTime.now();
    final initialTime = _customEndTime ?? now;

    // First select date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialTime,
      firstDate: startTime,
      lastDate: now,
      helpText: 'Select End Date',
    );

    if (selectedDate == null || !context.mounted) return;

    // Then select time
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
      helpText: 'Select End Time',
    );

    if (selectedTime == null || !context.mounted) return;

    // Combine date and time
    final combinedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Validate: end time must not be later than now
    if (combinedDateTime.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time cannot be in the future'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (combinedDateTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time cannot be before start time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _customEndTime = combinedDateTime;
    });
  }

  Future<void> _addNote(BuildContext context, TrackingProvider provider) async {
    final content = _noteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note cannot be empty')));
      return;
    }

    await provider.addNote(content);
    _noteController.clear();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note added')));
    }
  }

  Future<void> _endTracking(
    BuildContext context,
    TrackingProvider provider,
  ) async {
    final projectName = provider.activeProject?.name ?? 'Unknown';

    await provider.endCurrentInstance(customEndTime: _customEndTime);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ended tracking: $projectName')));
    }

    // Reset custom end time
    setState(() {
      _customEndTime = null;
    });
  }
}
