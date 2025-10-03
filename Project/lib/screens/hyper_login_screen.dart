import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'advanced_main_screen.dart';

class HyperLoginScreen extends StatefulWidget {
  const HyperLoginScreen({super.key});

  @override
  State<HyperLoginScreen> createState() => _HyperLoginScreenState();
}

class _HyperLoginScreenState extends State<HyperLoginScreen> {
  final _controller = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final user = await _authService.login(_controller.text.trim());
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdvancedMainScreen(user: user)),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF24243e),
              Color(0xFF302B63),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildTitle(),
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 60),
                _buildInput(),
                const SizedBox(height: 30),
                _buildButton(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00D4FF),
            Color(0xFF5B73FF),
            Color(0xFF9C27B0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_bubble_outline,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'HYPER CHAT',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 3,
        shadows: [
          Shadow(
            color: Colors.cyanAccent,
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Real-time messaging experience',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white70,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.cyanAccent.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: const InputDecoration(
          hintText: 'Enter your username',
          hintStyle: TextStyle(
            color: Colors.white60,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Icon(
            Icons.person_outline,
            color: Colors.cyanAccent,
          ),
        ),
        onSubmitted: (_) => _login(),
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00D4FF),
                Color(0xFF5B73FF),
                Color(0xFF9C27B0),
              ],
            ),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'START CHATTING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}