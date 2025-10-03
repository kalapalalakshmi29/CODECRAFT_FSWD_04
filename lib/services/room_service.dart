import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_room.dart';
import '../models/user.dart';

class RoomService {
  static const String _roomsKey = 'chat_rooms';
  static const String _currentRoomKey = 'current_room';

  Future<List<ChatRoom>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getString(_roomsKey);
    
    if (roomsJson == null) {
      // Create default public room
      final defaultRoom = ChatRoom(
        id: 'general',
        name: 'General Chat',
        description: 'Welcome to the general chat room!',
        type: RoomType.public,
        participants: [],
        createdAt: DateTime.now(),
      );
      await saveRoom(defaultRoom);
      return [defaultRoom];
    }
    
    final List<dynamic> jsonList = jsonDecode(roomsJson);
    return jsonList.map((json) => ChatRoom.fromJson(json)).toList();
  }

  Future<void> saveRoom(ChatRoom room) async {
    final rooms = await getRooms();
    final existingIndex = rooms.indexWhere((r) => r.id == room.id);
    
    if (existingIndex != -1) {
      rooms[existingIndex] = room;
    } else {
      rooms.add(room);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = rooms.map((r) => r.toJson()).toList();
    await prefs.setString(_roomsKey, jsonEncode(jsonList));
  }

  Future<ChatRoom> createPublicRoom(String name, String description, String createdBy) async {
    final room = ChatRoom(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: RoomType.public,
      participants: [createdBy],
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    
    await saveRoom(room);
    return room;
  }

  Future<ChatRoom> createPrivateRoom(String userId1, String userId2, String user1Name, String user2Name) async {
    // Check if private room already exists
    final rooms = await getRooms();
    final existingRoom = rooms.where((room) => 
      room.isPrivate && 
      room.participants.contains(userId1) && 
      room.participants.contains(userId2)
    ).firstOrNull;
    
    if (existingRoom != null) {
      return existingRoom;
    }
    
    final room = ChatRoom(
      id: const Uuid().v4(),
      name: '$user1Name & $user2Name',
      type: RoomType.private,
      participants: [userId1, userId2],
      createdBy: userId1,
      createdAt: DateTime.now(),
    );
    
    await saveRoom(room);
    return room;
  }

  Future<void> joinRoom(String roomId, String userId) async {
    final rooms = await getRooms();
    final roomIndex = rooms.indexWhere((r) => r.id == roomId);
    
    if (roomIndex != -1) {
      final room = rooms[roomIndex];
      if (!room.participants.contains(userId)) {
        final updatedRoom = room.copyWith(
          participants: [...room.participants, userId],
        );
        await saveRoom(updatedRoom);
      }
    }
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    final rooms = await getRooms();
    final roomIndex = rooms.indexWhere((r) => r.id == roomId);
    
    if (roomIndex != -1) {
      final room = rooms[roomIndex];
      final updatedParticipants = room.participants.where((id) => id != userId).toList();
      
      if (updatedParticipants.isEmpty && room.type == RoomType.public) {
        // Don't delete public rooms, just remove user
        final updatedRoom = room.copyWith(participants: updatedParticipants);
        await saveRoom(updatedRoom);
      } else if (room.type == RoomType.private) {
        // Delete private room if empty
        await deleteRoom(roomId);
      } else {
        final updatedRoom = room.copyWith(participants: updatedParticipants);
        await saveRoom(updatedRoom);
      }
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final rooms = await getRooms();
    rooms.removeWhere((r) => r.id == roomId);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = rooms.map((r) => r.toJson()).toList();
    await prefs.setString(_roomsKey, jsonEncode(jsonList));
  }

  Future<void> updateRoomActivity(String roomId, String lastMessage) async {
    final rooms = await getRooms();
    final roomIndex = rooms.indexWhere((r) => r.id == roomId);
    
    if (roomIndex != -1) {
      final room = rooms[roomIndex];
      final updatedRoom = room.copyWith(
        lastMessage: lastMessage,
        lastActivity: DateTime.now(),
      );
      await saveRoom(updatedRoom);
    }
  }

  Future<ChatRoom?> getCurrentRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString(_currentRoomKey);
    
    if (roomId == null) return null;
    
    final rooms = await getRooms();
    return rooms.where((r) => r.id == roomId).firstOrNull;
  }

  Future<void> setCurrentRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentRoomKey, roomId);
  }

  Future<List<ChatRoom>> getUserRooms(String userId) async {
    final rooms = await getRooms();
    return rooms.where((room) => room.participants.contains(userId)).toList();
  }

  Future<List<ChatRoom>> getPublicRooms() async {
    final rooms = await getRooms();
    return rooms.where((room) => room.type == RoomType.public).toList();
  }
}