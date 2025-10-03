class User {
  final String id;
  final String username;
  final bool isOnline;
  final String? avatar;
  final String? status;
  final DateTime? lastSeen;
  final bool isTyping;

  User({
    required this.id,
    required this.username,
    this.isOnline = false,
    this.avatar,
    this.status,
    this.lastSeen,
    this.isTyping = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'isOnline': isOnline,
    'avatar': avatar,
    'status': status,
    'lastSeen': lastSeen?.toIso8601String(),
    'isTyping': isTyping,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    username: json['username'],
    isOnline: json['isOnline'] ?? false,
    avatar: json['avatar'],
    status: json['status'],
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    isTyping: json['isTyping'] ?? false,
  );

  String get presenceText {
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      final diff = DateTime.now().difference(lastSeen!);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return 'Offline';
  }

  User copyWith({
    String? id,
    String? username,
    bool? isOnline,
    String? avatar,
    String? status,
    DateTime? lastSeen,
    bool? isTyping,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      isOnline: isOnline ?? this.isOnline,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}