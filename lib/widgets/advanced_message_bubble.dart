import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class AdvancedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onReact;

  const AdvancedMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onReact,
  });

  @override
  State<AdvancedMessageBubble> createState() => _AdvancedMessageBubbleState();
}

class _AdvancedMessageBubbleState extends State<AdvancedMessageBubble> with TickerProviderStateMixin {
  bool _showReactions = false;
  late AnimationController _reactionController;

  @override
  void initState() {
    super.initState();
    _reactionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe) _buildAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: _showMessageOptions,
                    onDoubleTap: widget.onReact,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: widget.isMe
                            ? const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFf8f9fa), Color(0xFFe9ecef)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
                          bottomRight: Radius.circular(widget.isMe ? 6 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.isMe)
                            Text(
                              widget.message.senderName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF667eea),
                              ),
                            ),
                          if (!widget.isMe) const SizedBox(height: 4),
                          _buildMessageContent(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(widget.message.timestamp),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: widget.isMe ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                              if (widget.isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  widget.message.isRead ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: widget.message.isRead ? Colors.lightBlue : Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showReactions) _buildReactionBar(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isMe) _buildAvatar(),
          ],
        ),
      ).animate().slideX(
        begin: widget.isMe ? 0.3 : -0.3,
        duration: 400.ms,
        curve: Curves.easeOutBack,
      ).fadeIn(duration: 300.ms),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.transparent,
        child: Text(
          widget.message.senderName[0].toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      widget.message.content,
      style: GoogleFonts.poppins(
        color: widget.isMe ? Colors.white : Colors.black87,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildReactionBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['❤️', '😂', '👍', '😮', '😢', '😡']
            .map((emoji) => GestureDetector(
                  onTap: () => _addReaction(emoji),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ))
            .toList(),
      ),
    ).animate(controller: _reactionController).scale().fadeIn();
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
  }

  void _addReaction(String emoji) {
    setState(() => _showReactions = false);
    _reactionController.reverse();
    widget.onReact?.call();
  }

  @override
  void dispose() {
    _reactionController.dispose();
    super.dispose();
  }
}