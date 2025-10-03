import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../services/auth_service.dart';
import 'ultra_chat_screen.dart';

class UltraLoginScreen extends StatefulWidget {
  const UltraLoginScreen({super.key});

  @override
  State<UltraLoginScreen> createState() => _UltraLoginScreenState();
}

class _UltraLoginScreenState extends State<UltraLoginScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _particleController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _particleController.repeat();
    _glowController.repeat(reverse: true);
  }

  void _login() async {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final user = await _authService.login(_controller.text.trim());
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => UltraChatScreen(user: user),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
    
    setState(() => _isLoading = false);
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
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFF667eea).withValues(alpha: 0.8),
              const Color(0xFF764ba2).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedLogo(),
                    const SizedBox(height: 32),
                    _buildAnimatedTitle(),
                    const SizedBox(height: 16),
                    _buildAnimatedSubtitle(),
                    const SizedBox(height: 64),
                    _buildGlassmorphicInput(),
                    const SizedBox(height: 32),
                    _buildAnimatedButton(),
                    const SizedBox(height: 32),
                    _buildFeaturesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AvatarGlow(
      animate: true,
      glowColor: Colors.white,
      duration: const Duration(milliseconds: 2000),
      repeat: true,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.1)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 80,
          color: Colors.white,
        ),
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).fadeIn();
  }

  Widget _buildAnimatedTitle() {
    return AnimatedTextKit(
      animatedTexts: [
        TypewriterAnimatedText(
          'Ultra Chat',
          textStyle: GoogleFonts.orbitron(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          speed: const Duration(milliseconds: 100),
        ),
      ],
      totalRepeatCount: 1,
    );
  }

  Widget _buildAnimatedSubtitle() {
    return AnimatedTextKit(
      animatedTexts: [
        FadeAnimatedText(
          'Experience the future of messaging',
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w300,
          ),
          duration: const Duration(milliseconds: 2000),
        ),
        FadeAnimatedText(
          'Connect • Share • Inspire',
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w300,
          ),
          duration: const Duration(milliseconds: 2000),
        ),
      ],
      repeatForever: true,
    );
  }

  Widget _buildGlassmorphicInput() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 70,
      borderRadius: 25,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.2),
        ],
      ),
      child: TextField(
        controller: _controller,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your cosmic username...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: 24,
          ),
        ),
        onSubmitted: (_) => _login(),
      ),
    ).animate().slideY(begin: 0.5, duration: 1000.ms, curve: Curves.elasticOut).fadeIn();
  }

  Widget _buildAnimatedButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _isLoading ? null : _login,
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(const Color(0xFF667eea)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: const Color(0xFF667eea),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Launch Into Chat',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.5, duration: 1200.ms, curve: Curves.elasticOut).fadeIn();
  }

  Widget _buildFeaturesList() {
    final features = [
      '🚀 Real-time messaging',
      '✨ Advanced animations',
      '🎨 Glassmorphic design',
      '🌟 Premium experience',
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            entry.value,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ).animate(delay: Duration(milliseconds: 1500 + (entry.key * 200)))
            .slideX(begin: -0.5)
            .fadeIn();
      }).toList(),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = (size.width * (i * 0.1 + animationValue)) % size.width;
      final y = (size.height * (i * 0.07 + animationValue * 0.5)) % size.height;
      final radius = (i % 3 + 1) * 2.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}