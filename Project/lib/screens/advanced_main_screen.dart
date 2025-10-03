import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../services/websocket_service.dart';
import '../services/chat_history_service.dart';
import '../services/notification_service.dart';

class AdvancedMainScreen extends StatefulWidget {
  final User currentUser;

  const AdvancedMainScreen({super.key, required this.currentUser});

  @override
  State<AdvancedMainScreen> createState() => _AdvancedMainScreenState();
}

class _AdvancedMainScreenState extends State<AdvancedMainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _typingController;
  
  final _webSocketService = WebSocketService();
  final _historyService = ChatHistoryService();
  final _notificationService = NotificationService();
  
  final List<ChatRoom> _rooms = [];
  final List<User> _users = [];
  final List<Message> _messages = [];
  final List<String> _typingUsers = [];
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  
  ChatRoom? _currentRoom;
  bool _showNotifications = true;
  bool _isDarkMode = false;
  bool _isTyping = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _typingController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _initializeData();
    _setupWebSocket();
    _setupNotifications();
    _setupTyping();
  }

  void _initializeData() {
    _rooms.addAll([
      ChatRoom(id: 'general', name: '🌍 General', description: 'General discussion for everyone', type: RoomType.public, participants: [], createdAt: DateTime.now()),
      ChatRoom(id: 'tech', name: '💻 Tech Talk', description: 'Technology discussions', type: RoomType.public, participants: [], createdAt: DateTime.now()),
      ChatRoom(id: 'random', name: '🎲 Random', description: 'Random conversations', type: RoomType.public, participants: [], createdAt: DateTime.now()),
    ]);
    
    _users.addAll([
      User(id: 'user1', username: 'Alice Johnson', isOnline: true, status: 'Available'),
      User(id: 'user2', username: 'Bob Smith', isOnline: true, status: 'Busy'),
      User(id: 'user3', username: 'Charlie Brown', isOnline: false, lastSeen: DateTime.now().subtract(const Duration(minutes: 5))),
      User(id: 'user4', username: 'Diana Prince', isOnline: true, status: 'Away'),
      User(id: 'user5', username: 'Eve Wilson', isOnline: false, lastSeen: DateTime.now().subtract(const Duration(hours: 2))),
    ]);
    
    _currentRoom = _rooms.first;
    _loadHistory();
  }

  void _setupWebSocket() {
    _webSocketService.connect(widget.currentUser.id, widget.currentUser.username);
    
    _webSocketService.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
        if (message.senderId != widget.currentUser.id) _unreadCount++;
      });
      _historyService.saveMessage(message);
      
      if (message.senderId != widget.currentUser.id && _showNotifications) {
        _notificationService.showMessageNotification(message);
      }
    });
  }

  void _setupNotifications() {
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${notification.title}: ${notification.body}')),
              ],
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => _tabController.animateTo(2),
            ),
          ),
        );
      }
    });
  }

  void _setupTyping() {
    _controller.addListener(() {
      if (_controller.text.isNotEmpty && !_isTyping) {
        setState(() => _isTyping = true);
        _typingController.repeat();
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _isTyping = false);
            _typingController.stop();
          }
        });
      }
    });
  }

  void _loadHistory() async {
    final history = await _historyService.getHistory();
    setState(() => _messages.addAll(history));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_currentRoom?.name ?? 'Advanced Chat'),
              if (_currentRoom != null)
                Text(
                  '${_users.where((u) => u.isOnline).length} online • ${_messages.length} messages',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.purple,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Rooms', icon: Icon(Icons.chat_bubble)),
              Tab(text: 'Users', icon: Icon(Icons.people)),
              Tab(text: 'Chat', icon: Stack(
                children: [
                  Icon(Icons.message),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$_unreadCount', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                ],
              )),
              Tab(text: 'Settings', icon: Icon(Icons.settings)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_showNotifications ? Icons.notifications : Icons.notifications_off),
              onPressed: () => setState(() => _showNotifications = !_showNotifications),
            ),
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRoomsTab(),
            _buildUsersTab(),
            _buildChatTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search rooms...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _rooms.length + 1,
            itemBuilder: (context, index) {
              if (index == _rooms.length) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.add)),
                    title: const Text('Create New Room'),
                    subtitle: const Text('Start a new conversation'),
                    onTap: _createRoom,
                  ),
                );
              }
              
              final room = _rooms[index];
              if (_searchController.text.isNotEmpty && 
                  !room.name.toLowerCase().contains(_searchController.text.toLowerCase())) {
                return const SizedBox.shrink();
              }
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _currentRoom?.id == room.id ? Colors.green : Colors.purple,
                    child: Icon(room.type == RoomType.public ? Icons.public : Icons.lock),
                  ),
                  title: Text(room.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room.description != null) Text(room.description!),
                      Text('${room.participants.length} members • Created ${_formatDate(room.createdAt)}'),
                    ],
                  ),
                  trailing: _currentRoom?.id == room.id 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.arrow_forward_ios),
                  onTap: () => _joinRoom(room),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    final onlineUsers = _users.where((u) => u.isOnline).toList();
    final offlineUsers = _users.where((u) => !u.isOnline).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onlineUsers.isNotEmpty) ...[
          Text('Online (${onlineUsers.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...onlineUsers.map((user) => _buildUserCard(user)),
          const SizedBox(height: 16),
        ],
        if (offlineUsers.isNotEmpty) ...[
          Text('Offline (${offlineUsers.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...offlineUsers.map((user) => _buildUserCard(user)),
        ],
      ],
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.presenceText),
            if (user.status != null) Text(user.status!, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () => _startVideoCall(user),
            ),
            ElevatedButton(
              onPressed: () => _startPrivateChat(user),
              child: const Text('Chat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    if (_currentRoom == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a room to start chatting', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.purple.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Icon(Icons.chat, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentRoom!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_messages.where((m) => m.roomId == _currentRoom!.id).length} messages'),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.search), onPressed: _searchMessages),
              IconButton(icon: const Icon(Icons.history), onPressed: _showHistory),
              IconButton(icon: const Icon(Icons.attach_file), onPressed: _showFileOptions),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: _showChatOptions),
            ],
          ),
        ),
        if (_typingUsers.isNotEmpty) _buildTypingIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.where((m) => m.roomId == _currentRoom!.id).length,
            itemBuilder: (context, index) {
              final roomMessages = _messages.where((m) => m.roomId == _currentRoom!.id).toList();
              final message = roomMessages[index];
              final isMe = message.senderId == widget.currentUser.id;
              return _buildAdvancedMessageBubble(message, isMe);
            },
          ),
        ),
        _buildAdvancedInputField(),
      ],
    );
  }

  Widget _buildAdvancedMessageBubble(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple,
              child: Text(message.senderName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.purple : (_isDarkMode ? Colors.grey[700] : Colors.grey.shade300),
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
                    if (message.type == MessageType.file)
                      _buildFileMessage(message, isMe)
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87),
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : (_isDarkMode ? Colors.white54 : Colors.grey.shade600),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.isRead ? Colors.purple.shade200 : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple,
              child: Text(widget.currentUser.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileMessage(Message message, bool isMe) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(message.fileName ?? ''),
            color: isMe ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _typingController,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5 + (_typingController.value * 0.5)),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Text('${_typingUsers.join(", ")} typing...', style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildAdvancedInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
            icon: const Icon(Icons.emoji_emotions),
            onPressed: _showEmojiPicker,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[700] : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.purple,
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                subtitle: Text(widget.currentUser.username),
                trailing: const Icon(Icons.edit),
                onTap: _editProfile,
              ),
              ListTile(
                leading: Icon(_showNotifications ? Icons.notifications : Icons.notifications_off),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: _showNotifications,
                  onChanged: (value) => setState(() => _showNotifications = value),
                ),
              ),
              ListTile(
                leading: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) => setState(() => _isDarkMode = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Clear Chat History'),
                onTap: _clearHistory,
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Export Chat Data'),
                onTap: _exportData,
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: _showAbout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg': case 'jpeg': case 'png': return Icons.image;
      case 'mp4': case 'avi': return Icons.video_file;
      case 'mp3': case 'wav': return Icons.audio_file;
      default: return Icons.insert_drive_file;
    }
  }

  // Action methods
  void _sendMessage() {
    if (_controller.text.trim().isEmpty || _currentRoom == null) return;
    
    final message = Message(
      id: const Uuid().v4(),
      senderId: widget.currentUser.id,
      senderName: widget.currentUser.username,
      content: _controller.text.trim(),
      roomId: _currentRoom!.id,
      timestamp: DateTime.now(),
    );
    
    _webSocketService.sendMessage(message);
    _controller.clear();
    setState(() => _isTyping = false);
  }

  void _joinRoom(ChatRoom room) {
    setState(() {
      _currentRoom = room;
      _unreadCount = 0;
    });
    _tabController.animateTo(2);
    _notificationService.showUserJoinedNotification('Joined ${room.name}');
  }

  void _startPrivateChat(User user) {
    final privateRoom = ChatRoom(
      id: 'private_${widget.currentUser.id}_${user.id}',
      name: '💬 ${user.username}',
      type: RoomType.private,
      participants: [widget.currentUser.id, user.id],
      createdAt: DateTime.now(),
    );
    
    setState(() {
      if (!_rooms.any((r) => r.id == privateRoom.id)) {
        _rooms.add(privateRoom);
      }
      _currentRoom = privateRoom;
    });
    
    _tabController.animateTo(2);
    _notificationService.showUserJoinedNotification('Started chat with ${user.username}');
  }

  void _startVideoCall(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video Call'),
        content: Text('Starting video call with ${user.username}...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Call')),
        ],
      ),
    );
  }

  void _createRoom() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descController = TextEditingController();
        return AlertDialog(
          title: const Text('Create Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Room name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(hintText: 'Description (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final room = ChatRoom(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    type: RoomType.public,
                    participants: [widget.currentUser.id],
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
            height: 400,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final msg = history[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(msg.senderName[0])),
                  title: Text(msg.senderName),
                  subtitle: Text(msg.content),
                  trailing: Text(_formatTime(msg.timestamp)),
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
            const Text('Share Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFileOption(Icons.image, 'Image', Colors.purple, () => _sendFileMessage('📷 Image.jpg', MessageType.image)),
                _buildFileOption(Icons.videocam, 'Video', Colors.red, () => _sendFileMessage('🎥 Video.mp4', MessageType.file)),
                _buildFileOption(Icons.attach_file, 'Document', Colors.green, () => _sendFileMessage('📄 Document.pdf', MessageType.file)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  void _sendFileMessage(String content, MessageType type) {
    final message = Message(
      id: const Uuid().v4(),
      senderId: widget.currentUser.id,
      senderName: widget.currentUser.username,
      content: content,
      roomId: _currentRoom!.id,
      timestamp: DateTime.now(),
      type: type,
      fileName: content.split(' ').last,
    );
    _webSocketService.sendMessage(message);
  }

  void _searchMessages() {
    showDialog(
      context: context,
      builder: (context) {
        final searchController = TextEditingController();
        return AlertDialog(
          title: const Text('Search Messages'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Search...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement search logic
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Room Info'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Members'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Leave Room'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
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
            onTap: () => Navigator.pop(context),
          ),
          if (message.senderId == widget.currentUser.id)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 8,
          children: ['😀', '😂', '😍', '🥰', '😎', '🤔', '😢', '😡', '👍', '👎', '❤️', '🔥', '💯', '🎉', '👏', '🙏']
              .map((emoji) => GestureDetector(
                    onTap: () {
                      _controller.text += emoji;
                      Navigator.pop(context);
                    },
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const TextField(decoration: InputDecoration(hintText: 'New username')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _historyService.clearHistory();
              setState(() => _messages.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _historyService.deleteMessage(message.id);
              setState(() => _messages.removeWhere((m) => m.id == message.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat data exported successfully!')),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Advanced Chat',
      applicationVersion: '1.0.0',
      children: [const Text('A feature-rich real-time chat application.')],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _typingController.dispose();
    _controller.dispose();
    _searchController.dispose();
    _webSocketService.disconnect();
    super.dispose();
  }
}