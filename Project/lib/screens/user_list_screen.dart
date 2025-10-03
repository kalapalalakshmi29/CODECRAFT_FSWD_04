import 'package:flutter/material.dart';
import '../models/user.dart';

class UserListScreen extends StatelessWidget {
  final List<User> users;

  const UserListScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Online Users (${users.length})'),
      ),
      body: users.isEmpty
          ? const Center(
              child: Text(
                'No users online',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.isOnline ? Colors.green : Colors.grey,
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      user.presenceText,
                      style: TextStyle(
                        color: user.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: user.isOnline
                        ? const Icon(
                            Icons.circle,
                            color: Colors.green,
                            size: 12,
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}