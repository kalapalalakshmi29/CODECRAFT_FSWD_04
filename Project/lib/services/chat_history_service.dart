import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatHistoryService {
  static const String _historyKey = 'chat_history';
  static const String _lastSeenKey = 'last_seen_message';
  
  Future<void> saveMessage(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.add(message);
    
    // Keep only last 1000 messages
    if (history.length > 1000) {
      history.removeRange(0, history.length - 1000);
    }
    
    final jsonList = history.map((m) => m.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<List<Message>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    
    if (historyJson == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(historyJson);
    return jsonList.map((json) => Message.fromJson(json)).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
  
  Future<void> deleteMessage(String messageId) async {
    final messages = await getHistory();
    messages.removeWhere((msg) => msg.id == messageId);
    await _saveHistory(messages);
  }
  
  Future<void> deleteChat(String roomId) async {
    final messages = await getHistory();
    messages.removeWhere((msg) => msg.roomId == roomId);
    await _saveHistory(messages);
  }
  
  Future<List<String>> getChatRooms() async {
    final messages = await getHistory();
    return messages.map((msg) => msg.roomId).toSet().toList();
  }
  
  Future<void> _saveHistory(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((msg) => {
      'id': msg.id,
      'senderId': msg.senderId,
      'senderName': msg.senderName,
      'content': msg.content,
      'roomId': msg.roomId,
      'timestamp': msg.timestamp.toIso8601String(),
      'type': msg.type.toString(),
      'fileName': msg.fileName,
      'isRead': msg.isRead,
    }).toList();
    await prefs.setString(_historyKey, json.encode(jsonList));
  }

  Future<void> markMessageAsSeen(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenKey, messageId);
  }

  Future<String?> getLastSeenMessageId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenKey);
  }

  Future<int> getUnreadCount() async {
    final history = await getHistory();
    final lastSeenId = await getLastSeenMessageId();
    
    if (lastSeenId == null) return history.length;
    
    final lastSeenIndex = history.indexWhere((m) => m.id == lastSeenId);
    if (lastSeenIndex == -1) return history.length;
    
    return history.length - lastSeenIndex - 1;
  }

  Future<List<Message>> searchMessages(String query) async {
    final history = await getHistory();
    return history.where((message) => 
      message.content.toLowerCase().contains(query.toLowerCase()) ||
      message.senderName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}