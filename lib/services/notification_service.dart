import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<ChatNotification> _notificationController = StreamController<ChatNotification>.broadcast();
  Stream<ChatNotification> get notificationStream => _notificationController.stream;

  void showMessageNotification(Message message, {bool isCurrentChat = false}) {
    if (!isCurrentChat) {
      final notification = ChatNotification(
        title: message.senderName,
        body: _getNotificationBody(message),
        type: NotificationType.message,
        timestamp: DateTime.now(),
        messageId: message.id,
      );
      _notificationController.add(notification);
    }
  }

  void showUserJoinedNotification(String username) {
    final notification = ChatNotification(
      title: 'User Joined',
      body: '$username joined the chat',
      type: NotificationType.userJoined,
      timestamp: DateTime.now(),
    );
    _notificationController.add(notification);
  }

  void showTypingNotification(String username) {
    final notification = ChatNotification(
      title: 'Typing',
      body: '$username is typing...',
      type: NotificationType.typing,
      timestamp: DateTime.now(),
    );
    _notificationController.add(notification);
  }

  String _getNotificationBody(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Sent an image';
      case MessageType.file:
        return '📎 Sent a file: ${message.fileName}';
      case MessageType.emoji:
        return message.content;
    }
  }

  void dispose() {
    _notificationController.close();
  }
}

enum NotificationType { message, userJoined, typing }

class ChatNotification {
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final String? messageId;

  ChatNotification({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.messageId,
  });
}