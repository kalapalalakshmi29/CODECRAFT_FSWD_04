import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import 'dart:convert';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _usersKey = 'registered_users';
  
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final username = prefs.getString(_usernameKey);
    
    if (userId != null && username != null) {
      return User(id: userId, username: username);
    }
    return null;
  }

  Future<bool> createAccount(String username, String password, String email) async {
    if (username.trim().isEmpty || password.trim().isEmpty) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    if (users.containsKey(username)) return false;
    
    users[username] = {
      'password': password,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_usersKey, json.encode(users));
    return true;
  }

  Future<User?> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    if (!users.containsKey(username) || users[username]['password'] != password) {
      return null;
    }
    
    final userId = const Uuid().v4();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    
    return User(id: userId, username: username);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }
}