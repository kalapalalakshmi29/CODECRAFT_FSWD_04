import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import '../services/chat_history_service.dart';
import '../services/file_service.dart';
import '../services/room_service.dart';
import '../widgets/presence_indicator.dart';
import '../widgets/file_message_widget.dart';
import '../widgets/attachment_picker.dart';

class EnhancedChatScreen extends StatefulWidget {
  final User user;
  final ChatRoom? room;

  const EnhancedChatScreen({super.key, required this.user, this.room});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _webSocketService = WebSocketService();
  final _notificationService = NotificationService();
  final _historyService = ChatHistoryService();
  final _fileService = FileService();
  final _roomService = RoomService();
  final List<Message> _messages = [];
  final List<User> _onlineUsers = [];
  final List<String> _typingUsers = [];
  
  bool _isDarkMode = true;
  bool _showNotifications = true;
  Timer? _typingTimer;
  int _unreadCount = 0;
  late ChatRoom _currentRoom;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room ?? ChatRoom(
      id: 'general',
      name: 'General Chat',
      type: RoomType.public,
      participants: [widget.user.id],
      createdAt: DateTime.now(),
    );
    _loadChatHistory();
    _setupWebSocket();
    _setupNotifications();
    _setupTypingIndicator();
  }

  void _loadChatHistory() async {
    final history = await _historyService.getHistory();
    final unreadCount = await _historyService.getUnreadCount();
    setState(() {
      _messages.addAll(history);
      _unreadCount = unreadCount;
    });
    _scrollToBottom();
  }

  void _setupWebSocket() {
    _webSocketService.connect(widget.user.id, widget.user.username);
    
    _webSocketService.messageStream.listen((message) {
      setState(() => _messages.add(message));
      _historyService.saveMessage(message);
      _scrollToBottom();
      
      if (message.senderId != widget.user.id && _showNotifications) {
        _notificationService.showMessageNotification(message);
      }
    });
    
    _webSocketService.usersStream.listen((users) {
      final newUsers = users.where((u) => !_onlineUsers.any((existing) => existing.id == u.id));
      for (final user in newUsers) {
        if (user.id != widget.user.id) {
          _notificationService.showUserJoinedNotification(user.username);
        }
      }
      
      setState(() {
        _onlineUsers.clear();
        _onlineUsers.addAll(users);
      });
    });
  }

  void _setupNotifications() {
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_getNotificationIcon(notification.type), color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(notification.body),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _setupTypingIndicator() {
    _controller.addListener(() {
      if (_controller.text.isNotEmpty) {
        _webSocketService.sendTypingIndicator(true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          _webSocketService.sendTypingIndicator(false);
        });
      }
    });
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.userJoined:
        return Icons.person_add;
      case NotificationType.typing:
        return Icons.edit;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    final message = Message(
      id: const Uuid().v4(),
      senderId: widget.user.id,
      senderName: widget.user.username,
      content: _controller.text.trim(),
      roomId: _currentRoom.id,
      timestamp: DateTime.now(),
    );
    
    _webSocketService.sendMessage(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(user: widget.user, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentRoom.getDisplayName(widget.user.id),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_onlineUsers.length} users online',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showNotifications ? Icons.notifications : Icons.notifications_off),
            onPressed: () => setState(() => _showNotifications = !_showNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Clear History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'users',
                child: Row(
                  children: [
                    Icon(Icons.people),
                    SizedBox(width: 8),
                    Text('Online Users'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'history') _clearHistory();
              if (value == 'users') _showOnlineUsers();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkMode
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _typingUsers.isNotEmpty) {
                    return _buildTypingIndicator();
                  }
                  
                  final message = _messages[index];
                  final isMe = message.senderId == widget.user.id;
                  
                  return _buildEnhancedMessageBubble(message, isMe);
                },
              ),
            ),
            _buildEnhancedInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...<Widget>[
            UserAvatar(
              user: User(id: message.senderId, username: message.senderName, isOnline: true),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    if (message.type == MessageType.file || message.type == MessageType.image)
                      FileMessageWidget(message: message, isMe: isMe)
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : (_isDarkMode ? Colors.black : Colors.black87),
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.isRead ? Colors.blue.shade200 : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...<Widget>[
            const SizedBox(width: 8),
            UserAvatar(
              user: widget.user,
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _fileService.getFileIcon(message.fileName ?? ''),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap to download',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(Message message) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 40, color: Colors.grey),
            Text('Image Preview', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Text(
              _typingUsers.first[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_typingUsers.first} is typing',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentPicker(
        onFileSelected: (file, type) => _sendFileMessage(file, type),
      ),
    );
  }

  void _pickAndSendImage() async {
    final result = await _fileService.pickImage();
    if (result != null) {
      _sendFileMessage(result, MessageType.image);
    }
  }

  void _pickAndSendFile() async {
    final result = await _fileService.pickFile();
    if (result != null) {
      _sendFileMessage(result, MessageType.file);
    }
  }

  void _sendFileMessage(FilePickerResult file, MessageType type) async {
    final fileUrl = await _fileService.uploadFile(file.fileBytes, file.fileName);
    if (fileUrl != null) {
      final message = Message(
        id: const Uuid().v4(),
        senderId: widget.user.id,
        senderName: widget.user.username,
        content: type == MessageType.image ? '📷 Image' : '📎 ${file.fileName}',
        roomId: _currentRoom.id,
        timestamp: DateTime.now(),
        type: type,
        fileUrl: fileUrl,
        fileName: file.fileName,
      );
      _webSocketService.sendMessage(message);
    }
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _controller.text = '@${message.senderName} ';
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // Copy to clipboard
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return AlertDialog(
          title: const Text('Search Messages'),
          content: TextField(
            onChanged: (value) => query = value,
            decoration: const InputDecoration(
              hintText: 'Enter search term...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final results = await _historyService.searchMessages(query);
                _showSearchResults(results, query);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchResults(List<Message> results, String query) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Results for "$query"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: results.isEmpty
              ? const Center(child: Text('No messages found'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final message = results[index];
                    return ListTile(
                      title: Text(message.senderName),
                      subtitle: Text(message.content),
                      trailing: Text(
                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _historyService.clearHistory();
      setState(() {
        _messages.clear();
        _unreadCount = 0;
      });
    }
  }

  void _showOnlineUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Online Users'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _onlineUsers.length,
            itemBuilder: (context, index) {
              final user = _onlineUsers[index];
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(user.username[0].toUpperCase()),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: user.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(user.username),
                subtitle: Text(user.presenceText),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}