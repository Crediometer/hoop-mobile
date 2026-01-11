// lib/providers/chat_websocket_handler.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/main.dart';
import 'package:hoop/screens/calls/call_screen.dart';
import 'package:hoop/services/audio/SynthNotificationAudio.dart';
import 'package:hoop/services/callkit_integration.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:vibration/vibration.dart';

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
}

// Isolate Worker Class
class ChatIsolateWorker {
  final SendPort _sendPort;
  final Map<num, List<Message>> _messages = {};
  final Map<num, List<TypingUser>> _typingData = {};
  final Map<num, Set<String>> _unreadMessages = {};
  final Map<num, Set<num>> _onlineUsersByGroup = {};
  final Set<num> _onlineUsers = {};

  ChatIsolateWorker(this._sendPort);

  void handleMessage(IsolateMessage message) {
    switch (message.type) {
      case 'process_message_batch':
        _processMessageBatch(message.data);
        break;
      case 'process_typing_data':
        _processTypingData(message.data);
        break;
      case 'process_presence_data':
        _processPresenceData(message.data);
        break;
      case 'parse_messages_json':
        _parseMessagesJson(message.data);
        break;
      case 'process_call_data':
        _processCallData(message.data);
        break;
      case 'get_messages':
        _getMessages(message.data);
        break;
      case 'mark_messages_read':
        _markMessagesRead(message.data);
        break;
      case 'add_reaction':
        _addReaction(message.data);
        break;
      case 'update_message':
        _updateMessage(message.data);
        break;
      case 'shutdown':
        _shutdown();
        break;
    }
  }

  void _processMessageBatch(List<dynamic> messages) {
    final processed = <Map<String, dynamic>>[];

    for (final messageData in messages) {
      try {
        final message = Message.fromJson(messageData);
        final groupId = message.group;

        // Add to local storage
        _messages.putIfAbsent(groupId, () => []);
        final exists = _messages[groupId]!.any((m) => m.id == message.id);
        if (!exists) {
          _messages[groupId]!.add(message);
          _messages[groupId]!.sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );
        }

        processed.add(message.toJson());
      } catch (e) {
        debugPrint('❌ Error processing message in isolate: $e');
      }
    }

    _sendPort.send(IsolateMessage(type: 'messages_processed', data: processed));
  }

  void _processTypingData(Map<String, dynamic> data) {
    try {
      final indicator = TypingIndicator.fromJson(data);
      final currentTypingUsers = _typingData[indicator.groupId] ?? [];

      // Update typing data
      _typingData[indicator.groupId] = indicator.typingUsers;

      _sendPort.send(
        IsolateMessage(
          type: 'typing_processed',
          data: {
            'groupId': indicator.groupId,
            'typingUsers': indicator.typingUsers
                .map(
                  (u) => {
                    'userId': u.userId,
                    'userName': u.userName,
                    'startedAt': u.startedAt?.toIso8601String(),
                  },
                )
                .toList(),
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error processing typing data in isolate: $e');
    }
  }

  void _processPresenceData(Map<String, dynamic> data) {
    try {
      final groupId = data['groupId'];
      final users =
          (data['users'] as List<dynamic>?)
              ?.map((u) => int.parse(u.toString()))
              .toSet() ??
          <num>{};

      if (groupId != null) {
        _onlineUsersByGroup[groupId] = users;
      }

      _onlineUsers.clear();
      _onlineUsers.addAll(users);

      _sendPort.send(
        IsolateMessage(
          type: 'presence_processed',
          data: {
            'groupId': groupId,
            'users': users.toList(),
            'count': users.length,
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error processing presence data in isolate: $e');
    }
  }

  void _parseMessagesJson(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      final messages = List<Map<String, dynamic>>.from(
        parsed['messages'] ?? [],
      );
      final processed = messages
          .map((m) => Message.fromJson(m).toJson())
          .toList();

      _sendPort.send(IsolateMessage(type: 'messages_parsed', data: processed));
    } catch (e) {
      debugPrint('❌ Error parsing messages JSON in isolate: $e');
    }
  }

  void _processCallData(Map<String, dynamic> data) {
    try {
      final callData = CallData.fromJson(data);

      _sendPort.send(
        IsolateMessage(type: 'call_processed', data: callData.toJson()),
      );
    } catch (e) {
      debugPrint('❌ Error processing call data in isolate: $e');
    }
  }

  void _getMessages(Map<String, dynamic> params) {
    final groupId = params['groupId'];
    final page = params['page'] ?? 1;
    final limit = params['limit'] ?? 50;

    final messages = _messages[groupId] ?? [];
    final start = (page - 1) * limit;
    final end = start + limit;
    final paginated = messages.sublist(
      start.clamp(0, messages.length),
      end.clamp(0, messages.length),
    );

    _sendPort.send(
      IsolateMessage(
        type: 'messages_retrieved',
        data: {
          'groupId': groupId,
          'messages': paginated.map((m) => m.toJson()).toList(),
          'page': page,
          'total': messages.length,
        },
      ),
    );
  }

  void _markMessagesRead(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);
    final userId = data['userId'];
    final userName = data['userName'];

    if (groupId != null && userId != null) {
      final messages = _messages[groupId] ?? [];

      for (final message in messages) {
        if (messageIds.contains(message.id)) {
          final index = messages.indexOf(message);
          if (index != -1) {
            messages[index] = message.markAsReadByUser(userId, userName);
          }
        }
      }

      // Remove from unread
      _unreadMessages[groupId]?.removeAll(messageIds);
      if (_unreadMessages[groupId]?.isEmpty ?? false) {
        _unreadMessages.remove(groupId);
      }
    }

    _sendPort.send(
      IsolateMessage(
        type: 'messages_marked_read',
        data: {'groupId': groupId, 'messageIds': messageIds},
      ),
    );
  }

  void _addReaction(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final messageId = data['messageId'];
    final emoji = data['emoji'];
    final userId = data['userId'];
    final userName = data['userName'];

    if (groupId != null &&
        messageId != null &&
        emoji != null &&
        userId != null) {
      final messages = _messages[groupId] ?? [];
      final messageIndex = messages.indexWhere((m) => m.id == messageId);

      if (messageIndex != -1) {
        final message = messages[messageIndex];
        final updatedMessage = message.addReaction(emoji, userId, userName);
        messages[messageIndex] = updatedMessage;

        _sendPort.send(
          IsolateMessage(type: 'reaction_added', data: updatedMessage.toJson()),
        );
      }
    }
  }

  void _updateMessage(Map<String, dynamic> data) {
    final message = Message.fromJson(data);
    final groupId = message.group;

    final messages = _messages[groupId] ?? [];
    final messageIndex = messages.indexWhere((m) => m.id == message.id);

    if (messageIndex != -1) {
      messages[messageIndex] = message;

      _sendPort.send(
        IsolateMessage(type: 'message_updated', data: message.toJson()),
      );
    }
  }

  void _shutdown() {
    _messages.clear();
    _typingData.clear();
    _unreadMessages.clear();
    _onlineUsers.clear();
    _onlineUsersByGroup.clear();
  }
}

class ChatWebSocketHandler with ChangeNotifier {
  final BaseWebSocketService socketService = BaseWebSocketService(
    namespace: '/group-chat',
  );
  final TokenManager tokenManager = TokenManager.instance;

  static ChatWebSocketHandler? _instance;
  ChatWebSocketHandler get instance {
    if (_instance == null) {
      _initialize();
      _instance = ChatWebSocketHandler();
    }
    return _instance!;
  }

  // Isolate Management
  Isolate? _isolate;
  ReceivePort? _isolateReceivePort;
  SendPort? _isolateSendPort;
  bool _isolateInitialized = false;
  final Map<String, Completer<dynamic>> _isolateCompleters = {};
  int _isolateRequestId = 0;

  // UI State (lightweight)
  final ValueNotifier<List<MessageGroup>> _messages = ValueNotifier([]);
  final Map<num, List<TypingUser>> _typingDataUI = {};
  final Map<num, Set<String>> _unreadMessagesUI = {};
  final Set<num> _onlineUsersUI = {};
  final Map<num, Set<num>> _onlineUsersByGroupUI = {};

  // Batch processing
  final List<Map<String, dynamic>> _messageBatch = [];
  Timer? _batchTimer;
  final Duration _batchDelay = const Duration(milliseconds: 100);
  final int _batchSize = 50;

  late CallKitIntegration callKitIntegration;
  late WebRTCManager _webrtcManager;
  num? _currentGroupId;
  int _reconnectAttempts = 0;
  String? _lastReadMessageId;

  bool _isConnected = false;
  bool _isAuthenticated = false;
  String _connectionStatus = 'disconnected';

  bool _isTyping = false;
  final Set<String> _typingUsers = {};
  final Map<String, Set<String>> _typingUsersByGroup = {};

  Timer? _reconnectTimer;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 1);

  final Map<String, List<Function(dynamic)>> _eventHandlers = {};
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;

  final audio = SynthNotificationAudio();
  AudioSession? _audioSession;
  bool _isRinging = false;

  String? _userId;
  String? _userName;

  Timer? _tokenCheckTimer;
  String? _currentToken;
  bool _tokenMonitoringStarted = false;
  final Duration _tokenCheckInterval = const Duration(seconds: 2);
  WebRTCManager get webrtcManager => _webrtcManager;

  // Getters
  ValueNotifier<List<MessageGroup>> get messages => _messages;
  num? get currentGroupId => _currentGroupId;
  int get reconnectAttempts => _reconnectAttempts;

  ValueNotifier<Map<num, List<TypingUser>>> get typingData =>
      ValueNotifier(Map.unmodifiable(_typingDataUI));

  ValueNotifier<Map<num, Set<String>>> get unreadMessages =>
      ValueNotifier(Map.unmodifiable(_unreadMessagesUI));

  String? get lastReadMessageId => _lastReadMessageId;
  Set<num> get onlineUsers => Set.unmodifiable(_onlineUsersUI);
  Map<num, Set<num>> get onlineUsersByGroup =>
      Map.unmodifiable(_onlineUsersByGroupUI);

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  String get connectionStatus => _connectionStatus;

  int get totalUnreadMessages {
    int total = 0;
    for (final set in _unreadMessagesUI.values) {
      total += set.length;
    }
    return total;
  }

  bool get isTyping => _isTyping;
  Set<String> get typingUsers => Set.unmodifiable(_typingUsers);
  Map<String, Set<String>> get typingUsersByGroup =>
      Map.unmodifiable(_typingUsersByGroup);

  bool get isCallingEnabled => true;

  // Isolate Initialization
  Future<void> _initializeIsolate() async {
    if (_isolateInitialized) return;

    _isolateReceivePort = ReceivePort();

    try {
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _isolateReceivePort!.sendPort,
        debugName: 'ChatWebSocketIsolate',
        errorsAreFatal: true,
      );

      _isolateReceivePort!.listen(_handleIsolateMessage);
      _isolateInitialized = true;
      debugPrint('✅ Chat isolate initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize chat isolate: $e');
      _isolateReceivePort?.close();
      _isolateInitialized = false;
    }
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    final worker = ChatIsolateWorker(sendPort);

    receivePort.listen((message) {
      if (message is IsolateMessage) {
        worker.handleMessage(message);
      }
    });
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
      _sendToIsolate(IsolateMessage(type: 'initialize'));
      return;
    }

    if (message is IsolateMessage) {
      switch (message.type) {
        case 'messages_processed':
          _updateMessagesFromIsolate(message.data);
          break;
        case 'typing_processed':
          _updateTypingFromIsolate(message.data);
          break;
        case 'presence_processed':
          _updatePresenceFromIsolate(message.data);
          break;
        case 'messages_parsed':
          _updateMessagesFromIsolate(message.data);
          break;
        case 'call_processed':
          _handleCallFromIsolate(message.data);
          break;
        case 'messages_retrieved':
          _updateMessagesFromIsolate(message.data['messages']);
          break;
        case 'messages_marked_read':
          _updateUnreadFromIsolate(message.data);
          break;
        case 'reaction_added':
          _updateMessageFromIsolate(message.data);
          break;
        case 'message_updated':
          _updateMessageFromIsolate(message.data);
          break;
      }

      // Complete any pending completers
      if (message.replyPort != null) {
        final completerKey = '${message.type}_${message.replyPort!.hashCode}';
        if (_isolateCompleters.containsKey(completerKey)) {
          _isolateCompleters[completerKey]!.complete(message.data);
          _isolateCompleters.remove(completerKey);
        }
      }
    }
  }

  Future<dynamic> _sendToIsolate(
    IsolateMessage message, {
    bool waitForResponse = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isolateInitialized || _isolateSendPort == null) {
      await _initializeIsolate();
      if (_isolateSendPort == null) {
        throw Exception('Isolate not ready');
      }
    }

    if (!waitForResponse) {
      _isolateSendPort!.send(message);
      return null;
    }

    final completer = Completer<dynamic>();
    final requestId = _isolateRequestId++;
    final completerKey = '${message.type}_$requestId';

    _isolateCompleters[completerKey] = completer;

    // Setup timeout
    Timer(timeout, () {
      if (_isolateCompleters.containsKey(completerKey) &&
          !completer.isCompleted) {
        completer.completeError(TimeoutException('Isolate response timeout'));
        _isolateCompleters.remove(completerKey);
      }
    });

    _isolateSendPort!.send(
      IsolateMessage(
        type: message.type,
        data: message.data,
        replyPort: _isolateReceivePort!.sendPort,
      ),
    );

    return completer.future;
  }

  // UI Update Methods from Isolate
  void _updateMessagesFromIsolate(List<dynamic> messagesData) {
    if (messagesData.isEmpty) return;

    // Process in chunks for UI responsiveness
    final chunkSize = 10;
    final total = messagesData.length;
    int processed = 0;

    void processChunk() {
      final end = processed + chunkSize;
      final chunk = messagesData.sublist(processed, end > total ? total : end);

      for (final messageData in chunk) {
        try {
          final message = Message.fromJson(messageData);
          _addMessageToGroupUI(message.group, message);
        } catch (e) {
          debugPrint('❌ Error updating message from isolate: $e');
        }
      }

      processed = end;

      if (processed < total) {
        Future.microtask(() => processChunk());
      } else {
        _notifyListeners();
      }
    }

    processChunk();
  }

  void _updateTypingFromIsolate(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final typingUsers = List<dynamic>.from(
      data['typingUsers'] ?? [],
    ).map((u) => TypingUser.fromJson(u)).toList();

    _typingDataUI[groupId] = typingUsers;
    _notifyListeners();
    _emitEvent('typing_update', data);
  }

  void _updatePresenceFromIsolate(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final users = List<num>.from(data['users'] ?? []);

    if (groupId != null) {
      _onlineUsersByGroupUI[groupId] = users.toSet();
    }

    _onlineUsersUI.clear();
    _onlineUsersUI.addAll(users);

    _notifyListeners();
    _emitEvent('presence_update', data);
  }

  void _handleCallFromIsolate(Map<String, dynamic> data) {
    try {
      final callData = CallData.fromJson(data);
      webrtcManager.setIncomingCall(callData);
      _emitEvent('call_processed', data);
    } catch (e) {
      debugPrint('❌ Error handling call from isolate: $e');
    }
  }

  void _updateUnreadFromIsolate(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);

    if (groupId != null) {
      _unreadMessagesUI[groupId]?.removeAll(messageIds);
      if (_unreadMessagesUI[groupId]?.isEmpty ?? false) {
        _unreadMessagesUI.remove(groupId);
      }
    }

    _notifyListeners();
  }

  void _updateMessageFromIsolate(Map<String, dynamic> messageData) {
    try {
      final message = Message.fromJson(messageData);
      final groupId = message.group;

      final groupIndex = _messages.value.indexWhere(
        (g) => g.groupId == groupId,
      );
      if (groupIndex != -1) {
        final messageIndex = _messages.value[groupIndex].messages.indexWhere(
          (m) => m.id == message.id,
        );

        if (messageIndex != -1) {
          _messages.value[groupIndex].messages[messageIndex] = message;
          _notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating single message from isolate: $e');
    }
  }

  // Main Initialization
  Future<void> _initialize() async {
    await _initializeIsolate();

    _userId = await _getUserIdFromTokenManager();
    _userName = await _getUserName();

    socketService.onConnected(_handleConnected);
    socketService.onDisconnected(_handleDisconnected);
    socketService.onError(_handleError);
    socketService.onConnecting(_handleConnecting);
    socketService.onReconnectAttempt(_handleReconnectAttempt);

    _setupChatHandlers();
    _startTokenMonitoring();
    await _checkAndConnect();
    _initializeWebRTCManager();
  }

  void _initializeWebRTCManager() async {
    try {
      final userId = await _getUserIdFromTokenManager();
      final userName = await _getUserName();

      _webrtcManager = WebRTCManager();
      _webrtcManager.initialize(this, 1, "Raji");
      callKitIntegration = CallKitIntegration();
      callKitIntegration.initialize(webrtcManager);

      _webrtcManager.onIncomingCall = (callData) {
        debugPrint("📨 Incoming call received via WebRTC");
        audio.play(SynthSoundType.ringtone);
        callKitIntegration.handleIncomingCallFromWebRTC(callData);
      };

      _webrtcManager.onCallStarted = (callData) {
        debugPrint('📞 Call started via WebRTC');
      };

      _webrtcManager.onCallEnded = (callData) {
        debugPrint('📞 Call ended via WebRTC');
        audio.stop();
      };

      debugPrint('✅ WebRTC Manager initialized');
    } catch (e) {
      debugPrint('❌ Error initializing WebRTC Manager: $e');
    }
  }

  // Event Handlers (modified to use isolate)
  void _setupChatHandlers() {
    on('chat_authenticated', (data) {
      _isAuthenticated = true;
      _emitEvent('chat_authenticated', data);
    });

    on('chat_initialized', (data) {
      debugPrint("data?? $data");
      _isAuthenticated = true;
      getMessages();
      getOnlineUsers();
      _emitEvent('chat_initialized', data);
    });

    // Use isolate for heavy processing
    on('new_message', (data) {
      _queueMessageForBatch(data);
    });

    on('message_sent', (data) {
      _emitEvent('message_sent', data);
    });

    on('message_edited', (data) {
      _sendToIsolate(IsolateMessage(type: 'update_message', data: data));
    });

    on('message_deleted', (data) {
      _handleMessageDeletedInUI(data);
    });

    on('user_typing', (data) {
      _sendToIsolate(IsolateMessage(type: 'process_typing_data', data: data));
    });

    on('user_stopped_typing', (data) {
      _sendToIsolate(IsolateMessage(type: 'process_typing_data', data: data));
    });

    on('user_joined', (data) {
      _emitEvent('user_joined', data);
    });

    on('user_left', (data) {
      _emitEvent('user_left', data);
    });

    on('user_online', (data) {
      _sendToIsolate(IsolateMessage(type: 'process_presence_data', data: data));
    });

    on('user_offline', (data) {
      _sendToIsolate(IsolateMessage(type: 'process_presence_data', data: data));
    });

    // In _setupChatHandlers() method:
    on('online_users', (data) {
      // Send to isolate for processing
      _sendToIsolate(IsolateMessage(type: 'process_presence_data', data: data));

      // Also emit the event for any direct listeners
      _emitEvent('online_users', data);
    });

    on('call_started', (data) {
      _sendToIsolate(
        IsolateMessage(type: 'process_call_data', data: data),
      ).then((_) {
        _handleCallStarted(data);
      });
    });

    on('call_answered', (data) {
      debugPrint('📞 Call answered: $data');
      audio.stop();
      _emitEvent('call_answered', data);
    });

    on('call_rejected', (data) {
      debugPrint('📞 Call rejected: $data');
      audio.stop();
      _emitEvent('call_rejected', data);
    });

    on('call_ended', (data) {
      debugPrint('📞 Call ended: $data');
      audio.stop();
      _emitEvent('call_ended', data);
    });

    on('user_joined_call', (data) {
      debugPrint('📞 User joined call: $data');
      _emitEvent('user_joined_call', data);
    });

    on('user_left_call', (data) {
      debugPrint('📞 User left call: $data');
      _emitEvent('user_left_call', data);
    });

    // WebRTC events
    on('webrtc_offer', (data) {
      _emitEvent('webrtc_offer', data);
    });

    on('webrtc_answer', (data) {
      _emitEvent('webrtc_answer', data);
    });

    on('webrtc_ice_candidate', (data) {
      _emitEvent('webrtc_ice_candidate', data);
    });

    // Ping/pong
    on('ping', (_) {
      emit('pong', {'timestamp': DateTime.now().millisecondsSinceEpoch});
    });
  }

  // Batch Processing
  void _queueMessageForBatch(dynamic data) {
    _messageBatch.add(data);

    if (_batchTimer == null || !_batchTimer!.isActive) {
      _batchTimer = Timer(_batchDelay, _processMessageBatch);
    }

    if (_messageBatch.length >= _batchSize) {
      _batchTimer?.cancel();
      _processMessageBatch();
    }
  }

  void _processMessageBatch() {
    if (_messageBatch.isEmpty) return;

    final batch = List.from(_messageBatch);
    _messageBatch.clear();

    _sendToIsolate(IsolateMessage(type: 'process_message_batch', data: batch));
  }

  // UI Helper Methods
  void _addMessageToGroupUI(num groupId, Message message) {
    // Play notification if not our own message
    if (_userId != message.sender.toString() &&
        message.type != 'system' &&
        message.messageType != 'SYSTEM') {
      _vibrate();
      audio.play(SynthSoundType.message);
    }

    // Add to unread messages if appropriate
    if (_userId != message.sender.toString() &&
        message.type != 'system' &&
        message.messageType != 'SYSTEM' &&
        !_isMessageReadByUser(message, _userId)) {
      _unreadMessagesUI.putIfAbsent(groupId, () => <String>{});
      _unreadMessagesUI[groupId]!.add(message.id);

      if (_currentGroupId == groupId) {
        markMessageAsRead(message.id, groupId);
      }
    }

    // Add to UI state
    final groupIndex = _messages.value.indexWhere((g) => g.groupId == groupId);
    if (groupIndex == -1) {
      _messages.value.add(MessageGroup(groupId: groupId, messages: [message]));
    } else {
      final existingMessages = _messages.value[groupIndex].messages;
      final exists = existingMessages.any(
        (m) =>
            m.id == message.id ||
            (message.tempId != null && m.tempId == message.tempId),
      );

      if (!exists) {
        existingMessages.add(message);
        existingMessages.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );
      }
    }

    _emitEvent('message_received', message);
  }

  void _handleMessageDeletedInUI(dynamic data) {
    final messageId = data['messageId'];
    final groupId = data['groupId'];

    final groupIndex = _messages.value.indexWhere((g) => g.groupId == groupId);
    if (groupIndex != -1) {
      _messages.value[groupIndex].messages.removeWhere(
        (m) => m.id == messageId,
      );
      _notifyListeners();
    }

    _emitEvent('message_deleted', data);
  }

  void _handleCallStarted(dynamic data) {
    try {
      debugPrint('📞 Incoming call received: $data');
      final callData = CallData.fromJson(data);
      debugPrint('📞 Incoming call received:4 ${callData.toJson()}');
      webrtcManager.setIncomingCall(callData);
      _emitEvent('call_started', data);
    } on Exception catch (e) {
      debugPrint("e.toString();??? ${e.toString()}");
    }
  }

  // Presence methods
  void getOnlineUsers({String? groupId}) {
    if (!_isConnected) {
      if (groupId != null) {
        _queueMessage('get_online_users', {'groupId': groupId});
      } else {
        _queueMessage('get_online_users', {});
      }
      return;
    }

    // Send to isolate for processing if we have cached data
    if (_onlineUsersByGroupUI.isNotEmpty || _onlineUsersUI.isNotEmpty) {
      // Get cached data immediately for UI
      final cachedData = {
        'users': _onlineUsersUI.toList(),
        'groupUsers': Map.from(
          _onlineUsersByGroupUI,
        ).map((key, value) => MapEntry(key, value.toList())),
      };

      _emitEvent('online_users_cached', cachedData);
    }

    // Request fresh data from server
    if (groupId != null) {
      emit('get_online_users', {'groupId': groupId});
    } else {
      emit('get_online_users');
    }
  }

  // Helper to get online users for a specific group from UI cache
  List<num> getOnlineUsersForGroup(dynamic groupId) {
    final groupKey = groupId;
    final users = _onlineUsersByGroupUI[groupKey];
    return users?.toList() ?? [];
  }

  // Helper to get online count for a specific group from UI cache
  int getOnlineCountForGroup(dynamic groupId) {
    final groupKey = groupId;
    final users = _onlineUsersByGroupUI[groupKey];
    return users?.length ?? 0;
  }

  // Public API Methods (modified to use isolate)
  void getMessages({int page = 1, int limit = 50, String? before}) {
    if (!_isConnected) {
      _queueMessage('get_messages', {
        'page': page,
        'limit': limit,
        'before': before,
      });
      return;
    }

    _sendToIsolate(
      IsolateMessage(
        type: 'get_messages',
        data: {
          'groupId': _currentGroupId,
          'page': page,
          'limit': limit,
          'before': before,
        },
      ),
    );

    emit('get_messages', {'page': page, 'limit': limit, 'before': before});
  }

  Map<String, dynamic> sendMessage(SendMessageParams params) {
    final messageData = params.toJson();

    // Send to isolate for processing
    _sendToIsolate(IsolateMessage(type: 'update_message', data: messageData));

    if (!_isConnected) {
      _queueMessage('send_message', messageData);
      return messageData;
    }

    emit('send_message', messageData);
    return messageData;
  }

  void markMessageAsRead(String messageId, num groupId) {
    // Update UI immediately
    _unreadMessagesUI[groupId]?.remove(messageId);
    if (_unreadMessagesUI[groupId]?.isEmpty ?? false) {
      _unreadMessagesUI.remove(groupId);
    }

    // Update message in isolate
    _sendToIsolate(
      IsolateMessage(
        type: 'mark_messages_read',
        data: {
          'groupId': groupId,
          'messageIds': [messageId],
          'userId': _userId,
          'userName': _userName,
        },
      ),
    );

    if (!_isConnected) {
      _queueMessage('mark_message_read', {
        'messageId': messageId,
        'groupId': groupId,
      });
      return;
    }

    emit('mark_message_read', {
      'messageId': messageId,
      'groupId': groupId,
      'userId': _userId,
      'userName': _userName,
    });
  }

  void markMessagesAsRead(List<String> messageIds, num groupId) {
    if (!_isConnected) {
      _queueMessage('mark_messages_read', {
        'messageIds': messageIds,
        'groupId': groupId,
      });
      return;
    }

    // Update UI immediately
    _unreadMessagesUI[groupId]?.removeAll(messageIds);
    if (_unreadMessagesUI[groupId]?.isEmpty ?? false) {
      _unreadMessagesUI.remove(groupId);
    }

    // Update in isolate
    _sendToIsolate(
      IsolateMessage(
        type: 'mark_messages_read',
        data: {
          'groupId': groupId,
          'messageIds': messageIds,
          'userId': _userId,
          'userName': _userName,
        },
      ),
    );

    emit('mark_messages_read', {
      'messageIds': messageIds,
      'groupId': groupId,
      'userId': _userId,
      'userName': _userName,
    });
  }

  void addReaction(String messageId, String emoji, String groupId) {
    // Update in isolate
    _sendToIsolate(
      IsolateMessage(
        type: 'add_reaction',
        data: {
          'groupId': groupId,
          'messageId': messageId,
          'emoji': emoji,
          'userId': _userId,
          'userName': _userName,
        },
      ),
    );

    if (!_isConnected) {
      _queueMessage('add_reaction', {
        'messageId': messageId,
        'emoji': emoji,
        'groupId': groupId,
      });
      return;
    }

    emit('add_reaction', {
      'messageId': messageId,
      'emoji': emoji,
      'groupId': groupId,
      'userId': _userId,
      'userName': _userName,
    });
  }

  // WebRTC methods (unchanged)
  void sendWebRTCOffer(Map<String, dynamic> data) {
    emit('webrtc_offer', data);
  }

  void sendWebRTCAnswer(Map<String, dynamic> data) {
    emit('webrtc_answer', data);
  }

  void sendWebRTCICECandidate(Map<String, dynamic> data) {
    emit('webrtc_ice_candidate', data);
  }

  Future<CallData> startWebRTCCall(
    BuildContext context, {
    required String type,
    required int groupId,
    required String groupName,
  }) async {
    try {
      final callData = await _webrtcManager.startCall(
        type: type == 'video' ? CallType.video : CallType.audio,
        groupId: groupId,
        groupName: groupName,
      );

      final messageData = {
        'groupId': groupId,
        'message': 'Started a ${type} call',
        'messageType': 'CALL',
        'metadata': {
          'eventType': 'CALL_STARTED',
          'callData': callData.toJson(),
        },
      };
      audio.play(SynthSoundType.ringtone);
      _emitEvent('call_started', callData.toJson());
      emit('send_message', messageData);
      return callData;
    } catch (e) {
      debugPrint('❌ Error starting WebRTC call: $e');
      rethrow;
    }
  }

  Future<void> joinWebRTCCall(CallData callData) async {
    try {
      await _webrtcManager.joinCall(callData);
      debugPrint('✅ Joined WebRTC call');
    } catch (e) {
      debugPrint('❌ Error joining WebRTC call: $e');
      rethrow;
    }
  }

  void endWebRTCCall() {
    _webrtcManager.endCall();
    debugPrint('✅ Ended WebRTC call');
  }

  void rejectWebRTCCall() {
    _webrtcManager.rejectCall();
    debugPrint('✅ Rejected WebRTC call');
  }

  // Connection Management (unchanged)
  Future<void> connect() async {
    _cancelReconnect();
    final token = await tokenManager.getToken();
    if (token == null) {
      debugPrint('⚠️ Cannot connect: No token available');
      return;
    }
    debugPrint('🔌 Connecting to chat socket...');
    await socketService.connect();
  }

  void disconnect() {
    _cancelReconnect();
    debugPrint('🔌 Disconnecting from chat socket...');
    socketService.disconnect();
    _isConnected = false;
    _isAuthenticated = false;
    _connectionStatus = 'disconnected';
    _notifyListeners();
  }

  void reconnect() {
    _cancelReconnect();
    debugPrint('🔄 Reconnecting chat socket...');
    socketService.reconnect();
  }

  // Token Management (unchanged)
  Future<void> _checkAndConnect() async {
    try {
      final token = await tokenManager.getToken();
      final userId = await _getUserIdFromTokenManager();
      if (token != null && userId != null) {
        await _handleTokenChange(token, userId);
      } else {
        debugPrint('⚠️ No token or user ID available');
        disconnect();
        _clearChatData();
      }
    } catch (e) {
      debugPrint('❌ Error checking initial token: $e');
    }
  }

  Future<void> _handleTokenChange(String? newToken, String? newUserId) async {
    final oldToken = _currentToken;
    final oldUserId = _userId;
    _currentToken = newToken;
    _userId = newUserId;

    if (newToken == null || newUserId == null) {
      debugPrint('🔒 No valid token or user ID, disconnecting...');
      disconnect();
      _clearChatData();
      return;
    }

    if (oldToken == null && oldUserId == null) {
      debugPrint('🔑 First time connection with valid token');
      await connect();
    } else if (oldToken != newToken || oldUserId != newUserId) {
      debugPrint('🔄 Token/user ID changed, reconnecting...');
      disconnect();
      await Future.delayed(const Duration(milliseconds: 500));
      await connect();
    }
  }

  void _clearChatData() {
    _messages.value.clear();
    _typingDataUI.clear();
    _unreadMessagesUI.clear();
    _onlineUsersUI.clear();
    _onlineUsersByGroupUI.clear();
    _notifyListeners();
  }

  // Helper Methods
  bool _isMessageReadByUser(Message message, String? userId) {
    if (message.readBy == null || userId == null) return false;
    return message.readBy!.any((read) {
      if (read is Map) {
        return read['user']?.toString() == userId ||
            read['userId']?.toString() == userId;
      }
      return read.toString() == userId;
    });
  }

  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      debugPrint('❌ Error vibrating: $e');
    }
  }

  Future<String?> _getUserIdFromTokenManager() async {
    try {
      final userId = await tokenManager.getUserId();
      return userId?.toString();
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  Future<String?> _getUserName() async {
    return 'User';
  }

  void _startTokenMonitoring() {
    if (_tokenMonitoringStarted) return;
    _tokenMonitoringStarted = true;
    _tokenCheckTimer = Timer.periodic(_tokenCheckInterval, (_) async {
      await _checkTokenAndReconnect();
    });
    debugPrint('🔐 Started token monitoring for chat');
  }

  void _stopTokenMonitoring() {
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = null;
    _tokenMonitoringStarted = false;
    debugPrint('🔐 Stopped token monitoring for chat');
  }

  Future<void> _checkTokenAndReconnect() async {
    try {
      final token = await tokenManager.getToken();
      final userId = await _getUserIdFromTokenManager();
      if (token != _currentToken || userId != _userId) {
        debugPrint('🔄 Token/user ID changed, reconnecting...');
        await _handleTokenChange(token, userId);
      }
      if (token != null) {
        final isExpired = await tokenManager.isTokenExpired();
        if (isExpired) {
          debugPrint('⚠️ Token expired, disconnecting...');
          disconnect();
          _clearChatData();
        }
      } else if (_currentToken != null) {
        debugPrint('⚠️ Token removed, disconnecting...');
        disconnect();
        _clearChatData();
      }
    } catch (e) {
      debugPrint('❌ Error checking token: $e');
    }
  }

  // Event Management
  void on(String event, Function(dynamic) handler) {
    if (socketService.socket != null && socketService.isConnected) {
      socketService.socket!.on(event, handler);
    } else {
      _queueMessage('_event_$event', handler);
    }

    if (!_eventHandlers.containsKey(event)) {
      _eventHandlers[event] = [];
    }
    _eventHandlers[event]!.add(handler);
  }

  void off(String event, Function(dynamic) handler) {
    if (_eventHandlers.containsKey(event)) {
      _eventHandlers[event]!.remove(handler);
    }
  }

  void _emitEvent(String event, [dynamic data]) {
    final handlers = _eventHandlers[event];
    if (handlers != null) {
      for (final handler in handlers) {
        handler(data);
      }
    }
  }

  void emit(String event, [dynamic data]) {
    if (!socketService.isConnected) {
      debugPrint('⚠️ Cannot emit $event: Socket not connected');
      return;
    }

    try {
      socketService.socket?.emit(event, data);
      debugPrint('📤 Emitted event: $event');
    } catch (e) {
      debugPrint('❌ Error emitting event $event: $e');
    }
  }

  // Connection Event Handlers
  void _handleConnected() {
    debugPrint('🎉 Chat socket connected');
    _isConnected = true;
    _connectionStatus = 'connected';
    _reconnectAttempts = 0;
    _processMessageQueue();
    _notifyListeners();
    _emitEvent('connected');
  }

  void _handleConnecting() {
    debugPrint('🔄 Connecting to chat socket...');
    _connectionStatus = 'connecting';
    _notifyListeners();
  }

  void _handleDisconnected(String reason) {
    debugPrint('🔌 Chat socket disconnected: $reason');
    _isConnected = false;
    _isAuthenticated = false;
    _connectionStatus = 'disconnected';
    _notifyListeners();
    _emitEvent('disconnected', {'reason': reason});
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    debugPrint('❌ Chat socket error: $error');
    _connectionStatus = 'disconnected';
    _notifyListeners();
    _emitEvent('error', {'error': error.toString()});
  }

  void _handleReconnectAttempt(int attempt) {
    debugPrint('🔄 Chat socket reconnect attempt: $attempt');
    _connectionStatus = 'reconnecting';
    _reconnectAttempts = attempt;
    _notifyListeners();
    _emitEvent('reconnect_attempt', {'attempt': attempt});
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      _emitEvent('error', {'error': 'Failed to reconnect to chat service'});
      return;
    }
    _reconnectAttempts++;
    final delay = _reconnectDelay * (1 << (_reconnectAttempts - 1));
    debugPrint(
      '⏰ Scheduling reconnect in ${delay.inMilliseconds}ms (attempt $_reconnectAttempts)',
    );
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _processMessageQueue() {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    _isProcessingQueue = true;
    while (_messageQueue.isNotEmpty) {
      final message = _messageQueue.removeAt(0);
      if (_isConnected) {
        emit(message['event'], message['data']);
      }
    }
    _isProcessingQueue = false;
  }

  void _queueMessage(String event, dynamic data) {
    _messageQueue.add({'event': event, 'data': data});
  }

  void _notifyListeners() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  // Cleanup
  @override
  void dispose() {
    // Shutdown isolate
    _sendToIsolate(IsolateMessage(type: 'shutdown'));
    _isolate?.kill(priority: Isolate.immediate);
    _isolateReceivePort?.close();

    _stopTokenMonitoring();
    _cancelReconnect();
    audio.stop();
    _eventHandlers.clear();
    _messageQueue.clear();
    socketService.dispose();
    _batchTimer?.cancel();
    _clearChatData();

    super.dispose();
  }

  // Other methods (keep as is)
  void joinGroup(num groupId) {
    _currentGroupId = groupId;
    if (!_isConnected) {
      _queueMessage('join_chat', {'groupId': groupId});
      return;
    }
    emit('join_chat', {'groupId': groupId});
    markAllGroupMessagesAsRead(groupId);
  }

  void leaveGroup(num groupId) {
    if (_currentGroupId == groupId) {
      _currentGroupId = null;
    }
    if (!_isConnected) {
      _queueMessage('leave_chat', {'groupId': groupId});
      return;
    }
    emit('leave_chat', {'groupId': groupId});
  }

  Map<String, dynamic> sendTextMessage(
    int groupId,
    String content,
    String tempId, {
    Map<String, dynamic>? replyTo,
  }) {
    return sendMessage(
      SendMessageParams(
        groupId: groupId,
        message: content,
        messageType: 'TEXT',
        tempId: tempId,
        replyTo: replyTo,
      ),
    );
  }

  void markAllGroupMessagesAsRead(num groupId) {
    if (!_isConnected) {
      _queueMessage('mark_group_read', {'groupId': groupId});
      return;
    }
    _unreadMessagesUI.remove(groupId);
    emit('mark_group_read', {'groupId': groupId});
    _notifyListeners();
  }

  void startTyping(String groupId) {
    if (!_isConnected) {
      _queueMessage('typing_start', {'groupId': groupId});
      return;
    }
    emit('typing_start', {'groupId': groupId});
  }

  void stopTyping(String groupId) {
    if (!_isConnected) {
      _queueMessage('typing_stop', {'groupId': groupId});
      return;
    }
    emit('typing_stop', {'groupId': groupId});
  }

  List<TypingUser> getTypingUsers(num groupId) {
    return _typingDataUI[groupId] ?? [];
  }

  // Audio generation (unchanged)
  Uint8List generateSineWav(double freq, double duration) {
    const sampleRate = 44100;
    final samples = (duration * sampleRate).toInt();
    final pcm = Int16List(samples);

    for (int i = 0; i < samples; i++) {
      pcm[i] = (sin(2 * pi * freq * i / sampleRate) * 2000).toInt();
    }

    final byteData = ByteData(44 + pcm.lengthInBytes);
    byteData.setUint32(0, 0x52494646, Endian.big);
    byteData.setUint32(4, 36 + pcm.lengthInBytes, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big);
    byteData.setUint32(12, 0x666d7420, Endian.big);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint32(36, 0x64617461, Endian.big);
    byteData.setUint32(40, pcm.lengthInBytes, Endian.little);

    byteData.buffer.asUint8List().setRange(
      44,
      byteData.lengthInBytes,
      pcm.buffer.asUint8List(),
    );
    return byteData.buffer.asUint8List();
  }
}
