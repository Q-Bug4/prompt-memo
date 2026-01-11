import 'package:flutter/material.dart';
import 'package:prompt_memo/features/prompt-management/domain/services/file_picker_service.dart';

/// Dialog for selecting and adding result sample files
class FilePickerDialog extends StatelessWidget {
  final Function(PickedFile? file) onFileSelected;

  const FilePickerDialog({
    super.key,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Result Sample'),
      content: const Text('Choose the type of file you want to add'),
      actions: [
        _buildFileOption(
          context,
          icon: Icons.description,
          label: 'Text File',
          color: Colors.blue,
          type: PickedFileType.text,
        ),
        _buildFileOption(
          context,
          icon: Icons.image,
          label: 'Image',
          color: Colors.green,
          type: PickedFileType.image,
        ),
        _buildFileOption(
          context,
          icon: Icons.videocam,
          label: 'Video',
          color: Colors.purple,
          type: PickedFileType.video,
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildFileOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required PickedFileType type,
  }) {
    return TextButton.icon(
      onPressed: () async {
        final service = FilePickerService();
        PickedFile? file;

        switch (type) {
          case PickedFileType.text:
            file = await service.pickTextFile();
          case PickedFileType.image:
            file = await service.pickImageFile();
          case PickedFileType.video:
            file = await service.pickVideoFile();
        }

        if (context.mounted) {
          // Call callback - let the callback handle closing the dialog
          onFileSelected(file);
        }
      },
      icon: Icon(icon, color: color),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
      ),
    );
  }
}
