import 'package:flutter/material.dart';
import '../models/user.dart';

class PresenceIndicator extends StatelessWidget {
  final User user;
  final double size;

  const PresenceIndicator({
    super.key,
    required this.user,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getPresenceColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Color _getPresenceColor() {
    if (user.isOnline) return Colors.green;
    if (user.lastSeen != null) {
      final diff = DateTime.now().difference(user.lastSeen!);
      if (diff.inMinutes < 5) return Colors.orange;
    }
    return Colors.grey;
  }
}

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.blue,
          child: Text(
            user.username[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: PresenceIndicator(
            user: user,
            size: radius * 0.6,
          ),
        ),
      ],
    );
  }
}