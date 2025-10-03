enum MessageType { text, image, file, emoji }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String roomId;
  final DateTime timestamp;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final bool isRead;
  final String? replyToId;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.roomId,
    required this.timestamp,
    this.type = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.isRead = false,
    this.replyToId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'roomId': roomId,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'fileUrl': fileUrl,
    'fileName': fileName,
    'isRead': isRead,
    'replyToId': replyToId,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    senderId: json['senderId'],
    senderName: json['senderName'],
    content: json['content'],
    roomId: json['roomId'],
    timestamp: DateTime.parse(json['timestamp']),
    type: MessageType.values.firstWhere((e) => e.name == json['type'], orElse: () => MessageType.text),
    fileUrl: json['fileUrl'],
    fileName: json['fileName'],
    isRead: json['isRead'] ?? false,
    replyToId: json['replyToId'],
  );
}