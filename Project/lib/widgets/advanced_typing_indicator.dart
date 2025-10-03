import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class AdvancedTypingIndicator extends StatelessWidget {
  final String username;

  const AdvancedTypingIndicator({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Text(
                username[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[400]!,
                    highlightColor: Colors.grey[200]!,
                    child: Text(
                      '$username is typing',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    height: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAnimatedDot(0),
                        _buildAnimatedDot(200),
                        _buildAnimatedDot(400),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3);
  }

  Widget _buildAnimatedDot(int delay) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.3, 1.3),
          duration: 600.ms,
        )
        .then(delay: Duration(milliseconds: delay))
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(0.5, 0.5),
          duration: 600.ms,
        );
  }
}