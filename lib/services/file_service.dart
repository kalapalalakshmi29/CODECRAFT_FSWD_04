import 'dart:typed_data';
import 'package:flutter/material.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  // Simulated file upload (in real app, would upload to server)
  Future<String?> uploadFile(Uint8List fileBytes, String fileName) async {
    try {
      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Return simulated URL
      return 'https://example.com/files/$fileName';
    } catch (e) {
      return null;
    }
  }

  // Get file type icon
  IconData getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if file is image
  bool isImage(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  // Check if file is video
  bool isVideo(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(extension);
  }

  // Simulate file picker (in real app would use file_picker package)
  Future<FilePickerResult?> pickFile() async {
    // Simulate file selection
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock file for demo
    return FilePickerResult(
      fileName: 'sample_document.pdf',
      fileSize: 1024 * 1024, // 1MB
      fileBytes: Uint8List.fromList([]), // Empty for demo
    );
  }

  Future<FilePickerResult?> pickImage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return FilePickerResult(
      fileName: 'sample_image.jpg',
      fileSize: 512 * 1024, // 512KB
      fileBytes: Uint8List.fromList([]),
    );
  }
}

class FilePickerResult {
  final String fileName;
  final int fileSize;
  final Uint8List fileBytes;

  FilePickerResult({
    required this.fileName,
    required this.fileSize,
    required this.fileBytes,
  });
}