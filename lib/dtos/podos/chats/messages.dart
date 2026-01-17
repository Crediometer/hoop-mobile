import 'dart:isolate';

// Isolate communication models
class IsolateMessage {
  final String type;
  final dynamic data;
  final SendPort? replyPort;

  IsolateMessage({required this.type, this.data, this.replyPort});

  Map<String, dynamic> toJson() => {'type': type, 'data': data};
}

// Chat Models (keep as is)
class ChatModel {
  final String id;
  final String title;
  final String? message;
  final String? type;
  final bool read;
  final DateTime createdAt;
  final String? senderName;
  final Map<String, dynamic>? metadata;

  ChatModel({
    required this.id,
    required this.title,
    this.message,
    this.type,
    required this.read,
    required this.createdAt,
    this.senderName,
    this.metadata,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? json['senderName'] ?? 'Unknown',
      message: json['message'] ?? json['content'],
      type: json['type'] ?? json['messageType'],
      read: json['read'] ?? json['status'] == 'read' ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      senderName: json['senderName'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      if (message != null) 'message': message,
      if (message != null) 'content': message,
      if (type != null) 'type': type,
      if (type != null) 'messageType': type,
      'read': read,
      'status': read ? 'read' : 'unread',
      'createdAt': createdAt.toIso8601String(),
      if (senderName != null) 'senderName': senderName,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class Message {
  final String id;
  final num group;
  final String? tempId;
  final dynamic sender;
  final String content;
  final String? message;
  final DateTime? createdAt;
  final String? senderName;
  final String type;
  final String? messageType;
  final String? status;
  final List<dynamic>? attachments;
  final List<dynamic>? reactions;
  final List<dynamic>? readBy;
  final Map<String, dynamic>? pollData;
  final String? paymentStatus;
  final Map<String, dynamic>? systemInfo;
  final Map<String, dynamic>? callData;
  final bool? edited;
  final DateTime? editedAt;
  final bool? deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  Message({
    required this.id,
    required this.group,
    this.tempId,
    required this.sender,
    required this.content,
    this.message,
    this.createdAt,
    this.senderName,
    required this.type,
    this.messageType,
    this.status,
    this.attachments,
    this.reactions,
    this.readBy,
    this.pollData,
    this.paymentStatus,
    this.systemInfo,
    this.callData,
    this.edited,
    this.editedAt,
    this.deleted,
    this.deletedAt,
    this.deletedBy,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      group: json['groupId'] ?? json['group'],
      tempId: json['tempId'],
      sender: json['sender'] ?? json['userId'],
      content: json['content'] ?? json['message'] ?? '',
      message: json['message'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      senderName: json['senderName'] ?? json['userName'],
      type: _mapMessageType(json['type'] ?? json['messageType']),
      messageType: json['messageType'],
      status: json['status'],
      attachments: json['attachments'],
      reactions: json['reactions'],
      readBy: json['readBy'],
      pollData: json['pollData'],
      paymentStatus: json['paymentStatus'],
      systemInfo: json['systemInfo'],
      callData: json['callData'],
      edited: json['edited'],
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      deleted: json['deleted'],
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      deletedBy: json['deletedBy'],
    );
  }

  static String _mapMessageType(String? backendType) {
    const typeMap = {
      'TEXT': 'text',
      'IMAGE': 'image',
      'FILE': 'file',
      'SYSTEM': 'system',
      'CONTRIBUTION': 'contribution',
      'AUDIO': 'audio',
      'VIDEO': 'video',
      'POLL': 'poll',
      'CALL': 'call',
    };
    return typeMap[backendType] ?? 'text';
  }

  static String? _reverseMapMessageType(String? frontendType) {
    const reverseMap = {
      'text': 'TEXT',
      'image': 'IMAGE',
      'file': 'FILE',
      'system': 'SYSTEM',
      'contribution': 'CONTRIBUTION',
      'audio': 'AUDIO',
      'video': 'VIDEO',
      'poll': 'POLL',
      'call': 'CALL',
    };
    return reverseMap[frontendType];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'groupId': group,
      'group': group,
      if (tempId != null) 'tempId': tempId,
      'sender': sender,
      'userId': sender,
      'content': content,
      'message': content,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      if (senderName != null) 'senderName': senderName,
      if (senderName != null) 'userName': senderName,
      'type': type,
      'messageType': _reverseMapMessageType(type) ?? type.toUpperCase(),
      if (status != null) 'status': status,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments,
      if (reactions != null && reactions!.isNotEmpty) 'reactions': reactions,
      if (readBy != null && readBy!.isNotEmpty) 'readBy': readBy,
      if (pollData != null) 'pollData': pollData,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (systemInfo != null) 'systemInfo': systemInfo,
      if (callData != null) 'callData': callData,
      if (edited != null) 'edited': edited,
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      if (deleted != null) 'deleted': deleted,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (deletedBy != null) 'deletedBy': deletedBy,
    };
  }

  Message copyWith({
    String? id,
    dynamic group,
    String? tempId,
    dynamic sender,
    String? content,
    String? message,
    DateTime? createdAt,
    String? senderName,
    String? type,
    String? messageType,
    String? status,
    List<dynamic>? attachments,
    List<dynamic>? reactions,
    List<dynamic>? readBy,
    Map<String, dynamic>? pollData,
    String? paymentStatus,
    Map<String, dynamic>? systemInfo,
    Map<String, dynamic>? callData,
    bool? edited,
    DateTime? editedAt,
    bool? deleted,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return Message(
      id: id ?? this.id,
      group: group ?? this.group,
      tempId: tempId ?? this.tempId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      pollData: pollData ?? this.pollData,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      systemInfo: systemInfo ?? this.systemInfo,
      callData: callData ?? this.callData,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  bool isFromUser(String userId) {
    return sender.toString() == userId;
  }

  bool isReadByUser(String userId) {
    if (readBy == null) return false;
    for (final read in readBy!) {
      if (read is Map) {
        if (read['userId']?.toString() == userId ||
            read['user']?.toString() == userId) {
          return true;
        }
      } else if (read.toString() == userId) {
        return true;
      }
    }
    return false;
  }

  Message markAsReadByUser(String userId, String userName) {
    final List<dynamic> updatedReadBy = List.from(readBy ?? []);
    final alreadyRead = updatedReadBy.any((read) {
      if (read is Map) {
        return read['userId']?.toString() == userId ||
            read['user']?.toString() == userId;
      }
      return read.toString() == userId;
    });

    if (!alreadyRead) {
      updatedReadBy.add({
        'userId': int.tryParse(userId) ?? userId,
        'user': int.tryParse(userId) ?? userId,
        'userName': userName,
        'readAt': DateTime.now().toIso8601String(),
      });
    }

    return copyWith(status: 'read', readBy: updatedReadBy);
  }

  Message addReaction(String emoji, String userId, String userName) {
    final List<dynamic> updatedReactions = List.from(reactions ?? []);
    final reactionIndex = updatedReactions.indexWhere(
      (r) => r is Map && r['emoji'] == emoji,
    );

    if (reactionIndex != -1) {
      final reaction = Map<String, dynamic>.from(
        updatedReactions[reactionIndex],
      );
      final users = List<Map<String, dynamic>>.from(reaction['users'] ?? []);

      final alreadyReacted = users.any(
        (u) => u['userId']?.toString() == userId,
      );
      if (!alreadyReacted) {
        users.add({
          'userId': int.tryParse(userId) ?? userId,
          'userName': userName,
          'reactedAt': DateTime.now().toIso8601String(),
        });
        reaction['users'] = users;
        reaction['count'] = users.length;
        updatedReactions[reactionIndex] = reaction;
      }
    } else {
      updatedReactions.add({
        'emoji': emoji,
        'users': [
          {
            'userId': int.tryParse(userId) ?? userId,
            'userName': userName,
            'reactedAt': DateTime.now().toIso8601String(),
          },
        ],
        'count': 1,
      });
    }

    return copyWith(reactions: updatedReactions);
  }

  Message removeReaction(String emoji, String userId) {
    final List<dynamic> updatedReactions = List.from(reactions ?? []);
    final reactionIndex = updatedReactions.indexWhere(
      (r) => r is Map && r['emoji'] == emoji,
    );

    if (reactionIndex != -1) {
      final reaction = Map<String, dynamic>.from(
        updatedReactions[reactionIndex],
      );
      final users = List<Map<String, dynamic>>.from(reaction['users'] ?? []);
      users.removeWhere((u) => u['userId']?.toString() == userId);

      if (users.isEmpty) {
        updatedReactions.removeAt(reactionIndex);
      } else {
        reaction['users'] = users;
        reaction['count'] = users.length;
        updatedReactions[reactionIndex] = reaction;
      }
    }

    return copyWith(reactions: updatedReactions);
  }
}

class SendMessageParams {
  final int groupId;
  final String message;
  final String messageType;
  final String? tempId;
  final List<Map<String, dynamic>>? attachments;
  final Map<String, dynamic>? replyTo;
  final Map<String, dynamic>? metadata;

  SendMessageParams({
    required this.groupId,
    required this.message,
    required this.messageType,
    this.tempId,
    this.attachments,
    this.replyTo,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'message': message,
      'messageType': messageType,
      'tempId': tempId,
      'attachments': attachments,
      'metadata': metadata,
      if (replyTo != null && replyTo!['messageId'] != null)
        'replyTo': replyTo!['messageId'],
    };
  }
}

class TypingUser {
  final String userId;
  final String userName;
  final DateTime? startedAt;

  TypingUser({required this.userId, required this.userName, this.startedAt});

  factory TypingUser.fromJson(Map<String, dynamic> json) {
    return TypingUser(
      userId: json['userId'].toString(),
      userName: json['userName'] ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'startedAt': startedAt?.toIso8601String(),
    };
  }
}

class TypingIndicator {
  final num groupId;
  final List<TypingUser> typingUsers;

  TypingIndicator({required this.groupId, required this.typingUsers});

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      groupId: json['groupId'],
      typingUsers:
          (json['typingUsers'] as List?)
              ?.map((u) => TypingUser.fromJson(u))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'typingUsers': typingUsers.map((u) => u.toJson()).toList(),
    };
  }
}

class MessagesResponse {
  final List<MessageGroup> groups;

  MessagesResponse({required this.groups});

  factory MessagesResponse.fromJson(List<dynamic> json) {
    return MessagesResponse(
      groups:
          (json as List?)?.map((g) => MessageGroup.fromJson(g)).toList() ?? [],
    );
  }
}

class MessageGroup {
  final num groupId;
  final List<Message> messages;

  MessageGroup({required this.groupId, required this.messages});

  factory MessageGroup.fromJson(Map<String, dynamic> json) {
    return MessageGroup(
      groupId: json['groupId'] ?? json['group'],
      messages:
          (json['messages'] as List?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}

