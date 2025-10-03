import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/user.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Message> _messageController = StreamController.broadcast();
  final StreamController<List<User>> _usersController = StreamController.broadcast();
  final List<User> _connectedUsers = [];
  String? _currentUserId;
  
  Stream<Message> get messageStream => _messageController.stream;
  Stream<List<User>> get usersStream => _usersController.stream;

  void connect(String userId, String username) {
    _currentUserId = userId;
    
    // Add current user to connected users
    final currentUser = User(id: userId, username: username, isOnline: true);
    _connectedUsers.add(currentUser);
    _usersController.add(List.from(_connectedUsers));
    
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://echo.websocket.org/'),
      );
      
      _channel!.stream.listen(
        (data) => _handleEchoMessage(data),
        onError: (error) => debugPrint('WebSocket error: $error'),
        onDone: () => debugPrint('WebSocket connection closed'),
      );
    } catch (e) {
      debugPrint('Connection error: $e');
    }
  }

  void _handleEchoMessage(dynamic data) {
    try {
      final json = jsonDecode(data);
      if (json['type'] == 'message') {
        final message = Message.fromJson(json['data']);
        // Only add message if it's not from current user (to simulate other users)
        if (message.senderId != _currentUserId) {
          _messageController.add(message);
        }
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void sendMessage(Message message) {
    // Add message to local stream immediately
    _messageController.add(message);
    
    // Send to WebSocket (will echo back)
    _sendMessage({
      'type': 'message',
      'data': message.toJson(),
    });
    
    // Simulate other users responding
    _simulateResponse(message);
  }

  void _simulateResponse(Message originalMessage) {
    Timer(const Duration(seconds: 2), () {
      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'bot',
        senderName: 'ChatBot',
        content: 'Thanks for your message: "${originalMessage.content}"',
        roomId: originalMessage.roomId,
        timestamp: DateTime.now(),
      );
      _messageController.add(botMessage);
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void sendTypingIndicator(bool isTyping) {
    _sendMessage({
      'type': 'typing',
      'data': {
        'userId': _currentUserId,
        'isTyping': isTyping,
      },
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _messageController.close();
    _usersController.close();
  }
}