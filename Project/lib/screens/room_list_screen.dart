import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
import '../widgets/presence_indicator.dart';
import 'enhanced_chat_screen.dart';
import 'create_room_screen.dart';
import 'user_list_screen.dart';

class RoomListScreen extends StatefulWidget {
  final User user;

  const RoomListScreen({super.key, required this.user});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> with SingleTickerProviderStateMixin {
  final _roomService = RoomService();
  final _authService = AuthService();
  late TabController _tabController;
  List<ChatRoom> _userRooms = [];
  List<ChatRoom> _publicRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
  }

  void _loadRooms() async {
    setState(() => _isLoading = true);
    
    final userRooms = await _roomService.getUserRooms(widget.user.id);
    final publicRooms = await _roomService.getPublicRooms();
    
    setState(() {
      _userRooms = userRooms;
      _publicRooms = publicRooms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.user.username}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Chats', icon: Icon(Icons.chat)),
            Tab(text: 'Public Rooms', icon: Icon(Icons.public)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _showUserList(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_room',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Create Room'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'create_room') _createRoom();
              if (value == 'logout') _logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserRooms(),
                _buildPublicRooms(),
              ],
            ),
    );
  }

  Widget _buildUserRooms() {
    if (_userRooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start a conversation or join a public room',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userRooms.length,
      itemBuilder: (context, index) {
        final room = _userRooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildPublicRooms() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _publicRooms.length,
      itemBuilder: (context, index) {
        final room = _publicRooms[index];
        final isJoined = room.participants.contains(widget.user.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                room.isPrivate ? Icons.lock : Icons.public,
                color: Colors.white,
              ),
            ),
            title: Text(
              room.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (room.description != null)
                  Text(room.description!),
                const SizedBox(height: 4),
                Text(
                  '${room.participants.length} members',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: isJoined
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: () => _joinRoom(room),
                    child: const Text('Join'),
                  ),
            onTap: isJoined ? () => _openRoom(room) : null,
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(ChatRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: room.isPrivate ? Colors.purple : Colors.blue,
              child: Icon(
                room.isPrivate ? Icons.person : Icons.group,
                color: Colors.white,
              ),
            ),
            if (room.unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${room.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          room.getDisplayName(widget.user.id),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.lastMessage != null)
              Text(
                room.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  room.isPrivate ? Icons.lock : Icons.public,
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  room.isPrivate ? 'Private' : 'Public',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                if (room.lastActivity != null)
                  Text(
                    _formatTime(room.lastActivity!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _openRoom(room),
        onLongPress: () => _showRoomOptions(room),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openRoom(ChatRoom room) async {
    await _roomService.setCurrentRoom(room.id);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedChatScreen(
            user: widget.user,
            room: room,
          ),
        ),
      ).then((_) => _loadRooms());
    }
  }

  void _joinRoom(ChatRoom room) async {
    await _roomService.joinRoom(room.id, widget.user.id);
    _loadRooms();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${room.name}')),
      );
    }
  }

  void _createRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(user: widget.user),
      ),
    ).then((_) => _loadRooms());
  }

  void _showUserList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListScreen(currentUser: widget.user),
      ),
    ).then((_) => _loadRooms());
  }

  void _showRoomOptions(ChatRoom room) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Room Info'),
              onTap: () {
                Navigator.pop(context);
                _showRoomInfo(room);
              },
            ),
            if (!room.isPrivate)
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave Room'),
                onTap: () {
                  Navigator.pop(context);
                  _leaveRoom(room);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRoomInfo(ChatRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.description != null) ...[
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(room.description!),
              const SizedBox(height: 16),
            ],
            const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(room.isPrivate ? 'Private Chat' : 'Public Room'),
            const SizedBox(height: 8),
            const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${room.participants.length} participants'),
            const SizedBox(height: 8),
            const Text('Created:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatTime(room.createdAt)),
          ],
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

  void _leaveRoom(ChatRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: Text('Are you sure you want to leave ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _roomService.leaveRoom(room.id, widget.user.id);
      _loadRooms();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left ${room.name}')),
        );
      }
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}