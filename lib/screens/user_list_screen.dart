import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/room_service.dart';
import '../widgets/presence_indicator.dart';
import 'enhanced_chat_screen.dart';

class UserListScreen extends StatefulWidget {
  final User currentUser;

  const UserListScreen({super.key, required this.currentUser});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _roomService = RoomService();
  final List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    // Simulate loading users (in real app, would fetch from server)
    setState(() {
      _users.addAll([
        User(id: 'user1', username: 'Alice', isOnline: true),
        User(id: 'user2', username: 'Bob', isOnline: false, lastSeen: DateTime.now().subtract(const Duration(minutes: 5))),
        User(id: 'user3', username: 'Charlie', isOnline: true),
        User(id: 'user4', username: 'Diana', isOnline: false, lastSeen: DateTime.now().subtract(const Duration(hours: 2))),
        User(id: 'user5', username: 'Eve', isOnline: true),
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return _buildUserCard(user);
              },
            ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: UserAvatar(user: user, radius: 20),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user.presenceText,
          style: TextStyle(
            color: user.isOnline ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _startPrivateChat(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Chat'),
        ),
      ),
    );
  }

  void _startPrivateChat(User user) async {
    try {
      final room = await _roomService.createPrivateRoom(
        widget.currentUser.id,
        user.id,
        widget.currentUser.username,
        user.username,
      );

      if (mounted) {
        Navigator.pop(context); // Close user list
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatScreen(
              user: widget.currentUser,
              room: room,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}