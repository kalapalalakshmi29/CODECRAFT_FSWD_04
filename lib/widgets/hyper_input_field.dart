import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:shimmer/shimmer.dart';

class HyperInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onVoiceToggle;
  final bool isVoiceMode;
  final bool isDarkMode;

  const HyperInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.onVoiceToggle,
    this.isVoiceMode = false,
    this.isDarkMode = true,
  });

  @override
  State<HyperInputField> createState() => _HyperInputFieldState();
}

class _HyperInputFieldState extends State<HyperInputField> with TickerProviderStateMixin {
  bool _isTyping = false;
  bool _isRecording = false;
  late AnimationController _sendButtonController;
  late AnimationController _voiceController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _voiceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    
    widget.controller.addListener(_onTextChanged);
    _glowController.repeat(reverse: true);
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
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode ? [
            Colors.transparent,
            const Color(0xFF0F0C29).withValues(alpha: 0.8),
            const Color(0xFF24243e).withValues(alpha: 0.9),
          ] : [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -15),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildQuantumAttachmentButton(),
            const SizedBox(width: 15),
            Expanded(child: _buildQuantumInputContainer()),
            const SizedBox(width: 15),
            _buildQuantumVoiceButton(),
            const SizedBox(width: 15),
            _buildQuantumSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantumAttachmentButton() {
    return GestureDetector(
      onTap: widget.onAttachment,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.3 + _glowController.value * 0.3),
                  blurRadius: 15 + _glowController.value * 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: GlassmorphicContainer(
              width: 55,
              height: 55,
              borderRadius: 27.5,
              blur: 25,
              alignment: Alignment.center,
              border: 2.5,
              linearGradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4FF).withValues(alpha: 0.4),
                  const Color(0xFF9C27B0).withValues(alpha: 0.4),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.8),
                  Colors.blue.withValues(alpha: 0.4),
                ],
              ),
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.cyanAccent,
                size: 28,
              ),
            ),
          );
        },
      ),
    ).animate().scale(delay: 100.ms, curve: Curves.elasticOut);
  }

  Widget _buildQuantumInputContainer() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.2 + _glowController.value * 0.2),
                blurRadius: 20 + _glowController.value * 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 60,
            borderRadius: 30,
            blur: 25,
            alignment: Alignment.center,
            border: 2.5,
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
            child: Container(
              constraints: const BoxConstraints(minHeight: 55, maxHeight: 140),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      minLines: 1,
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isVoiceMode 
                            ? '🎤 Quantum voice mode active...' 
                            : 'Type your quantum message...',
                        hintStyle: GoogleFonts.rajdhani(
                          color: widget.isDarkMode 
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey[500],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 18,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  _buildQuantumEmojiButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantumEmojiButton() {
    return GestureDetector(
      onTap: _showQuantumEmojiPicker,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.cyanAccent.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: Icon(
          Icons.emoji_emotions_outlined,
          color: Colors.cyanAccent,
          size: 25,
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildQuantumVoiceButton() {
    return GestureDetector(
      onTap: _toggleVoiceMode,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording ? (1.0 + _pulseController.value * 0.15) : 1.0,
            child: AvatarGlow(
              animate: _isRecording,
              glowColor: Colors.redAccent,
              duration: const Duration(milliseconds: 1200),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isRecording ? [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GlassmorphicContainer(
                  width: 55,
                  height: 55,
                  borderRadius: 27.5,
                  blur: 25,
                  alignment: Alignment.center,
                  border: 2.5,
                  linearGradient: LinearGradient(
                    colors: _isRecording
                        ? [
                            Colors.redAccent.withValues(alpha: 0.9),
                            Colors.red.withValues(alpha: 0.8),
                          ]
                        : [
                            const Color(0xFF00D4FF).withValues(alpha: 0.4),
                            const Color(0xFF9C27B0).withValues(alpha: 0.4),
                          ],
                  ),
                  borderGradient: LinearGradient(
                    colors: _isRecording ? [
                      Colors.redAccent.withValues(alpha: 0.8),
                      Colors.red.withValues(alpha: 0.4),
                    ] : [
                      Colors.cyanAccent.withValues(alpha: 0.8),
                      Colors.blue.withValues(alpha: 0.4),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantumSendButton() {
    return ScaleTransition(
      scale: _sendButtonController,
      child: GestureDetector(
        onTap: _handleSend,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.5 + _glowController.value * 0.3),
                    blurRadius: 20 + _glowController.value * 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF00D4FF),
                      Color(0xFF5B73FF),
                      Color(0xFF9C27B0),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ).animate().rotate(begin: -0.2, end: 0, curve: Curves.elasticOut),
    );
  }

  void _handleSend() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend();
    }
  }

  void _showQuantumEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphicContainer(
        width: double.infinity,
        height: 350,
        borderRadius: 30,
        blur: 30,
        alignment: Alignment.center,
        border: 3,
        linearGradient: LinearGradient(
          colors: widget.isDarkMode ? [
            const Color(0xFF0F0C29).withValues(alpha: 0.9),
            const Color(0xFF24243e).withValues(alpha: 0.8),
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
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.cyanAccent,
              highlightColor: Colors.white,
              child: Text(
                'QUANTUM EMOJIS',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 8,
                padding: const EdgeInsets.all(25),
                children: [
                  '⚡', '🚀', '💎', '🌟', '🔥', '💫', '✨', '🎯',
                  '💥', '🌈', '🎨', '🎭', '🎪', '🎊', '🎉', '🎈',
                  '❤️', '💙', '💚', '💛', '🧡', '💜', '🖤', '🤍',
                  '😀', '😂', '🥰', '😍', '🤔', '😎', '🥳', '😴',
                ].map((emoji) => GestureDetector(
                  onTap: () {
                    widget.controller.text += emoji;
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
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
    _glowController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}