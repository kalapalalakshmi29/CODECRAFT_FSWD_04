import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/websocket_service.dart';
import '../widgets/advanced_message_bubble.dart';
import '../widgets/advanced_typing_indicator.dart';
import '../widgets/chat_input_field.dart';

class AdvancedChatScreen extends StatefulWidget {
  final User user;

  const AdvancedChatScreen({super.key, required this.user});

  @override
  State<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _webSocketService = WebSocketService();
  final List<Message> _messages = [];
  final List<User> _onlineUsers = [];
  final List<String> _typingUsers = [];
  
  Timer? _typingTimer;
  late AnimationController _backgroundController;
  late AnimationController _fabController;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    
    _backgroundController.repeat();
    _scrollController.addListener(_onScroll);
    
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
    
    // Simulate typing users
    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _typingUsers.clear();
          if (_messages.isNotEmpty) {
            _typingUsers.add('Assistant');
          }
        });
        Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _typingUsers.clear());
        });
      }
    });
  }

  void _onScroll() {
    final showFab = _scrollController.offset > 100;
    if (showFab != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showFab);
      if (showFab) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea).withOpacity(0.1),
              const Color(0xFF764ba2).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAdvancedAppBar(),
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _typingUsers.isNotEmpty) {
                      return AdvancedTypingIndicator(username: _typingUsers.first);
                    }
                    
                    final message = _messages[index];
                    final isMe = message.senderId == widget.user.id;
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: AdvancedMessageBubble(
                            message: message,
                            isMe: isMe,
                            onReply: () => _replyToMessage(message),
                            onReact: () => _reactToMessage(message),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            ChatInputField(
              controller: _controller,
              onSend: _sendMessage,
              onAttachment: _showAttachmentOptions,
              onVoice: _startVoiceRecording,
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _scrollToBottom,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.user.username[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF667eea),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ).animate().scale(delay: 200.ms),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().slideX(delay: 300.ms),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ).animate().scale(delay: 400.ms),
                        const SizedBox(width: 6),
                        Text(
                          '${_onlineUsers.length} online',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ).animate().slideX(delay: 500.ms),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showOnlineUsers,
                icon: const Icon(Icons.people_outline, color: Colors.white, size: 26),
              ).animate().scale(delay: 600.ms),
              IconButton(
                onPressed: _showChatSettings,
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 26),
              ).animate().scale(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _replyToMessage(Message message) {
    _controller.text = '@${message.senderName} ';
  }

  void _reactToMessage(Message message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reacted to ${message.senderName}\'s message'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphicContainer(
        width: double.infinity,
        height: 300,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.bottomCenter,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.pink),
                  _buildAttachmentOption(Icons.photo_library, 'Gallery', Colors.purple),
                  _buildAttachmentOption(Icons.attach_file, 'Document', Colors.blue),
                  _buildAttachmentOption(Icons.location_on, 'Location', Colors.green),
                  _buildAttachmentOption(Icons.contact_phone, 'Contact', Colors.orange),
                  _buildAttachmentOption(Icons.music_note, 'Audio', Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().scale(delay: Duration(milliseconds: 100 * [Icons.camera_alt, Icons.photo_library, Icons.attach_file, Icons.location_on, Icons.contact_phone, Icons.music_note].indexOf(icon)));
  }

  void _startVoiceRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic, color: Colors.white),
            const SizedBox(width: 8),
            Text('Voice recording started...', style: GoogleFonts.poppins()),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showOnlineUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphicContainer(
        width: double.infinity,
        height: 400,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.bottomCenter,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Online Users (${_onlineUsers.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: user.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ).animate().slideX(delay: Duration(milliseconds: index * 100));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat settings coming soon!', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _backgroundController.dispose();
    _fabController.dispose();
    _typingTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}