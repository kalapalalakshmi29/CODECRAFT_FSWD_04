import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:avatar_glow/avatar_glow.dart';

class UltraInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onVoiceToggle;
  final bool isVoiceMode;

  const UltraInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.onVoiceToggle,
    this.isVoiceMode = false,
  });

  @override
  State<UltraInputField> createState() => _UltraInputFieldState();
}

class _UltraInputFieldState extends State<UltraInputField> with TickerProviderStateMixin {
  bool _isTyping = false;
  bool _isRecording = false;
  late AnimationController _sendButtonController;
  late AnimationController _voiceController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _voiceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _toggleVoiceMode() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
    }
    widget.onVoiceToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(),
            const SizedBox(width: 12),
            Expanded(child: _buildInputContainer()),
            const SizedBox(width: 12),
            _buildVoiceButton(),
            const SizedBox(width: 12),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return GestureDetector(
      onTap: widget.onAttachment,
      child: GlassmorphicContainer(
        width: 50,
        height: 50,
        borderRadius: 25,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.3),
            const Color(0xFF764ba2).withValues(alpha: 0.3),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Icon(
          Icons.add_circle_outline_rounded,
          color: const Color(0xFF667eea),
          size: 24,
        ),
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.elasticOut);
  }

  Widget _buildInputContainer() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: null,
      borderRadius: 25,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 50, maxHeight: 120),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                minLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: widget.isVoiceMode 
                      ? '🎤 Voice mode active...' 
                      : 'Type your cosmic message...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            _buildEmojiButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton() {
    return GestureDetector(
      onTap: _showEmojiPicker,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF667eea).withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.emoji_emotions_outlined,
          color: const Color(0xFF667eea),
          size: 22,
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: _toggleVoiceMode,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? (1.0 + _pulseController.value * 0.1) : 1.0,
            child: AvatarGlow(
              animate: _isRecording,
              glowColor: Colors.redAccent,
              duration: const Duration(milliseconds: 1000),
              child: GlassmorphicContainer(
                width: 50,
                height: 50,
                borderRadius: 25,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  colors: _isRecording
                      ? [
                          Colors.redAccent.withValues(alpha: 0.8),
                          Colors.red.withValues(alpha: 0.8),
                        ]
                      : [
                          const Color(0xFF667eea).withValues(alpha: 0.3),
                          const Color(0xFF764ba2).withValues(alpha: 0.3),
                        ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isRecording ? Colors.white : const Color(0xFF667eea),
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSendButton() {
    return ScaleTransition(
      scale: _sendButtonController,
      child: GestureDetector(
        onTap: _handleSend,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ).animate().rotate(begin: -0.1, end: 0, curve: Curves.elasticOut),
    );
  }

  void _handleSend() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend();
    }
  }

  void _showEmojiPicker() {
    // Show emoji picker modal
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphicContainer(
        width: double.infinity,
        height: 300,
        borderRadius: 25,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
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
        child: Column(
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
            Expanded(
              child: GridView.count(
                crossAxisCount: 8,
                padding: const EdgeInsets.all(20),
                children: [
                  '😀', '😂', '🥰', '😍', '🤔', '😎', '🥳', '😴',
                  '👍', '👎', '👏', '🙌', '💪', '🤝', '🙏', '✌️',
                  '❤️', '💙', '💚', '💛', '🧡', '💜', '🖤', '🤍',
                  '🔥', '⭐', '✨', '💫', '🌟', '💥', '💯', '🚀',
                ].map((emoji) => GestureDetector(
                  onTap: () {
                    widget.controller.text += emoji;
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    _voiceController.dispose();
    _pulseController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}