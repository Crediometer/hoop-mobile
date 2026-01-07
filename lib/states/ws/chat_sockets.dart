// lib/providers/chat_websocket_handler.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/main.dart';
import 'package:hoop/screens/calls/call_screen.dart';
import 'package:hoop/services/callkit_integration.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:vibration/vibration.dart';

// DTOs and Models
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/services/websocket_service.dart';

// Chat Models
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
      '_id': id, // Include both id and _id for compatibility
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
  final num group; // String or int
  final String? tempId;
  final dynamic sender; // String or int
  final String content;
  final String? message;
  final DateTime? createdAt;
  final String? senderName;
  final String type; // 'text', 'image', 'file', 'system', 'call'
  final String? messageType;
  final String? status; // 'sent', 'delivered', 'read', 'edited', 'deleted'
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

  // Helper to convert from frontend type to backend type
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
      '_id': id, // Include both for compatibility
      'groupId': group,
      'group': group,
      if (tempId != null) 'tempId': tempId,
      'sender': sender,
      'userId': sender, // Include both sender and userId for compatibility
      'content': content,
      'message': content, // Include both content and message
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      if (senderName != null) 'senderName': senderName,
      if (senderName != null)
        'userName': senderName, // Include both for compatibility
      'type': type,
      'messageType':
          _reverseMapMessageType(type) ??
          type.toUpperCase(), // Convert to backend format
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

  // Helper method to create a copy with updated fields
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

  // Helper to check if message is from current user
  bool isFromUser(String userId) {
    return sender.toString() == userId;
  }

  // Helper to check if message is read by specific user
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

  // Helper to add a user to readBy list
  Message markAsReadByUser(String userId, String userName) {
    final List<dynamic> updatedReadBy = List.from(readBy ?? []);

    // Check if user already marked as read
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

  // Helper to add a reaction
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

  // Helper to remove a reaction
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
  final num groupId; // String or int
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

class ChatWebSocketHandler with ChangeNotifier {
  final BaseWebSocketService socketService = BaseWebSocketService(
    namespace: '/group-chat',
  );
  final TokenManager tokenManager = TokenManager.instance;

  // State
  final List<MessageGroup> _messages = [];

  late CallKitIntegration _callKitIntegration;
  late WebRTCManager _webrtcManager;
  num? _currentGroupId;
  int _reconnectAttempts = 0;
  final Map<num, List<TypingUser>> _typingData = {};
  final Map<num, Set<String>> _unreadMessages = {};
  String? _lastReadMessageId;
  final Map<num, Set<num>> _onlineUsersByGroup = {};
  final Set<num> _onlineUsers = {};

  // Connection state
  bool _isConnected = false;
  bool _isAuthenticated = false;
  String _connectionStatus =
      'disconnected'; // 'connected', 'connecting', 'disconnected', 'reconnecting'

  // Typing state
  bool _isTyping = false;
  final Set<String> _typingUsers = {};
  final Map<String, Set<String>> _typingUsersByGroup = {};

  // Reconnection
  Timer? _reconnectTimer;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 1);

  // Event handlers
  final Map<String, List<Function(dynamic)>> _eventHandlers = {};

  // Pending messages queue
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;

  // Audio/vibration
  AudioSession? _audioSession;
  bool _isRinging = false;

  // User info
  String? _userId;
  String? _userName;

  // Token monitoring
  Timer? _tokenCheckTimer;
  String? _currentToken;
  bool _tokenMonitoringStarted = false;
  final Duration _tokenCheckInterval = const Duration(seconds: 2);
  WebRTCManager get webrtcManager => _webrtcManager;

  ChatWebSocketHandler() {
    _initialize();
  }

  // Getters
  List<MessageGroup> get messages => List.unmodifiable(_messages);
  num? get currentGroupId => _currentGroupId;
  int get reconnectAttempts => _reconnectAttempts;
  Map<String, List<TypingUser>> get typingData => Map.unmodifiable(_typingData);
  Map<num, Set<String>> get unreadMessages => Map.unmodifiable(_unreadMessages);
  String? get lastReadMessageId => _lastReadMessageId;
  Set<num> get onlineUsers => Set.unmodifiable(_onlineUsers);
  Map<String, Set<String>> get onlineUsersByGroup =>
      Map.unmodifiable(_onlineUsersByGroup);
  final List<MapEntry<String, Function(dynamic)>> _pendingHandlers = [];
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  String get connectionStatus => _connectionStatus;

  int get totalUnreadMessages =>
      _unreadMessages.values.fold(0, (sum, set) => sum + set.length);

  bool get isTyping => _isTyping;
  Set<String> get typingUsers => Set.unmodifiable(_typingUsers);
  Map<String, Set<String>> get typingUsersByGroup =>
      Map.unmodifiable(_typingUsersByGroup);

  bool get isCallingEnabled => true; // Assuming WebRTC is available

  Future<void> _initialize() async {
    // Load user info
    _userId = await _getUserIdFromTokenManager();
    _userName = await _getUserName();

    // Setup connection event handlers
    socketService.onConnected(_handleConnected);
    socketService.onDisconnected(_handleDisconnected);
    socketService.onError(_handleError);
    socketService.onConnecting(_handleConnecting);
    socketService.onReconnectAttempt(_handleReconnectAttempt);

    // Setup chat-specific event handlers
    _setupChatHandlers();

    // Start token monitoring
    _startTokenMonitoring();

    // Check initial token and connect if available
    await _checkAndConnect();

    // Initialize audio session
    _initializeAudio();

    _initializeWebRTCManager();
  }

  void _initializeWebRTCManager() async {
    try {
      final userId = await _getUserIdFromTokenManager();
      final userName = await _getUserName();

      _webrtcManager = WebRTCManager();
      _webrtcManager.initialize(this, 1, "Raji"); // todo: change this
      _callKitIntegration = CallKitIntegration();

      _callKitIntegration.initialize(webrtcManager);
      // Setup callbacks
      _webrtcManager.onIncomingCall = (callData) {
        //logger.i('📨 Incoming call received via WebRTC');

        // Send notification via existing chat system
        _playRingtone();
        _callKitIntegration.handleIncomingCallFromWebRTC(callData);
        // You can also show a notification or update UI
        // This will be handled by your CallKit integration
      };

      _webrtcManager.onCallStarted = (callData) {
        //logger.i('📞 Call started via WebRTC');
        // Update UI or show call screen
      };

      _webrtcManager.onCallEnded = (callData) {
        //logger.i('📞 Call ended via WebRTC');
        _stopRingtone();
      };

      //logger.i('✅ WebRTC Manager initialized');
    } catch (e) {
      //logger.e('❌ Error initializing WebRTC Manager: $e');
    }
  }

  // Add WebRTC signaling methods to your ChatWebSocketHandler
  void sendWebRTCOffer(Map<String, dynamic> data) {
    emit('webrtc_offer', data);
  }

  void sendWebRTCAnswer(Map<String, dynamic> data) {
    emit('webrtc_answer', data);
  }

  void sendWebRTCICECandidate(Map<String, dynamic> data) {
    emit('webrtc_ice_candidate', data);
  }

  // Add call management methods to your existing ChatWebSocketHandler
  Future<void> startWebRTCCall({
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

      // Send chat message about call start (optional)
      final messageData = {
        'groupId': groupId,
        'message': 'Started a ${type} call',
        'messageType': 'CALL',
        'metadata': {
          'eventType': 'CALL_STARTED',
          'callData': callData.toJson(),
        },
      };

      emit('send_message', messageData);

      //logger.i('✅ WebRTC call started');
    } catch (e) {
      //logger.e('❌ Error starting WebRTC call: $e');
      rethrow;
    }
  }

  Future<void> joinWebRTCCall(CallData callData) async {
    try {
      await _webrtcManager.joinCall(callData);
      //logger.i('✅ Joined WebRTC call');
    } catch (e) {
      //logger.e('❌ Error joining WebRTC call: $e');
      rethrow;
    }
  }

  void endWebRTCCall() {
    _webrtcManager.endCall();
    //logger.i('✅ Ended WebRTC call');
  }

  void rejectWebRTCCall() {
    _webrtcManager.rejectCall();
    //logger.i('✅ Rejected WebRTC call');
  }

  // Audio initialization
  Future<void> _initializeAudio() async {
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession?.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('❌ Error initializing audio session: $e');
    }
  }

  // Token Monitoring Methods
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
    // Implement user name retrieval from storage
    return 'User'; // Replace with actual implementation
  }

  void _clearChatData() {
    _messages.clear();
    _typingData.clear();
    _unreadMessages.clear();
    _onlineUsers.clear();
    _onlineUsersByGroup.clear();
    _notifyListeners();
  }

  // Connection Event Handlers
  void _handleConnected() {
    debugPrint('🎉 Chat socket connected');
    _isConnected = true;
    _connectionStatus = 'connected';
    _reconnectAttempts = 0;
    _registerPendingHandlers();
    _processMessageQueue();
    _notifyListeners();
    _emitEvent('connected');
  }

  // Register pending event handlers when socket is connected
  void _registerPendingHandlers() {
    for (final handlerEntry in _pendingHandlers) {
      final event = handlerEntry.key;
      final handler = handlerEntry.value;

      socketService.socket?.on(event, handler);
      debugPrint('✅ Registered event listener for: $event');
    }

    // Clear pending handlers after registration
    _pendingHandlers.clear();
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

  // Event Management
  void on(String event, Function(dynamic) handler) {
    if (socketService.socket != null && socketService.isConnected) {
      // Socket is already connected, register immediately
      socketService.socket!.on(event, handler);
      debugPrint('✅ Immediately registered event listener for: $event');
    } else {
      // Socket not ready yet, queue the handler
      _pendingHandlers.add(MapEntry(event, handler));
      debugPrint('⏳ Queued event listener for: $event');
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

  // Setup chat event handlers
  void _setupChatHandlers() {
    // Authentication events
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

    // Group events
    on('chat_joined', (data) {
      _emitEvent('chat_joined', data);
    });

    on('chat_left', (data) {
      _emitEvent('chat_left', data);
    });

    on('group_joined', (data) {
      _emitEvent('group_joined', data);
    });

    on('groups_refreshed', (data) {
      _emitEvent('groups_refreshed', data);
    });

    // Message events
    on('new_message', (data) {
      _handleMessageReceived(Message.fromJson(data));
    });

    on('message_sent', (data) {
      _emitEvent('message_sent', data);
    });

    on('message_edited', (data) {
      _handleMessageEdited(data);
    });

    on('message_deleted', (data) {
      _handleMessageDeleted(data);
    });

    on('message_read', (data) {
      _emitEvent('message_read', data);
    });

    on('messages_read', (data) {
      _handleMessagesRead(data);
    });

    on('message_read_receipt', (data) {
      _handleMessageReadReceipt(data);
    });

    on('messages_list', (data) {
      _handleMessagesList(data);
    });

    // Reaction events
    on('reaction_added_success', (data) {
      _handleReactionReceived(data, true);
    });

    on('reaction_removed_success', (data) {
      _handleReactionReceived(data, false);
    });

    // Typing events
    on('user_typing', (data) {
      _handleTypingStart(data);
    });

    on('user_stopped_typing', (data) {
      _handleTypingStop(data);
    });

    // Presence events
    on('user_joined', (data) {
      _handleUserJoined(data);
    });

    on('user_left', (data) {
      _handleUserLeft(data);
    });

    on('user_online', (data) {
      _handleUserOnline(data);
    });

    on('user_offline', (data) {
      _handleUserOffline(data);
    });

    on('online_users', (data) {
      _handleOnlineUsers(data);
    });

    // Calling events
    on('call_started', (data) {
      debugPrint("Incoming call received data??? $data");
      _handleCallStarted(data);
    });

    on('call_answered', (data) {
      _handleCallAnswered(data);
    });

    on('call_rejected', (data) {
      _handleCallRejected(data);
    });

    on('call_ended', (data) {
      _handleCallEnded(data);
    });

    on('user_joined_call', (data) {
      _handleUserJoinedCall(data);
    });

    on('user_left_call', (data) {
      _handleUserLeftCall(data);
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

  // Message handling
  void _handleMessageReceived(Message message) {
    final groupId = message.group;

    // Play notification if not our own message
    if (_userId != message.sender.toString() &&
        message.type != 'system' &&
        message.messageType != 'SYSTEM') {
      _playMessageNotification();
    }

    // Add to unread messages if appropriate
    if (_userId != message.sender.toString() &&
        message.type != 'system' &&
        message.messageType != 'SYSTEM' &&
        !_isMessageReadByUser(message, _userId)) {
      _addUnreadMessage(groupId, message.id);

      // If currently viewing this group, mark as read immediately
      if (_currentGroupId == groupId) {
        markMessageAsRead(message.id, groupId);
      }
    }

    // Add message to state
    _addMessageToGroup(groupId, message);

    _emitEvent('message_received', message);
  }

  void _handleMessageEdited(dynamic data) {
    final message = Message.fromJson(data);
    final groupId = message.group;

    _updateMessageInGroup(groupId, message);
    _emitEvent('message_edited', message);
  }

  void _handleMessageDeleted(dynamic data) {
    final messageId = data['messageId'];
    final groupId = data['groupId'];

    _removeMessageFromGroup(groupId, messageId);
    _emitEvent('message_deleted', data);
  }

  void _handleMessagesRead(dynamic data) {
    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);

    if (groupId != null && messageIds.isNotEmpty) {
      _markMessagesAsRead(groupId, messageIds, data['userId'] ?? _userId);
    }

    _emitEvent('messages_read', data);
  }

  void _handleMessageReadReceipt(dynamic data) {
    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);

    if (groupId != null && messageIds.isNotEmpty) {
      _markMessagesAsRead(groupId, messageIds, data['userId']);
    }

    _emitEvent('message_read_receipt', data);
  }

  void _handleMessagesList(dynamic data) {
    // try {

    final response = MessagesResponse.fromJson(data);

    _messages.clear();
    _messages.addAll(response.groups);

    // Track unread messages
    final newUnreadMessages = <num, Set<String>>{};
    for (final group in response.groups) {
      final groupId = group.groupId;
      final unreadMessageIds = <String>{};

      for (final message in group.messages) {
        if (_userId != message.sender.toString() &&
            message.type != 'system' &&
            message.messageType != 'SYSTEM' &&
            !_isMessageReadByUser(message, _userId)) {
          unreadMessageIds.add(message.id);
        }
      }

      if (unreadMessageIds.isNotEmpty) {
        newUnreadMessages[groupId] = unreadMessageIds;
      }
    }
    _unreadMessages.clear();
    _unreadMessages.addAll(newUnreadMessages);
    _emitEvent('messages_list', response);
    // } catch (e) {
    //   debugPrint('❌ Error parsing messages list: $e');
    // }
  }

  void _handleReactionReceived(dynamic data, bool isAdded) {
    final reaction = data;
    final groupId = int.parse(reaction['groupId'].toString());
    final messageId = reaction['messageId'];
    final emoji = reaction['emoji'] ?? reaction['reaction']?['emoji'];
    final userId =
        reaction['userId'] ?? reaction['reaction']?['userId']?.toString();
    final userName = reaction['userName'] ?? reaction['reaction']?['userName'];

    if (groupId == null ||
        messageId == null ||
        emoji == null ||
        userId == null) {
      return;
    }

    _updateMessageReaction(
      groupId,
      messageId,
      emoji,
      userId,
      userName,
      isAdded,
    );

    if (isAdded) {
      _emitEvent('reaction_added_success', data);
    } else {
      _emitEvent('reaction_removed_success', data);
    }
  }

  // Typing handlers
  void _handleTypingStart(dynamic data) {
    try {
      final indicator = TypingIndicator.fromJson(data);
      final currentUserId = _userId;

      // Don't show our own typing indicator
      if (indicator.typingUsers.any((user) => user.userId == currentUserId)) {
        return;
      }

      final now = DateTime.now();
      final currentTypingUsers = _typingData[indicator.groupId] ?? [];

      // Filter out old typing users (> 10 seconds)
      final validTypingUsers = currentTypingUsers.where((user) {
        if (user.startedAt == null) return true;
        return now.difference(user.startedAt!).inSeconds < 10;
      }).toList();

      // Merge with new typing users
      final newTypingUsers = indicator.typingUsers.where(
        (user) => user.userId != currentUserId,
      );

      for (final newUser in newTypingUsers) {
        final existingIndex = validTypingUsers.indexWhere(
          (u) => u.userId == newUser.userId,
        );
        if (existingIndex == -1) {
          validTypingUsers.add(newUser);
        } else {
          validTypingUsers[existingIndex] = newUser;
        }
      }

      // Only include users still typing
      final finalTypingUsers = validTypingUsers.where((user) {
        return indicator.typingUsers.any(
          (newUser) => newUser.userId == user.userId,
        );
      }).toList();

      _typingData[indicator.groupId] = finalTypingUsers;

      _emitEvent('typing_start', indicator);
      _emitEvent('user_typing', indicator);
      _notifyListeners();
    } catch (e) {
      debugPrint('❌ Error handling typing start: $e');
    }
  }

  void _handleTypingStop(dynamic data) {
    try {
      final indicator = TypingIndicator.fromJson(data);

      if (indicator.typingUsers.isEmpty) {
        _typingData.remove(indicator.groupId);
      } else {
        _typingData[indicator.groupId] = indicator.typingUsers;
      }

      _emitEvent('typing_stop', indicator);
      _emitEvent('user_stopped_typing', indicator);
      _notifyListeners();
    } catch (e) {
      debugPrint('❌ Error handling typing stop: $e');
    }
  }

  // Presence handlers
  void _handleUserJoined(dynamic data) {
    _emitEvent('user_joined', data);
    _emitEvent('group_update', {
      'type': 'user_joined',
      'groupId': data['groupId'],
      'data': data,
      'timestamp': data['timestamp'],
    });
  }

  void _handleUserLeft(dynamic data) {
    _emitEvent('user_left', data);
    _emitEvent('group_update', {
      'type': 'user_left',
      'groupId': data['groupId'],
      'data': data,
      'timestamp': data['timestamp'],
    });
  }

  void _handleUserOnline(dynamic data) {
    final userId = int.parse(data['userId'].toString());
    final groupId = int.parse(data['groupId'].toString());

    if (userId != null) {
      _onlineUsers.add(userId);
    }

    if (groupId != null && userId != null) {
      _onlineUsersByGroup.putIfAbsent(groupId, () => <num>{});
      _onlineUsersByGroup[groupId]!.add(userId);
    }

    _emitEvent('user_online', data);
    _notifyListeners();
  }

  void _handleUserOffline(dynamic data) {
    final userId = data['userId']?.toString();
    final groupId = data['groupId']?.toString();

    if (userId != null) {
      _onlineUsers.remove(userId);
    }

    if (groupId != null && userId != null) {
      final groupUsers = _onlineUsersByGroup[groupId];
      if (groupUsers != null) {
        groupUsers.remove(userId);
        if (groupUsers.isEmpty) {
          _onlineUsersByGroup.remove(groupId);
        }
      }
    }

    _emitEvent('user_offline', data);
    _notifyListeners();
  }

  void _handleOnlineUsers(dynamic data) {
    final groupIds = List<dynamic>.from(data['groupIds'] ?? []);
    final users = List<num>.from(data['users'] ?? []);

    final Set<num> userIds = users.map((u) => u).toSet();
    _onlineUsers.clear();
    _onlineUsers.addAll(userIds);

    for (final groupId in groupIds) {
      _onlineUsersByGroup[groupId] = userIds;
    }

    _emitEvent('online_users', data);
    _notifyListeners();
  }

  // Calling handlers
  void _handleCallStarted(dynamic data) {
    debugPrint('📞 Incoming call received: $data');

    // Only handle if we're not the initiator
    // if (data['fromUserId']?.toString() != _userId) {
    _playRingtone();
    _emitEvent('call_started', data);
    // }

    webrtcManager.answerCall().then((_) {
      print("?? going Here ");
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            callData: webrtcManager.activeCall!,
            webrtcManager: webrtcManager,
          ),
        ),
      );
    });
  }

  void _handleCallAnswered(dynamic data) {
    debugPrint('📞 Call answered: $data');
    _stopRingtone();
    _emitEvent('call_answered', data);
  }

  void _handleCallRejected(dynamic data) {
    debugPrint('📞 Call rejected: $data');
    _stopRingtone();
    _emitEvent('call_rejected', data);
  }

  void _handleCallEnded(dynamic data) {
    debugPrint('📞 Call ended: $data');
    _stopRingtone();
    _emitEvent('call_ended', data);
  }

  void _handleUserJoinedCall(dynamic data) {
    debugPrint('📞 User joined call: $data');
    _emitEvent('user_joined_call', data);
  }

  void _handleUserLeftCall(dynamic data) {
    debugPrint('📞 User left call: $data');
    _emitEvent('user_left_call', data);
  }

  // Message queue management
  void _queueMessage(String event, dynamic data) {
    _messageQueue.add({'event': event, 'data': data});
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

  // Audio notifications
  Future<void> _playMessageNotification() async {
    try {
      await _audioSession?.setActive(true);
      // Play notification sound
      // Implement audio playback using audioplayers or similar package
      await _vibrate();
    } catch (e) {
      debugPrint('❌ Error playing message notification: $e');
    }
  }

  Future<void> _playRingtone() async {
    if (_isRinging) return;

    _isRinging = true;
    // Implement ringtone playback
    debugPrint('🔔 Playing ringtone');
  }

  void _stopRingtone() {
    _isRinging = false;
    debugPrint('🔕 Stopped ringtone');
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

  // Public API Methods

  // Connection management
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

  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isConnected && _isAuthenticated) {
      return true;
    }

    final completer = Completer<bool>();
    final timer = Timer(timeout, () {
      completer.complete(false);
    });

    void checkConnection() {
      if (_isConnected && _isAuthenticated) {
        timer.cancel();
        completer.complete(true);
      }
    }

    // Check periodically
    final periodicTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      checkConnection();
    });

    // Also listen for connection events
    void connectedHandler(dynamic _) {
      checkConnection();
    }

    on('connected', connectedHandler);

    final result = await completer.future;

    periodicTimer.cancel();
    off('connected', connectedHandler);

    return result;
  }

  Future<bool> healthCheck() async {
    if (!_isConnected) return false;

    final completer = Completer<bool>();
    final timer = Timer(const Duration(seconds: 3), () {
      completer.complete(false);
    });

    void connectedHandler(dynamic _) {
      timer.cancel();
      completer.complete(true);
    }

    void errorHandler(dynamic _) {
      timer.cancel();
      completer.complete(false);
    }

    on('connected', connectedHandler);
    on('error', errorHandler);

    final result = await completer.future;

    // Cleanup after timeout
    Future.delayed(const Duration(seconds: 3), () {
      off('connected', connectedHandler);
      off('error', errorHandler);
    });

    return result;
  }

  // Group management
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

  void joinNewGroup(String groupId) {
    if (!_isConnected) {
      _queueMessage('join_new_group', {'groupId': groupId});
      return;
    }

    emit('join_new_group', {'groupId': groupId});
  }

  void refreshGroups() {
    if (!_isConnected) {
      _queueMessage('refresh_groups', {});
      return;
    }

    emit('refresh_groups');
  }

  // Message operations
  Map<String, dynamic> sendMessage(SendMessageParams params) {
    final messageData = params.toJson();

    if (!_isConnected) {
      _queueMessage('send_message', messageData);
      return messageData;
    }

    emit('send_message', messageData);
    return messageData;
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

  Future<Map<String, dynamic>> sendFileMessage(
    num groupId,
    List<int> fileBytes,
    String fileName,
    String mimeType, {
    String? caption,
  }) async {
    // Implement file upload first
    final fileUrl = await _uploadFile(fileBytes, fileName, mimeType, groupId);

    return sendMessage(
      SendMessageParams(
        groupId: groupId.toInt(),
        message: caption ?? fileName,
        messageType: 'FILE',
        tempId: 'file-${DateTime.now().millisecondsSinceEpoch}',
        attachments: [
          {
            'url': fileUrl,
            'type': mimeType,
            'name': fileName,
            'size': fileBytes.length,
          },
        ],
      ),
    );
  }

  void getMessages({int page = 1, int limit = 50, String? before}) {
    if (!_isConnected) {
      _queueMessage('get_messages', {
        'page': page,
        'limit': limit,
        'before': before,
      });
      return;
    }

    emit('get_messages', {'page': page, 'limit': limit, 'before': before});
  }

  void markMessageAsRead(String messageId, num groupId) {
    if (!_isConnected) {
      _queueMessage('mark_message_read', {
        'messageId': messageId,
        'groupId': groupId,
      });
      return;
    }

    // Update local state immediately
    _markMessagesAsRead(groupId, [messageId], _userId);

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

    // Update local state immediately
    _markMessagesAsRead(groupId, messageIds, _userId);

    emit('mark_messages_read', {
      'messageIds': messageIds,
      'groupId': groupId,
      'userId': _userId,
      'userName': _userName,
    });
  }

  void markAllGroupMessagesAsRead(num groupId) {
    if (!_isConnected) {
      _queueMessage('mark_group_read', {'groupId': groupId});
      return;
    }

    // Clear unread messages for this group
    _unreadMessages.remove(groupId);

    // Update all messages in this group to read status
    _updateGroupMessagesStatus(groupId, 'read');

    emit('mark_group_read', {'groupId': groupId});
    _notifyListeners();
  }

  void markAllMessagesAsRead() {
    if (!_isConnected) {
      _queueMessage('mark_all_read', {});
      return;
    }

    // Clear all unread messages
    _unreadMessages.clear();

    // Update all messages to read status
    for (final group in _messages) {
      _updateGroupMessagesStatus(group.groupId, 'read');
    }

    emit('mark_all_read');
    _notifyListeners();
  }

  void addReaction(String messageId, String emoji, String groupId) {
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

  void deleteMessage(String messageId, String groupId) {
    if (!_isConnected) {
      _queueMessage('delete_message', {
        'messageId': messageId,
        'groupId': groupId,
      });
      return;
    }

    emit('delete_message', {'messageId': messageId, 'groupId': groupId});
  }

  void editMessage(String messageId, num groupId, String content) {
    if (!_isConnected) {
      _queueMessage('edit_message', {
        'messageId': messageId,
        'groupId': groupId,
        'content': content,
      });
      return;
    }

    emit('edit_message', {
      'messageId': messageId,
      'groupId': groupId,
      'content': content,
    });
  }

  // Typing methods
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
    return _typingData[groupId] ?? [];
  }

  bool isUserTyping(num groupId, String userId) {
    final typers = getTypingUsers(groupId);
    return typers.any((user) => user.userId == userId);
  }

  String getTypingDisplayText(num groupId) {
    final typers = getTypingUsers(groupId);
    if (typers.isEmpty) return '';

    final names = typers.map((user) => user.userName).toList();
    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return '${names[0]}, ${names[1]} and ${typers.length - 2} others are typing...';
    }
  }

  bool isTypingDataEmpty() {
    return _typingData.isEmpty;
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

    if (groupId != null) {
      emit('get_online_users', {'groupId': groupId});
    } else {
      emit('get_online_users');
    }
  }

  List<num> getOnlineUsersForGroup(dynamic groupId) {
    final groupKey = groupId;
    final users = _onlineUsersByGroup[groupKey];
    return users?.toList() ?? [];
  }

  int getOnlineCountForGroup(dynamic groupId) {
    final groupKey = groupId;
    final users = _onlineUsersByGroup[groupKey];
    return users?.length ?? 0;
  }

  // Calling methods (stubs - implement with WebRTC)
  Future<void> startCall(String type, Map<String, dynamic> group) async {
    // Implement WebRTC call start
    debugPrint('📞 Starting $type call with group ${group['id']}');
  }

  Future<void> joinCall(CallData callData) async {
    // Implement WebRTC call join
    debugPrint('📞 Joining call ${callData.callId}');
  }

  void endCall(Map<String, dynamic> group) {
    // Implement WebRTC call end
    debugPrint('📞 Ending call in group ${group['id']}');
  }

  void rejectCall() {
    // Implement WebRTC call reject
    debugPrint('📞 Rejecting call');
  }

  // File upload
  Future<String> _uploadFile(
    List<int> fileBytes,
    String fileName,
    String mimeType,
    num groupId,
  ) async {
    // Implement file upload to server
    // This should make an HTTP request to your upload endpoint
    // Return the file URL
    return 'https://example.com/uploads/$fileName';
  }

  // Helper methods

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

  void _addMessageToGroup(num groupId, Message message) {
    final groupIndex = _messages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex == -1) {
      // Create new group
      _messages.add(MessageGroup(groupId: groupId, messages: [message]));
    } else {
      // Add to existing group
      final existingMessages = _messages[groupIndex].messages;

      // Check if message already exists
      final exists = existingMessages.any(
        (m) =>
            m.id == message.id ||
            (message.tempId != null && m.tempId == message.tempId),
      );

      if (!exists) {
        existingMessages.add(message);
        // Sort by timestamp
        existingMessages.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );
      }
    }

    _notifyListeners();
  }

  void _updateMessageInGroup(num groupId, Message message) {
    final groupIndex = _messages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex != -1) {
      final messageIndex = _messages[groupIndex].messages.indexWhere(
        (m) => m.id == message.id,
      );

      if (messageIndex != -1) {
        _messages[groupIndex].messages[messageIndex] = message;
        _notifyListeners();
      }
    }
  }

  void _removeMessageFromGroup(num groupId, String messageId) {
    final groupIndex = _messages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex != -1) {
      _messages[groupIndex].messages.removeWhere((m) => m.id == messageId);
      _notifyListeners();
    }
  }

  void _updateMessageReaction(
    num groupId,
    String messageId,
    String emoji,
    String userId,
    String? userName,
    bool isAdded,
  ) {
    final groupIndex = _messages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex != -1) {
      final messageIndex = _messages[groupIndex].messages.indexWhere(
        (m) => m.id == messageId,
      );

      if (messageIndex != -1) {
        final message = _messages[groupIndex].messages[messageIndex];
        final reactions = List<Map<String, dynamic>>.from(
          message.reactions ?? [],
        );

        final reactionIndex = reactions.indexWhere((r) => r['emoji'] == emoji);

        final userObj = {
          'userId': int.tryParse(userId) ?? userId,
          'userName': userName,
          'reactedAt': DateTime.now().toIso8601String(),
        };

        if (isAdded) {
          if (reactionIndex != -1) {
            final users = List<Map<String, dynamic>>.from(
              reactions[reactionIndex]['users'] ?? [],
            );
            final alreadyReacted = users.any(
              (u) =>
                  u['userId']?.toString() == userId || u.toString() == userId,
            );

            if (!alreadyReacted) {
              users.add(userObj);
              reactions[reactionIndex]['users'] = users;
              reactions[reactionIndex]['count'] = users.length;
            }
          } else {
            reactions.add({
              'emoji': emoji,
              'users': [userObj],
              'count': 1,
            });
          }
        } else {
          if (reactionIndex != -1) {
            final users = List<Map<String, dynamic>>.from(
              reactions[reactionIndex]['users'] ?? [],
            );
            users.removeWhere(
              (u) =>
                  u['userId']?.toString() == userId || u.toString() == userId,
            );

            if (users.isEmpty) {
              reactions.removeAt(reactionIndex);
            } else {
              reactions[reactionIndex]['users'] = users;
              reactions[reactionIndex]['count'] = users.length;
            }
          }
        }

        final updatedMessage = Message.fromJson({
          ...message.toJson(),
          'reactions': reactions,
        });

        _messages[groupIndex].messages[messageIndex] = updatedMessage;
        _notifyListeners();
      }
    }
  }

  void _addUnreadMessage(num groupId, String messageId) {
    _unreadMessages.putIfAbsent(groupId, () => <String>{});
    _unreadMessages[groupId]!.add(messageId);
    _notifyListeners();
  }

  void _markMessagesAsRead(
    num groupId,
    List<String> messageIds,
    String? userId,
  ) {
    final groupIndex = _messages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex != -1 && userId != null) {
      for (final message in _messages[groupIndex].messages) {
        if (messageIds.contains(message.id)) {
          final readBy = List<dynamic>.from(message.readBy ?? []);
          final userObj = {
            'userId': int.tryParse(userId) ?? userId,
            'userName': _userName,
            'readAt': DateTime.now().toIso8601String(),
          };

          if (!readBy.any(
            (r) =>
                (r is Map ? r['userId']?.toString() : r.toString()) == userId,
          )) {
            readBy.add(userObj);

            final messageIndex = _messages[groupIndex].messages.indexWhere(
              (m) => m.id == message.id,
            );

            if (messageIndex != -1) {
              _messages[groupIndex].messages[messageIndex] = Message.fromJson({
                ...message.toJson(),
                'status': 'read',
                'readBy': readBy,
              });
            }
          }
        }
      }
    }

    // Remove from unread messages
    final groupUnread = _unreadMessages[groupId];
    if (groupUnread != null) {
      for (final messageId in messageIds) {
        groupUnread.remove(messageId);
      }
      if (groupUnread.isEmpty) {
        _unreadMessages.remove(groupId);
      }
    }

    if (messageIds.isNotEmpty) {
      _lastReadMessageId = messageIds.last;
    }

    _notifyListeners();
  }

  void _updateGroupMessagesStatus(num groupId, String status) {
    final groupIndex = _messages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex != -1 && _userId != null) {
      for (int i = 0; i < _messages[groupIndex].messages.length; i++) {
        final message = _messages[groupIndex].messages[i];
        final readBy = List<dynamic>.from(message.readBy ?? []);
        final userObj = {
          'userId': int.tryParse(_userId!) ?? _userId,
          'userName': _userName,
          'readAt': DateTime.now().toIso8601String(),
        };

        if (!readBy.any(
          (r) => (r is Map ? r['userId']?.toString() : r.toString()) == _userId,
        )) {
          readBy.add(userObj);

          _messages[groupIndex].messages[i] = Message.fromJson({
            ...message.toJson(),
            'status': status,
            'readBy': readBy,
          });
        }
      }
    }
  }

  // Socket emit wrapper
  void emit(String event, [dynamic data]) {
    if (!_isConnected) {
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

  // Cleanup
  @override
  void dispose() {
    _stopTokenMonitoring();
    _cancelReconnect();
    _stopRingtone();
    _eventHandlers.clear();
    _messageQueue.clear();
    socketService.dispose();
    _pendingHandlers.clear();
    super.dispose();
  }

  void _notifyListeners() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  // Utility method to convert Message to JSON map (for debugging)
  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'groupId': message.group,
      'tempId': message.tempId,
      'sender': message.sender,
      'content': message.content,
      'message': message.message,
      'createdAt': message.createdAt?.toIso8601String(),
      'senderName': message.senderName,
      'type': message.type,
      'messageType': message.messageType,
      'status': message.status,
      'attachments': message.attachments,
      'reactions': message.reactions,
      'readBy': message.readBy,
      'pollData': message.pollData,
      'paymentStatus': message.paymentStatus,
      'systemInfo': message.systemInfo,
      'callData': message.callData,
      'edited': message.edited,
      'editedAt': message.editedAt?.toIso8601String(),
      'deleted': message.deleted,
      'deletedAt': message.deletedAt?.toIso8601String(),
      'deletedBy': message.deletedBy,
    };
  }
}
