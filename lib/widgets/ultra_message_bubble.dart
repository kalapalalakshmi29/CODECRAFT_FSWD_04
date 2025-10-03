import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class UltraMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onLongPress;

  const UltraMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onReact,
    this.onLongPress,
  });

  @override
  State<UltraMessageBubble> createState() => _UltraMessageBubbleState();
}

class _UltraMessageBubbleState extends State<UltraMessageBubble> with TickerProviderStateMixin {
  bool _showReactions = false;
  late AnimationController _reactionController;
  late AnimationController _glowController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _reactionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe) _buildUltraAvatar(),
            const SizedBox(width: 12),
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
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
                        child: GlassmorphicContainer(
                          width: null,
                          height: null,
                          borderRadius: 25,
                          blur: 20,
                          alignment: Alignment.center,
                          border: 2,
                          linearGradient: widget.isMe
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF667eea).withValues(alpha: 0.8),
                                    const Color(0xFF764ba2).withValues(alpha: 0.8),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.7),
                                  ],
                                ),
                          borderGradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.2),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!widget.isMe) _buildSenderName(),
                                _buildMessageContent(),
                                const SizedBox(height: 8),
                                _buildMessageFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showReactions) _buildUltraReactionBar(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (widget.isMe) _buildUltraAvatar(),
          ],
        ),
      ).animate().slideX(
        begin: widget.isMe ? 0.5 : -0.5,
        duration: 600.ms,
        curve: Curves.elasticOut,
      ).fadeIn(duration: 400.ms),
    );
  }

  Widget _buildUltraAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.transparent,
        child: Text(
          widget.message.senderName[0].toUpperCase(),
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.elasticOut);
  }

  Widget _buildSenderName() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Text(
        widget.message.senderName,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF667eea),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: Text(
        widget.message.content,
        style: GoogleFonts.poppins(
          color: widget.isMe ? Colors.white : Colors.black87,
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(widget.message.timestamp),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: widget.isMe 
                ? Colors.white.withValues(alpha: 0.8) 
                : Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        if (widget.isMe) ...[
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              widget.message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
              size: 16,
              color: widget.message.isRead 
                  ? Colors.lightBlueAccent 
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ).animate().scale(delay: 500.ms),
        ],
      ],
    );
  }

  Widget _buildUltraReactionBar() {
    final reactions = ['❤️', '😂', '👍', '😮', '😢', '🔥', '✨', '🚀'];
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: GlassmorphicContainer(
        width: null,
        height: 50,
        borderRadius: 25,
        blur: 20,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.3),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: reactions.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _addReaction(entry.value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: entry.key * 50))
                  .scale(curve: Curves.elasticOut)
                  .fadeIn();
            }).toList(),
          ),
        ),
      ),
    ).animate(controller: _reactionController)
        .scale(begin: const Offset(0.8, 0.8))
        .fadeIn();
  }

  void _showMessageOptions() {
    setState(() {
      _showReactions = !_showReactions;
      if (_showReactions) {
        _reactionController.forward();
      } else {
        _reactionController.reverse();
      }
    });
    widget.onLongPress?.call();
  }

  void _addReaction(String emoji) {
    setState(() => _showReactions = false);
    _reactionController.reverse();
    widget.onReact?.call();
    
    // Show floating reaction
    _showFloatingReaction(emoji);
  }

  void _showFloatingReaction(String emoji) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: MediaQuery.of(context).size.width * 0.5,
        top: MediaQuery.of(context).size.height * 0.3,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 40),
        ).animate()
            .moveY(begin: 0, end: -100, duration: 1500.ms)
            .fadeOut(delay: 1000.ms)
            .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5)),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _reactionController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}