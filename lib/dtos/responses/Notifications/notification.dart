// lib/models/notification.dart
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
   bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String? senderId;
  final String? groupId;
  final String? actionUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.data,
    this.senderId,
    this.groupId,
    this.actionUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseNotificationType(json['type']),
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      data: json['data'] != null 
          ? Map<String, dynamic>.from(json['data'])
          : null,
      senderId: json['senderId'],
      groupId: json['groupId'],
      actionUrl: json['actionUrl'],
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'system': return NotificationType.system;
      case 'group': return NotificationType.group;
      case 'message': return NotificationType.message;
      case 'transaction': return NotificationType.transaction;
      case 'reminder': return NotificationType.reminder;
      default: return NotificationType.system;
    }
  }
}

enum NotificationType {
  system,
  group,
  message,
  transaction,
  reminder,
}

// lib/models/chat.dart
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final List<String>? readBy;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
    this.replyToId,
    this.readBy,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      content: json['content'] ?? '',
      type: _parseMessageType(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      replyToId: json['replyToId'],
      readBy: (json['readBy'] as List<dynamic>?)?.cast<String>(),
    );
  }

  static MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'text': return MessageType.text;
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'audio': return MessageType.audio;
      case 'file': return MessageType.file;
      case 'system': return MessageType.system;
      default: return MessageType.text;
    }
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  system,
}

// lib/models/chat_room.dart
class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final ChatRoomType type;
  final List<String> participants;
  final DateTime createdAt;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.metadata,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      type: _parseChatRoomType(json['type']),
      participants: (json['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  static ChatRoomType _parseChatRoomType(String type) {
    switch (type.toLowerCase()) {
      case 'direct': return ChatRoomType.direct;
      case 'group': return ChatRoomType.group;
      case 'channel': return ChatRoomType.channel;
      default: return ChatRoomType.direct;
    }
  }
}

enum ChatRoomType {
  direct,
  group,
  channel,
}