import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/websocket_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart' as typing;

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _webSocketService = WebSocketService();
  final List<Message> _messages = [];
  final List<User> _onlineUsers = [];
  final List<String> _typingUsers = [];
  
  Timer? _typingTimer;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    
    _webSocketService.connect(widget.user.id, widget.user.username);
    
    _webSocketService.messageStream.listen((message) {
      setState(() => _messages.add(message));
      _scrollToBottom();
    });
    
    _webSocketService.usersStream.listen((users) {
      setState(() {
        _onlineUsers.clear();
        _onlineUsers.addAll(users);
      });
    });
    
    _controller.addListener(_onTyping);
  }

  void _onTyping() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      // Stop typing indicator
    });
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
      roomId: 'general',
      timestamp: DateTime.now(),
    );
    
    _webSocketService.sendMessage(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _typingUsers.isNotEmpty) {
                  return typing.TypingIndicator(username: _typingUsers.first);
                }
                
                final message = _messages[index];
                final isMe = message.senderId == widget.user.id;
                
                return MessageBubble(
                  message: message,
                  isMe: isMe,
                  onReply: () => _replyToMessage(message),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF667eea),
            child: Text(
              widget.user.username[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'General Chat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_onlineUsers.length} online',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.people_outline, color: Color(0xFF667eea)),
          onPressed: _showOnlineUsers,
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.poppins(),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabController,
      child: FloatingActionButton(
        onPressed: _scrollToBottom,
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }

  void _replyToMessage(Message message) {
    // Implement reply functionality
  }

  void _showOnlineUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Online Users (${_onlineUsers.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _onlineUsers.length,
                itemBuilder: (context, index) {
                  final user = _onlineUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF667eea),
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user.username,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: user.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fabController.dispose();
    _typingTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}