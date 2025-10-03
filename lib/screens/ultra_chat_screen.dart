import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:uuid/uuid.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../services/websocket_service.dart';
import '../widgets/ultra_message_bubble.dart';
import '../widgets/ultra_input_field.dart';

class UltraChatScreen extends StatefulWidget {
  final User user;

  const UltraChatScreen({super.key, required this.user});

  @override
  State<UltraChatScreen> createState() => _UltraChatScreenState();
}

class _UltraChatScreenState extends State<UltraChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _webSocketService = WebSocketService();
  final List<Message> _messages = [];
  final List<User> _onlineUsers = [];
  final List<String> _typingUsers = [];
  
  Timer? _typingTimer;
  late AnimationController _backgroundController;
  late AnimationController _fabController;
  late AnimationController _headerController;
  late ConfettiController _confettiController;
  
  bool _showScrollToBottom = false;
  bool _isVoiceMode = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 30));
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    _backgroundController.repeat();
    _headerController.forward();
    _scrollController.addListener(_onScroll);
    
    _webSocketService.connect(widget.user.id, widget.user.username);
    
    _webSocketService.messageStream.listen((message) {
      setState(() => _messages.add(message));
      _scrollToBottom();
      if (message.senderId != widget.user.id) {
        _confettiController.play();
      }
    });
    
    _webSocketService.usersStream.listen((users) {
      setState(() {
        _onlineUsers.clear();
        _onlineUsers.addAll(users);
      });
    });
    
    // Simulate advanced typing
    Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted && _messages.isNotEmpty) {
        setState(() {
          _typingUsers.clear();
          _typingUsers.add(['AI Assistant', 'ChatBot', 'Echo Bot'][Random().nextInt(3)]);
        });
        Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _typingUsers.clear());
        });
      }
    });
  }

  void _onScroll() {
    final showFab = _scrollController.offset > 200;
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
          duration: const Duration(milliseconds: 800),
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
      roomId: 'ultra-general',
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
              const Color(0xFF667eea).withValues(alpha: 0.1),
              const Color(0xFF764ba2).withValues(alpha: 0.1),
              Colors.white,
              const Color(0xFF667eea).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            Column(
              children: [
                _buildUltraAppBar(),
                Expanded(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _typingUsers.isNotEmpty) {
                          return _buildAdvancedTypingIndicator();
                        }
                        
                        final message = _messages[index];
                        final isMe = message.senderId == widget.user.id;
                        
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            verticalOffset: 100.0,
                            curve: Curves.elasticOut,
                            child: FadeInAnimation(
                              child: UltraMessageBubble(
                                message: message,
                                isMe: isMe,
                                onReply: () => _replyToMessage(message),
                                onReact: () => _reactToMessage(message),
                                onLongPress: () => _showMessageOptions(message),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                UltraInputField(
                  controller: _controller,
                  onSend: _sendMessage,
                  onVoiceToggle: () => setState(() => _isVoiceMode = !_isVoiceMode),
                  isVoiceMode: _isVoiceMode,
                  onAttachment: _showUltraAttachments,
                ),
              ],
            ),
            _buildFloatingElements(),
            _buildConfetti(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          painter: UltraBackgroundPainter(_backgroundController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildUltraAppBar() {
    return SlideTransition(
      position: _headerController.drive(Tween(begin: const Offset(0, -1), end: Offset.zero)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                AvatarGlow(
                  animate: true,
                  glowColor: Colors.white,
                  duration: const Duration(milliseconds: 2000),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.1)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        widget.user.username[0].toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white,
                        highlightColor: Colors.white.withValues(alpha: 0.7),
                        child: Text(
                          'Ultra Chat Room',
                          style: GoogleFonts.orbitron(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
                              .then()
                              .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
                          const SizedBox(width: 8),
                          Text(
                            '${_onlineUsers.length} cosmic users online',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildHeaderActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildGlassButton(
          icon: Icons.people_outline_rounded,
          onTap: _showUltraUserList,
        ),
        const SizedBox(width: 12),
        _buildGlassButton(
          icon: Icons.settings_rounded,
          onTap: _showUltraSettings,
        ),
      ],
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: 45,
        height: 45,
        borderRadius: 22.5,
        blur: 15,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildAdvancedTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          AvatarGlow(
            animate: true,
            glowColor: const Color(0xFF667eea),
            duration: const Duration(milliseconds: 1500),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF667eea),
              child: Text(
                _typingUsers.first[0].toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 50,
              borderRadius: 25,
              blur: 20,
              alignment: Alignment.centerLeft,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.grey.withValues(alpha: 0.1),
                  Colors.grey.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.grey.withValues(alpha: 0.3),
                  Colors.grey.withValues(alpha: 0.1),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[600]!,
                      highlightColor: Colors.grey[300]!,
                      child: Text(
                        '${_typingUsers.first} is crafting a message',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.5, 1.5),
                                duration: 800.ms,
                              )
                              .then(delay: Duration(milliseconds: index * 200))
                              .scale(
                                begin: const Offset(1.5, 1.5),
                                end: const Offset(0.5, 0.5),
                                duration: 800.ms,
                              );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        if (_showScrollToBottom)
          Positioned(
            bottom: 100,
            right: 20,
            child: ScaleTransition(
              scale: _fabController,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: GlassmorphicContainer(
                  width: 60,
                  height: 60,
                  borderRadius: 30,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withValues(alpha: 0.8),
                      const Color(0xFF764ba2).withValues(alpha: 0.8),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.6),
                      Colors.white.withValues(alpha: 0.2),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: pi / 2,
        maxBlastForce: 5,
        minBlastForce: 2,
        emissionFrequency: 0.05,
        numberOfParticles: 50,
        gravity: 0.05,
        shouldLoop: false,
        colors: const [
          Color(0xFF667eea),
          Color(0xFF764ba2),
          Colors.white,
          Colors.pinkAccent,
          Colors.greenAccent,
        ],
      ),
    );
  }

  void _replyToMessage(Message message) {
    _controller.text = '@${message.senderName} ';
  }

  void _reactToMessage(Message message) {
    _confettiController.play();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❤️ Reacted to ${message.senderName}\'s message'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF667eea),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showMessageOptions(Message message) {
    // Advanced message options
  }

  void _showUltraAttachments() {
    // Ultra attachment options
  }

  void _showUltraUserList() {
    // Ultra user list modal
  }

  void _showUltraSettings() {
    // Ultra settings modal
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _fabController.dispose();
    _headerController.dispose();
    _confettiController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}

class UltraBackgroundPainter extends CustomPainter {
  final double animationValue;

  UltraBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Animated gradient orbs
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.2 + 0.6 * sin(animationValue * 2 * pi + i));
      final y = size.height * (0.2 + 0.6 * cos(animationValue * 2 * pi + i * 0.7));
      
      paint.shader = RadialGradient(
        colors: [
          Color(0xFF667eea).withValues(alpha: 0.1),
          Color(0xFF764ba2).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 100));
      
      canvas.drawCircle(Offset(x, y), 100, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}