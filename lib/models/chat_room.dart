enum RoomType { public, private }

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final RoomType type;
  final List<String> participants;
  final String? createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastActivity;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastActivity,
    this.unreadCount = 0,
  });

  bool get isPrivate => type == RoomType.private;
  
  String getDisplayName(String currentUserId) {
    if (isPrivate && participants.length == 2) {
      return participants.firstWhere((id) => id != currentUserId);
    }
    return name;
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    RoomType? type,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'participants': participants,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'lastMessage': lastMessage,
    'lastActivity': lastActivity?.toIso8601String(),
    'unreadCount': unreadCount,
  };

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    type: RoomType.values.firstWhere((e) => e.name == json['type']),
    participants: List<String>.from(json['participants']),
    createdBy: json['createdBy'],
    createdAt: DateTime.parse(json['createdAt']),
    lastMessage: json['lastMessage'],
    lastActivity: json['lastActivity'] != null ? DateTime.parse(json['lastActivity']) : null,
    unreadCount: json['unreadCount'] ?? 0,
  );
}