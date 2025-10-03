import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/file_service.dart';

class FileMessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;

  const FileMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final fileService = FileService();
    
    if (message.type == MessageType.image) {
      return _buildImageMessage();
    } else if (message.type == MessageType.file) {
      return _buildFileMessage(fileService);
    }
    
    return Text(message.content);
  }

  Widget _buildImageMessage() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Image', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.download,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(FileService fileService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fileService.getFileIcon(message.fileName ?? ''),
            color: isMe ? Colors.white : Colors.grey.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap to download',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.download,
            color: isMe ? Colors.white70 : Colors.grey.shade600,
            size: 16,
          ),
        ],
      ),
    );
  }
}