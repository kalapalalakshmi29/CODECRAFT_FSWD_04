import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/message.dart';

class HyperMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onLongPress;
  final bool isDarkMode;

  const HyperMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onReact,
    this.onLongPress,
    this.isDarkMode = true,
  });

  @override
  State<HyperMessageBubble> createState() => _HyperMessageBubbleState();
}

class _HyperMessageBubbleState extends State<HyperMessageBubble> with TickerProviderStateMixin {
  bool _showReactions = false;
  bool _isHovered = false;
  late AnimationController _reactionController;
  late AnimationController _glowController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _reactionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    _glowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
        child: Row(
          mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe) _buildQuantumAvatar(),
            const SizedBox(width: 15),
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: GestureDetector(
                      onLongPress: _showMessageOptions,
                      onDoubleTap: widget.onReact,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: _isHovered ? [
                                  BoxShadow(
                                    color: (widget.isMe ? Colors.cyanAccent : Colors.blue)
                                        .withValues(alpha: 0.3 + _glowController.value * 0.3),
                                    blurRadius: 20 + _glowController.value * 10,
                                    spreadRadius: 2,
                                  ),
                                ] : [],
                              ),
                              child: GlassmorphicContainer(
                                width: 300,
                                height: 100,
                                borderRadius: 30,
                                blur: 25,
                                alignment: Alignment.center,
                                border: 2.5,
                                linearGradient: widget.isMe
                                    ? LinearGradient(
                                        colors: widget.isDarkMode ? [
                                          const Color(0xFF00D4FF).withValues(alpha: 0.9),
                                          const Color(0xFF5B73FF).withValues(alpha: 0.8),
                                          const Color(0xFF9C27B0).withValues(alpha: 0.9),
                                        ] : [
                                          const Color(0xFF2196F3).withValues(alpha: 0.9),
                                          const Color(0xFF3F51B5).withValues(alpha: 0.8),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: widget.isDarkMode ? [
                                          Colors.white.withValues(alpha: 0.15),
                                          Colors.grey.withValues(alpha: 0.1),
                                        ] : [
                                          Colors.white.withValues(alpha: 0.9),
                                          Colors.grey[100]!.withValues(alpha: 0.8),
                                        ],
                                      ),
                                borderGradient: LinearGradient(
                                  colors: [
                                    Colors.cyanAccent.withValues(alpha: 0.6),
                                    Colors.blue.withValues(alpha: 0.3),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!widget.isMe) _buildQuantumSenderName(),
                                      _buildQuantumMessageContent(),
                                      const SizedBox(height: 10),
                                      _buildQuantumMessageFooter(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_showReactions) _buildQuantumReactionBar(),
                ],
              ),
            ),
            const SizedBox(width: 15),
            if (widget.isMe) _buildQuantumAvatar(),
          ],
        ),
      ).animate().slideX(
        begin: widget.isMe ? 0.8 : -0.8,
        duration: 800.ms,
        curve: Curves.elasticOut,
      ).fadeIn(duration: 600.ms),
    );
  }

  Widget _buildQuantumAvatar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _pulseController.value * 0.1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF00D4FF),
                  Color(0xFF5B73FF),
                  Color(0xFF9C27B0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              child: Text(
                widget.message.senderName[0].toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    ).animate().scale(delay: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildQuantumSenderName() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.cyanAccent,
        highlightColor: Colors.white,
        child: Text(
          widget.message.senderName,
          style: GoogleFonts.rajdhani(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantumMessageContent() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Text(
        widget.message.content,
        style: GoogleFonts.rajdhani(
          color: widget.isMe 
              ? Colors.white 
              : (widget.isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuantumMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(widget.message.timestamp),
          style: GoogleFonts.rajdhani(
            fontSize: 12,
            color: widget.isMe 
                ? Colors.white.withValues(alpha: 0.8) 
                : (widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.isMe) ...[
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            child: Icon(
              widget.message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
              size: 18,
              color: widget.message.isRead 
                  ? Colors.cyanAccent 
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().scale(delay: 800.ms),
        ],
      ],
    );
  }

  Widget _buildQuantumReactionBar() {
    final reactions = ['⚡', '🚀', '💎', '🌟', '🔥', '💫', '✨', '🎯', '💥', '🌈'];
    
    return Container(
      margin: const EdgeInsets.only(top: 15),
      child: GlassmorphicContainer(
        width: 250,
        height: 60,
        borderRadius: 30,
        blur: 25,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: widget.isDarkMode ? [
            Colors.white.withValues(alpha: 0.15),
            Colors.cyanAccent.withValues(alpha: 0.1),
          ] : [
            Colors.white.withValues(alpha: 0.9),
            Colors.grey[100]!.withValues(alpha: 0.8),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withValues(alpha: 0.8),
            Colors.blue.withValues(alpha: 0.4),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: reactions.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _addReaction(entry.value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: entry.key * 80))
                  .scale(curve: Curves.elasticOut)
                  .fadeIn();
            }).toList(),
          ),
        ),
      ),
    ).animate(controller: _reactionController)
        .scale(begin: const Offset(0.5, 0.5))
        .fadeIn();
  }

  void _showMessageOptions() {
    setState(() {
      _showReactions = !_showReactions;
      if (_showReactions) {
        _reactionController.forward();
        _pulseController.repeat(reverse: true);
      } else {
        _reactionController.reverse();
        _pulseController.stop();
      }
    });
    widget.onLongPress?.call();
  }

  void _addReaction(String emoji) {
    setState(() => _showReactions = false);
    _reactionController.reverse();
    _pulseController.stop();
    widget.onReact?.call();
    
    // Show quantum floating reaction
    _showQuantumFloatingReaction(emoji);
  }

  void _showQuantumFloatingReaction(String emoji) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: MediaQuery.of(context).size.width * 0.5,
        top: MediaQuery.of(context).size.height * 0.3,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.cyanAccent.withValues(alpha: 0.8),
                Colors.blue.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 50),
          ),
        ).animate()
            .moveY(begin: 0, end: -150, duration: 2000.ms)
            .fadeOut(delay: 1500.ms)
            .scale(begin: const Offset(1, 1), end: const Offset(2, 2))
            .rotate(begin: 0, end: 0.5),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _reactionController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}