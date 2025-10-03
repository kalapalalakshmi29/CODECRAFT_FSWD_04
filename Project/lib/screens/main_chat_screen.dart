import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../services/websocket_service.dart';
import '../services/chat_history_service.dart';
import '../services/notification_service.dart';

class MainChatScreen extends StatefulWidget {
  final User user;

  const MainChatScreen({super.key, required this.user});

  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _webSocketService = WebSocketService();
  final _historyService = ChatHistoryService();
  final _notificationService = NotificationService();
  
  final List<ChatRoom> _rooms = [];
  final List<User> _users = [];
  final List<Message> _messages = [];
  final _controller = TextEditingController();
  
  ChatRoom? _currentRoom;
  bool _showNotifications = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _setupWebSocket();
    _setupNotifications();
  }

  void _initializeData() {
    // Create default rooms
    _rooms.addAll([
      ChatRoom(id: 'general', name: 'General', type: RoomType.public, participants: [], createdAt: DateTime.now()),
      ChatRoom(id: 'tech', name: 'Tech Talk', type: RoomType.public, participants: [], createdAt: DateTime.now()),
    ]);
    
    // Add sample users
    _users.addAll([
      User(id: 'user1', username: 'Alice', isOnline: true),
      User(id: 'user2', username: 'Bob', isOnline: true),
      User(id: 'user3', username: 'Charlie', isOnline: false, lastSeen: DateTime.now().subtract(const Duration(minutes: 5))),
    ]);
    
    _currentRoom = _rooms.first;
    _loadHistory();
  }

  void _setupWebSocket() {
    _webSocketService.connect(widget.user.id, widget.user.username);
    _webSocketService.messageStream.listen((message) {
      setState(() => _messages.add(message));
      _historyService.saveMessage(message);
      if (message.senderId != widget.user.id && _showNotifications) {
        _notificationService.showMessageNotification(message);
      }
    });
  }

  void _setupNotifications() {
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _loadHistory() async {
    final history = await _historyService.getHistory();
    setState(() => _messages.addAll(history));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoom?.name ?? 'Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Rooms', icon: Icon(Icons.chat)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Chat', icon: Icon(Icons.message)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showNotifications ? Icons.notifications : Icons.notifications_off),
            onPressed: () => setState(() => _showNotifications = !_showNotifications),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoomsTab(),
          _buildUsersTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rooms.length + 1,
      itemBuilder: (context, index) {
        if (index == _rooms.length) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: const Text('Create New Room'),
              onTap: _createRoom,
            ),
          );
        }
        
        final room = _rooms[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(room.type == RoomType.public ? Icons.public : Icons.lock),
            ),
            title: Text(room.name),
            subtitle: Text('${room.participants.length} members'),
            trailing: _currentRoom?.id == room.id ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => _joinRoom(room),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          child: ListTile(
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
            trailing: ElevatedButton(
              onPressed: () => _startPrivateChat(user),
              child: const Text('Chat'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    if (_currentRoom == null) {
      return const Center(child: Text('Select a room to start chatting'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.chat, color: Colors.blue),
              const SizedBox(width: 8),
              Text('${_currentRoom!.name} - ${_messages.length} messages'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _showHistory,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _showFileOptions,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isMe = message.senderId == widget.user.id;
              return _buildMessageBubble(message, isMe);
            },
          ),
        ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(message.senderName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) Text(message.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    message.content,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                  ),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty || _currentRoom == null) return;
    
    final message = Message(
      id: const Uuid().v4(),
      senderId: widget.user.id,
      senderName: widget.user.username,
      content: _controller.text.trim(),
      roomId: _currentRoom!.id,
      timestamp: DateTime.now(),
    );
    
    _webSocketService.sendMessage(message);
    _controller.clear();
  }

  void _joinRoom(ChatRoom room) {
    setState(() => _currentRoom = room);
    _tabController.animateTo(2);
    _notificationService.showUserJoinedNotification('You joined ${room.name}');
  }

  void _startPrivateChat(User user) {
    final privateRoom = ChatRoom(
      id: 'private_${widget.user.id}_${user.id}',
      name: 'Chat with ${user.username}',
      type: RoomType.private,
      participants: [widget.user.id, user.id],
      createdAt: DateTime.now(),
    );
    
    setState(() {
      if (!_rooms.any((r) => r.id == privateRoom.id)) {
        _rooms.add(privateRoom);
      }
      _currentRoom = privateRoom;
    });
    
    _tabController.animateTo(2);
    _notificationService.showUserJoinedNotification('Started private chat with ${user.username}');
  }

  void _createRoom() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Create Room'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Room name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final room = ChatRoom(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    type: RoomType.public,
                    participants: [widget.user.id],
                    createdAt: DateTime.now(),
                  );
                  setState(() => _rooms.add(room));
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chat History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final msg = history[index];
                return ListTile(
                  title: Text(msg.senderName),
                  subtitle: Text(msg.content),
                  trailing: Text('${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  void _showFileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Share Image'),
              onTap: () {
                Navigator.pop(context);
                _sendFileMessage('📷 Image shared', MessageType.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.green),
              title: const Text('Share File'),
              onTap: () {
                Navigator.pop(context);
                _sendFileMessage('📎 Document.pdf', MessageType.file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendFileMessage(String content, MessageType type) {
    final message = Message(
      id: const Uuid().v4(),
      senderId: widget.user.id,
      senderName: widget.user.username,
      content: content,
      roomId: _currentRoom!.id,
      timestamp: DateTime.now(),
      type: type,
    );
    _webSocketService.sendMessage(message);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }
}