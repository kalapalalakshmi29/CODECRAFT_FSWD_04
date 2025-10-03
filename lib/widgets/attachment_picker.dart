import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/file_service.dart';
import '../models/message.dart';

class AttachmentPicker extends StatelessWidget {
  final Function(FilePickerResult, MessageType) onFileSelected;

  const AttachmentPicker({
    super.key,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share Content',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                icon: Icons.image,
                label: 'Image',
                color: Colors.blue,
                onTap: () => _pickImage(context),
              ),
              _buildOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () => _pickVideo(context),
              ),
              _buildOption(
                icon: Icons.attach_file,
                label: 'File',
                color: Colors.green,
                onTap: () => _pickFile(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _pickImage(BuildContext context) async {
    Navigator.pop(context);
    final result = await FileService().pickImage();
    if (result != null) {
      onFileSelected(result, MessageType.image);
    }
  }

  void _pickVideo(BuildContext context) async {
    Navigator.pop(context);
    // Simulate video file
    final result = FilePickerResult(
      fileName: 'sample_video.mp4',
      fileSize: 5 * 1024 * 1024, // 5MB
      fileBytes: Uint8List(0),
    );
    onFileSelected(result, MessageType.file);
  }

  void _pickFile(BuildContext context) async {
    Navigator.pop(context);
    final result = await FileService().pickFile();
    if (result != null) {
      onFileSelected(result, MessageType.file);
    }
  }
}

