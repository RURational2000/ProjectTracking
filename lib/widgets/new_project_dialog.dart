import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_tracking/providers/tracking_provider.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'Enter project name',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Project name is required';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _createProject(context),
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createProject(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    var projectName = _controller.text.trim();
    var provider = Provider.of<TrackingProvider>(context, listen: false);

    // Close dialog first to avoid disposed context issues
    Navigator.pop(context);

    try {
      await provider.createProject(projectName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created project: $projectName')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
