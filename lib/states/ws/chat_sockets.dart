// lib/providers/chat_websocket_handler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/dtos/podos/chats/messages.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/services/audio/SynthNotificationAudio.dart';
import 'package:hoop/services/callkit_integration.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:vibration/vibration.dart';

class TypingIndicator {
  final num groupId;
  final List<TypingUser> typingUsers;

  TypingIndicator({required this.groupId, required this.typingUsers});

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      groupId: json['groupId'],
      typingUsers: (json['typingUsers'] as List)
          .map((u) => TypingUser.fromJson(u))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'typingUsers': typingUsers.map((u) => u.toJson()).toList(),
    };
  }
}

class SendMessageParams {
  final int groupId;
  final String message;
  final String messageType;
  final String tempId;
  final Map<String, dynamic>? replyTo;
  final List<Map<String, dynamic>>? attachments;
  final Map<String, dynamic>? metadata;

  SendMessageParams({
    required this.groupId,
    required this.message,
    required this.messageType,
    required this.tempId,
    this.replyTo,
    this.attachments,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'message': message,
      'messageType': messageType,
      'tempId': tempId,
      'replyTo': replyTo,
      'attachments': attachments,
      'metadata': metadata,
    };
  }
}

class IsolateMessage {
  final String type;
  final dynamic data;
  final SendPort? replyPort;

  IsolateMessage({required this.type, this.data, this.replyPort});
}

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
      case 'messages_list':
        _processMessagesList(message.data);
        break;
    }
  }

  void _processMessagesList(dynamic data) {
    try {
      // Data is a list of groups: [{group: X, messages: [...]}]
      if (data is! List<dynamic>) {
        debugPrint('❌ Expected List in isolate but got: ${data.runtimeType}');
        return;
      }
      
      print('📝 messages_list data is a List of ${data.length} groups');
      
      final List<Map<String, dynamic>> allMessages = [];
      
      for (final groupData in data) {
        try {
          final groupId = groupData['group'] ?? groupData['groupId'];
          final messagesData = List<Map<String, dynamic>>.from(groupData['messages'] ?? []);
          
          if (groupId == null) continue;
          
          // Add to local storage
          _messages.putIfAbsent(groupId, () => []);
          
          for (final messageData in messagesData) {
            try {
              final message = Message.fromJson(messageData);
              final exists = _messages[groupId]!.any((m) => m.id == message.id);
              if (!exists) {
                _messages[groupId]!.add(message);
              }
              allMessages.add(message.toJson());
            } catch (e) {
              debugPrint('❌ Error processing message in messages_list: $e');
            }
          }
          
          // Sort messages in this group
          _messages[groupId]!.sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('❌ Error processing group in isolate: $e');
        }
      }
      
      _sendPort.send(
        IsolateMessage(
          type: 'messages_list_processed',
          data: allMessages,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error processing messages_list in isolate: $e');
      debugPrint('Data received: $data');
      debugPrint('Data type: ${data.runtimeType}');
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
          'hasNext': end < messages.length,
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

  // Singleton instance
  static ChatWebSocketHandler? _instance;

  factory ChatWebSocketHandler() {
    return _instance ??= ChatWebSocketHandler._internal();
  }

  ChatWebSocketHandler._internal();

  // Isolate Management
  Isolate? _isolate;
  ReceivePort? _isolateReceivePort;
  SendPort? _isolateSendPort;
  bool _isolateInitialized = false;
  final Map<String, Completer<dynamic>> _isolateCompleters = {};
  int _isolateRequestId = 0;

  // UI State - ALL AS VALUENOTIFIERS
  final ValueNotifier<List<MessageGroup>> _messages = ValueNotifier([]);
  final ValueNotifier<Map<num, List<TypingUser>>> _typingDataUI = ValueNotifier(
    {},
  );
  final ValueNotifier<Map<num, Set<String>>> _unreadMessagesUI = ValueNotifier(
    {},
  );
  final ValueNotifier<Set<num>> _onlineUsersUI = ValueNotifier({});
  final ValueNotifier<Map<num, Set<num>>> _onlineUsersByGroupUI = ValueNotifier(
    {},
  );
  final ValueNotifier<String?> _lastReadMessageId = ValueNotifier(null);
  final ValueNotifier<bool> _isTyping = ValueNotifier(false);
  final ValueNotifier<Map<String, Set<String>>> _typingUsersByGroup =
      ValueNotifier({});
  final ValueNotifier<bool> _isConnected = ValueNotifier(false);
  final ValueNotifier<String> _connectionStatus = ValueNotifier('disconnected');
  final ValueNotifier<CallData?> _incomingCall = ValueNotifier(null);
  final ValueNotifier<CallData?> _activeCall = ValueNotifier(null);
  final ValueNotifier<bool> _isAudioMuted = ValueNotifier(false);
  final ValueNotifier<bool> _isVideoMuted = ValueNotifier(false);
  final ValueNotifier<bool> _isCallActive = ValueNotifier(false);

  // Getters for ValueNotifiers
  ValueNotifier<List<MessageGroup>> get messages => _messages;
  ValueNotifier<Map<num, List<TypingUser>>> get typingData => _typingDataUI;
  ValueNotifier<Map<num, Set<String>>> get unreadMessages => _unreadMessagesUI;
  ValueNotifier<Set<num>> get onlineUsers => _onlineUsersUI;
  ValueNotifier<Map<num, Set<num>>> get onlineUsersByGroup =>
      _onlineUsersByGroupUI;
  ValueNotifier<String?> get lastReadMessageId => _lastReadMessageId;
  ValueNotifier<bool> get isTyping => _isTyping;
  ValueNotifier<Map<String, Set<String>>> get typingUsersByGroup =>
      _typingUsersByGroup;
  ValueNotifier<bool> get isConnected => _isConnected;
  ValueNotifier<String> get connectionStatus => _connectionStatus;
  ValueNotifier<CallData?> get incomingCall => _incomingCall;
  ValueNotifier<CallData?> get activeCall => _activeCall;
  ValueNotifier<bool> get isAudioMuted => _isAudioMuted;
  ValueNotifier<bool> get isVideoMuted => _isVideoMuted;
  ValueNotifier<bool> get isCallActive => _isCallActive;

  // Helper getters
  int get totalUnreadMessages {
    int total = 0;
    for (final set in _unreadMessagesUI.value.values) {
      total += set.length;
    }
    return total;
  }

  bool get isAuthenticated => _isAuthenticated;

  // Batch processing
  final List<Map<String, dynamic>> _messageBatch = [];
  Timer? _batchTimer;
  final Duration _batchDelay = const Duration(milliseconds: 100);
  final int _batchSize = 50;

  late CallKitIntegration callKitIntegration;
  late WebRTCManager _webrtcManager;
  num? _currentGroupId;
  int _reconnectAttempts = 0;

  bool _isAuthenticated = false;
  bool _isRinging = false;
  String? _userId;
  String? _userName;
  Timer? _tokenCheckTimer;
  String? _currentToken;
  bool _tokenMonitoringStarted = false;
  final Duration _tokenCheckInterval = const Duration(seconds: 2);
  WebRTCManager get webrtcManager => _webrtcManager;

  // Initialization state
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isConnecting = false;

  // Event handling
  final Map<String, Set<Function(dynamic)>> _eventHandlers = {};
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;
  final audio = SynthNotificationAudio();
  AudioSession? _audioSession;
  Timer? _reconnectTimer;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 1);

  // Typing management
  Timer? _typingTimeout;
  Timer? _typingDebounceTimer;
  final Map<String, DateTime> _lastTypingSent = {};

  // Track registered handlers for reconnection
  final Set<String> _registeredSocketEvents = {};
  bool _handlersRegisteredWithSocket = false;

  // Prevent duplicate handler setup and infinite loops
  bool _handlersSetup = false;
  bool _isProcessingChatInitialized = false;
  bool _hasRequestedInitialData = false;
  Timer? _chatInitializedDebounceTimer;
  Timer? _authDebounceTimer;
  String? _lastChatInitializedData;

  // CRITICAL FIX: Add tracking for processed messages to prevent stack overflow
  final Set<String> _processedMessageIds = {};
  final Set<String> _processingTempIds = {};
  final Map<String, DateTime> _lastEventTime = {};
  final Duration _eventDebounceTime = Duration(milliseconds: 100);
  bool _isEmittingMessage = false;
  bool _isProcessingNewMessage = false;

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    debugPrint('🚀 Initializing ChatWebSocketHandler...');

    try {
      await _initializeIsolate();

      _userId = await _getUserIdFromTokenManager();
      _userName = await _getUserName();

      // Clear existing handlers and tracking
      _eventHandlers.clear();
      _registeredSocketEvents.clear();
      _processedMessageIds.clear();
      _processingTempIds.clear();
      _lastEventTime.clear();

      _handlersRegisteredWithSocket = false;
      _handlersSetup = false;
      _isProcessingChatInitialized = false;
      _hasRequestedInitialData = false;
      _lastChatInitializedData = null;
      _isEmittingMessage = false;
      _isProcessingNewMessage = false;

      // Setup connection handlers DIRECTLY (not through on() method)
      _setupConnectionHandlers();

      // Setup chat handlers DIRECTLY (not through on() method)
      _setupChatHandlers();

      _startTokenMonitoring();
      await _checkAndConnect();
      await _initializeWebRTCManager();

      _isInitialized = true;
      debugPrint('✅ ChatWebSocketHandler initialized successfully');
    } catch (e, stack) {
      debugPrint('❌ Error initializing ChatWebSocketHandler: $e\n$stack');
    }
  }

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
    if (_isDisposed) return;

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
        case 'messages_list_processed':
          _handleMessagesListFromIsolate(message.data);
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
          _handleMessagesRetrievedFromIsolate(message.data);
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

  void _handleMessagesListFromIsolate(dynamic data) {
    try {
      debugPrint('📋 Handling messages_list from isolate: ${data.runtimeType}');
      
      // Data is a List of message objects from isolate
      if (data is! List<dynamic>) {
        debugPrint('❌ Expected List but got: ${data.runtimeType}');
        debugPrint('Data received: $data');
        return;
      }
      
      final messagesData = List<Map<String, dynamic>>.from(data);
      debugPrint('📋 Processing ${messagesData.length} messages from messages_list');
      
      final transformedMessages = <MessageGroup>[];
      final Map<num, List<Message>> groupedMessages = {};
      final newUnreadMessages = <num, Set<String>>{};

      for (final messageData in messagesData) {
        try {
          final message = Message.fromJson(messageData);
          final groupId = message.group;
          
          groupedMessages.putIfAbsent(groupId, () => []);
          groupedMessages[groupId]!.add(message);
          
          // Track unread messages
          if (message.sender.toString() != _userId &&
              message.type != 'system' &&
              message.messageType != 'SYSTEM' &&
              !_isMessageReadByUser(message, _userId)) {
            newUnreadMessages.putIfAbsent(groupId, () => <String>{});
            newUnreadMessages[groupId]!.add(message.id);
          }
        } catch (e) {
          debugPrint('❌ Error processing message in messages_list: $e');
          debugPrint('Problematic message data: $messageData');
        }
      }

      // Create MessageGroup objects
      groupedMessages.forEach((groupId, messages) {
        messages.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );

        transformedMessages.add(
          MessageGroup(groupId: groupId, messages: messages),
        );
      });

      // Update messages
      _messages.value = transformedMessages;

      // Update unread messages
      _unreadMessagesUI.value = newUnreadMessages;

      _emitEvent('messages_list', transformedMessages);
      _notifyListeners();
      
      debugPrint('✅ Successfully processed ${transformedMessages.length} groups with total ${transformedMessages.fold(0, (sum, group) => sum + group.messages.length)} messages');
      
    } catch (e) {
      debugPrint('❌ Error handling messages_list from isolate: $e');
      debugPrint('Data that caused error: $data');
      debugPrint('Stack trace: ${e.toString()}');
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

  // Direct socket handler registration with duplicate prevention
  void _registerSocketHandler(String event, Function(dynamic) handler) {
    if (_isDisposed) return;

    // Store in our handlers map
    _eventHandlers.putIfAbsent(event, () => {});
    final handlerSet = _eventHandlers[event]!;

    // Check if handler is already registered (use hash for better comparison)
    final handlerHash = identityHashCode(handler);
    final alreadyRegistered = handlerSet.any(
      (h) => identityHashCode(h) == handlerHash,
    );

    if (!alreadyRegistered) {
      handlerSet.add(handler);
      debugPrint('✅ Stored handler for event: $event');
    } else {
      debugPrint('⚠️ Handler already stored for event: $event');
    }

    // If socket is connected, register immediately
    if (socketService.socket != null && socketService.socket!.connected) {
      _registerHandlerWithSocket(event, handler);
    } else {
      debugPrint(
        '⏳ Socket not connected yet, will register handler for $event when connected',
      );
    }
  }

  void _registerHandlerWithSocket(String event, Function(dynamic) handler) {
    if (_isDisposed || socketService.socket == null) return;

    try {
      // Check if already registered with socket
      if (_registeredSocketEvents.contains(event)) {
        debugPrint('⚠️ Handler already registered with socket for: $event');
        return;
      }

      debugPrint('🔗 Registering socket handler for: $event');
      socketService.socket!.on(event, handler);
      _registeredSocketEvents.add(event);
    } catch (e) {
      debugPrint('❌ Error registering socket handler for $event: $e');
    }
  }

  // Event Management - PUBLIC API with duplicate prevention
  void on(String event, Function(dynamic) handler) {
    if (_isDisposed) return;

    debugPrint("📝 Public on() called for event: $event");

    _registerSocketHandler(event, handler);
  }

  void off(String event, Function(dynamic) handler) {
    if (_eventHandlers.containsKey(event)) {
      final handlerSet = _eventHandlers[event]!;
      final handlerHash = identityHashCode(handler);
      handlerSet.removeWhere((h) => identityHashCode(h) == handlerHash);

      if (handlerSet.isEmpty) {
        _eventHandlers.remove(event);
        _registeredSocketEvents.remove(event);
      }
    }
  }

  // Setup ALL chat handlers from React implementation - ONLY ONCE
  void _setupChatHandlers() {
    if (_handlersSetup) {
      debugPrint('⚠️ Chat handlers already setup, skipping');
      return;
    }

    debugPrint('🔄 Setting up chat handlers...');

    // Define handlers matching React implementation
    final handlerMap = <String, Function(dynamic)>{
      'chat_authenticated': (data) {
        debugPrint('✅ chat_authenticated received: $data');
        _isAuthenticated = true;
        _emitEvent('chat_authenticated', data);
      },

      // FIXED: Simplified chat_initialized handler
      'chat_initialized': (data) {
        debugPrint("✅ Chat initialized event received: $data");

        // Skip if we've already processed initialization
        if (_isAuthenticated && _hasRequestedInitialData) {
          debugPrint('⚠️ Already initialized, skipping');
          return;
        }

        // Debounce to prevent multiple executions
        if (_chatInitializedDebounceTimer != null) {
          _chatInitializedDebounceTimer!.cancel();
        }

        _chatInitializedDebounceTimer = Timer(
          const Duration(milliseconds: 500),
          () {
            if (_isDisposed) {
              debugPrint('⚠️ Handler disposed, skipping chat_initialized');
              return;
            }

            // Set authenticated flag
            _isAuthenticated = true;

            // Request data only once
            if (!_hasRequestedInitialData) {
              _hasRequestedInitialData = true;
              debugPrint('📡 Requesting initial data...');

              // Small delay to ensure everything is ready
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!_isDisposed && _isConnected.value) {
                  getMessages();
                  getOnlineUsers();
                }
              });
            }

            _emitEvent('chat_initialized', data);
          },
        );
      },

      'chat_joined': (data) {
        debugPrint('✅ chat_joined: $data');
        _emitEvent('chat_joined', data);
      },

      'chat_left': (data) {
        debugPrint('✅ chat_left: $data');
        _emitEvent('chat_left', data);
      },

      'group_joined': (data) {
        debugPrint('✅ group_joined: $data');
        _emitEvent('group_joined', data);
      },

      'groups_refreshed': (data) {
        debugPrint('✅ groups_refreshed: $data');
        _emitEvent('groups_refreshed', data);
      },

      'new_message': (data) {
        if (_isProcessingNewMessage) {
          debugPrint('⚠️ Already processing new_message, skipping');
          return;
        }

        debugPrint('📨 new_message received');

        // CRITICAL FIX: Prevent processing the same message multiple times
        final messageId = data['id']?.toString();
        final tempId = data['tempId']?.toString();

        if (messageId != null && _processedMessageIds.contains(messageId)) {
          debugPrint('⚠️ Skipping already processed message: $messageId');
          return;
        }

        if (tempId != null && _processingTempIds.contains(tempId)) {
          debugPrint('⚠️ Skipping own message with tempId: $tempId');
          return;
        }

        try {
          _isProcessingNewMessage = true;

          if (messageId != null) {
            _processedMessageIds.add(messageId);
            // Clean up old message IDs to prevent memory leak
            if (_processedMessageIds.length > 1000) {
              final oldest = _processedMessageIds.take(500).toList();
              _processedMessageIds.removeAll(oldest);
            }
          }

          _queueMessageForBatch(data);
        } finally {
          _isProcessingNewMessage = false;
        }
      },

      'reaction_added_success': (data) {
        debugPrint('👍 reaction_added_success: $data');
        _handleReactionReceived(data, true);
      },

      'reaction_removed_success': (data) {
        debugPrint('👎 reaction_removed_success: $data');
        _handleReactionReceived(data, false);
      },

      'message_sent': (data) {
        debugPrint('📤 message_sent: $data');

        // CRITICAL FIX: Mark tempId as processed to prevent new_message handler from processing it
        final tempId = data['tempId']?.toString();
        final messageId = data['messageId']?.toString();

        if (tempId != null) {
          _processingTempIds.add(tempId);
          // Remove after 5 seconds to prevent memory leak
          Future.delayed(Duration(seconds: 5), () {
            _processingTempIds.remove(tempId);
          });
        }

        if (messageId != null) {
          _processedMessageIds.add(messageId);
        }

        _emitEvent('message_sent', data);
      },

      'message_edited': (data) {
        debugPrint('✏️ message_edited: $data');
        // Send to isolate for processing
        _sendToIsolate(IsolateMessage(type: 'update_message', data: data));
        // Also update UI directly
        _updateSingleMessageUI(data);
        _emitEvent('message_edited', data);
      },

      'message_deleted': (data) {
        debugPrint('🗑️ message_deleted: $data');
        _handleMessageDeletedInUI(data);
      },

      'message_read': (data) {
        debugPrint('👁️ message_read: $data');
        _emitEvent('message_read', data);
      },

      'message_read_receipt': (data) {
        debugPrint('👁️✓ message_read_receipt: $data');
        _handleMessageReadReceipt(data);
      },

      'messages_list': (data) {
        debugPrint('📋 messages_list received: ${data.runtimeType}');
        
        // Handle different data types
        if (data is List<MessageGroup>) {
          // Convert MessageGroup instances to raw JSON
          debugPrint('📋 Converting MessageGroup list to JSON');
          final formattedData = data.map((group) => group.toJson()).toList();
          _sendToIsolate(IsolateMessage(type: 'messages_list', data: formattedData));
        } 
        else if (data is List<dynamic>) {
          // Data is already in the expected format: [{group: X, messages: [...]}]
          debugPrint('📋 Sending List data to isolate');
          _sendToIsolate(IsolateMessage(type: 'messages_list', data: data));
        } 
        else if (data is Map<String, dynamic>) {
          // Data is a Map with messages key
          debugPrint('📋 Converting Map to List format');
          final messagesData = data['messages'] ?? [];
          final groupId = data['groupId'];
          
          if (groupId != null && messagesData is List) {
            final formattedData = [{
              'group': groupId,
              'messages': messagesData
            }];
            _sendToIsolate(IsolateMessage(type: 'messages_list', data: formattedData));
          } else {
            debugPrint('❌ Invalid messages_list data format: $data');
          }
        } 
        else {
          debugPrint('❌ Unexpected messages_list data type: ${data.runtimeType}');
          debugPrint('Data: $data');
        }
      },

      'messages_read': (data) {
        debugPrint('📖 messages_read: $data');
        _handleMessagesRead(data);
      },

      'user_typing': (data) {
        debugPrint('⌨️ user_typing: $data');
        _sendToIsolate(IsolateMessage(type: 'process_typing_data', data: data));
        _handleTypingStart(data);
      },

      'user_stopped_typing': (data) {
        debugPrint('⏹️ user_stopped_typing: $data');
        _sendToIsolate(IsolateMessage(type: 'process_typing_data', data: data));
        _handleTypingStop(data);
      },

      'user_joined': (data) {
        debugPrint('👤 user_joined: $data');
        _emitEvent('user_joined', data);
        _emitEvent('group_update', {
          'type': 'user_joined',
          'groupId': data['groupId'],
          'data': data,
          'timestamp': data['timestamp'],
        });
      },

      'user_left': (data) {
        debugPrint('👋 user_left: $data');
        _emitEvent('user_left', data);
        _emitEvent('group_update', {
          'type': 'user_left',
          'groupId': data['groupId'],
          'data': data,
          'timestamp': data['timestamp'],
        });
      },

      'user_online': (data) {
        debugPrint('🟢 user_online: $data');
        _handleUserOnline(data);
        _emitEvent('user_online', data);
      },

      'user_offline': (data) {
        debugPrint('🔴 user_offline: $data');
        _handleUserOffline(data);
        _emitEvent('user_offline', data);
      },

      'online_users': (data) {
        debugPrint('👥 online_users: $data');
        _handleOnlineUsers(data);
      },

      'call_started': (data) {
        debugPrint('📞 call_started: $data');
        _sendToIsolate(
          IsolateMessage(type: 'process_call_data', data: data),
        ).then((_) {
          _handleCallStarted(data);
        });
      },

      'call_answered': (data) {
        debugPrint('📞 call_answered: $data');
        audio.stop();
        _emitEvent('call_answered', data);
      },

      'call_rejected': (data) {
        debugPrint('📞 call_rejected: $data');
        audio.stop();
        _emitEvent('call_rejected', data);
      },

      'call_ended': (data) {
        debugPrint('📞 call_ended: $data');
        audio.stop();
        _emitEvent('call_ended', data);
      },

      'user_joined_call': (data) {
        debugPrint('📞 user_joined_call: $data');
        _emitEvent('user_joined_call', data);
      },

      'user_left_call': (data) {
        debugPrint('📞 user_left_call: $data');
        _emitEvent('user_left_call', data);
      },

      // WebRTC events
      'webrtc_offer': (data) {
        debugPrint('📡 webrtc_offer: $data');
        _emitEvent('webrtc_offer', data);
      },

      'webrtc_answer': (data) {
        debugPrint('📡 webrtc_answer: $data');
        _emitEvent('webrtc_answer', data);
      },

      'webrtc_ice_candidate': (data) {
        debugPrint('📡 webrtc_ice_candidate: $data');
        _emitEvent('webrtc_ice_candidate', data);
      },

      // Error handling
      'error': (data) {
        debugPrint('❌ Chat error: $data');
        _emitEvent('error', data);
      },

      // Ping/pong
      'ping': (_) {
        debugPrint('🏓 ping received');
        emit('pong', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      },
    };

    // Register all handlers using direct registration
    handlerMap.forEach((event, handler) {
      _registerSocketHandler(event, handler);
    });

    _handlersSetup = true;
    debugPrint('✅ Setup ${handlerMap.length} chat handlers (only once)');
  }

  // Setup connection handlers directly
  void _setupConnectionHandlers() {
    debugPrint('🔄 Setting up connection handlers...');

    // Clear existing socket listeners
    if (socketService.socket != null) {
      socketService.socket!.clearListeners();
    }

    // Direct assignment to ensure they're always registered
    socketService.onConnected(_handleConnected);
    socketService.onDisconnected(_handleDisconnected);
    socketService.onError(_handleError);
    socketService.onConnecting(_handleConnecting);
    socketService.onReconnectAttempt(_handleReconnectAttempt);

    debugPrint('✅ Setup connection handlers');
  }

  // Register all handlers with socket when connected
  void _registerAllHandlersWithSocket() {
    if (_isDisposed || socketService.socket == null) return;

    debugPrint('🔗 Registering all handlers with socket...');

    // Clear any existing socket listeners first
    socketService.socket!.clearListeners();
    _registeredSocketEvents.clear();

    // Re-register all stored handlers
    _eventHandlers.forEach((event, handlers) {
      for (final handler in handlers) {
        try {
          debugPrint("  📝 Registering: $event");
          socketService.socket!.on(event, handler);
          _registeredSocketEvents.add(event);
        } catch (e) {
          debugPrint('❌ Error registering $event: $e');
        }
      }
    });

    _handlersRegisteredWithSocket = true;
    debugPrint('✅ Registered ${_eventHandlers.length} event types with socket');
  }

  // Connection Management
  Future<void> connect() async {
    if (_isDisposed || _isConnecting) return;

    _isConnecting = true;
    _cancelReconnect();

    final token = await tokenManager.getToken();
    if (token == null) {
      debugPrint('⚠️ Cannot connect: No token available');
      _isConnecting = false;
      return;
    }

    debugPrint('🔌 Connecting to chat socket...');

    try {
      await socketService.connect();
    } finally {
      _isConnecting = false;
    }
  }

  // Handle connected with proper handler registration
  void _handleConnected() {
    if (_isDisposed) return;

    debugPrint('🎉 Chat socket connected');
    _isConnected.value = true;
    _connectionStatus.value = 'connected';
    _reconnectAttempts = 0;

    // Reset initialization flags for new connection
    _isAuthenticated = false;
    _hasRequestedInitialData = false;

    // CRITICAL: Register all handlers with the socket
    _registerAllHandlersWithSocket();

    _processMessageQueue();
    _notifyListeners();
    _emitEvent('connected');
  }

  void _handleConnecting() {
    if (_isDisposed) return;

    debugPrint('🔄 Connecting to chat socket...');
    _connectionStatus.value = 'connecting';
    _notifyListeners();
  }

  void _handleDisconnected(String reason) {
    if (_isDisposed) return;

    debugPrint('🔌 Chat socket disconnected: $reason');
    _isConnected.value = false;
    _isAuthenticated = false;
    _connectionStatus.value = 'disconnected';
    _handlersRegisteredWithSocket = false;
    _hasRequestedInitialData = false;
    _notifyListeners();
    _emitEvent('disconnected', {'reason': reason});
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    if (_isDisposed) return;

    debugPrint('❌ Chat socket error: $error');
    _connectionStatus.value = 'disconnected';
    _notifyListeners();
    _emitEvent('error', {'error': error.toString()});
  }

  void _handleReconnectAttempt(int attempt) {
    if (_isDisposed) return;

    debugPrint('🔄 Chat socket reconnect attempt: $attempt');
    _connectionStatus.value = 'reconnecting';
    _reconnectAttempts = attempt;
    _notifyListeners();
    _emitEvent('reconnect_attempt', {'attempt': attempt});
  }

  // Presence handlers
  void _handleUserOnline(dynamic data) {
    final userId = data['userId']?.toString();
    if (userId != null) {
      final currentUsers = _onlineUsersUI.value.toSet();
      currentUsers.add(num.tryParse(userId) ?? 0);
      _onlineUsersUI.value = currentUsers;
    }

    final groupId = data['groupId'];
    if (groupId != null) {
      final currentMap = Map<num, Set<num>>.from(_onlineUsersByGroupUI.value);
      final groupSet = currentMap[groupId]?.toSet() ?? <num>{};
      if (userId != null) {
        groupSet.add(num.tryParse(userId) ?? 0);
      }
      currentMap[groupId] = groupSet;
      _onlineUsersByGroupUI.value = currentMap;
    }
  }

  void _handleUserOffline(dynamic data) {
    final userId = data['userId']?.toString();
    if (userId != null) {
      final currentUsers = _onlineUsersUI.value.toSet();
      currentUsers.remove(num.tryParse(userId) ?? 0);
      _onlineUsersUI.value = currentUsers;
    }

    final groupId = data['groupId'];
    if (groupId != null) {
      final currentMap = Map<num, Set<num>>.from(_onlineUsersByGroupUI.value);
      final groupSet = currentMap[groupId]?.toSet() ?? <num>{};
      if (userId != null) {
        groupSet.remove(num.tryParse(userId) ?? 0);
      }
      currentMap[groupId] = groupSet;
      _onlineUsersByGroupUI.value = currentMap;
    }
  }

  void _handleOnlineUsers(dynamic data) {
    final groups = data['groupIds'] as List<dynamic>? ?? [];
    final users = data['users'] as List<dynamic>? ?? [];
    final userIds = users.map((u) => num.tryParse(u.toString()) ?? 0).toSet();

    // Update global list
    _onlineUsersUI.value = userIds;

    // Update per-group lists
    final currentMap = Map<num, Set<num>>.from(_onlineUsersByGroupUI.value);
    for (final gid in groups) {
      final groupId = num.tryParse(gid.toString()) ?? 0;
      currentMap[groupId] = userIds;
    }
    _onlineUsersByGroupUI.value = currentMap;
  }

  // Typing handlers
  void _handleTypingStart(dynamic data) {
    final indicator = TypingIndicator.fromJson(data);
    final currentUserId = _userId;

    // Don't show our own typing indicator
    final isMeTyping = indicator.typingUsers.any(
      (user) => user.userId.toString() == currentUserId,
    );

    if (isMeTyping) {
      return;
    }

    final currentTypingData = Map<num, List<TypingUser>>.from(
      _typingDataUI.value,
    );
    final currentTypingUsers = currentTypingData[indicator.groupId] ?? [];

    final now = DateTime.now();
    final validCurrentTypingUsers = currentTypingUsers
        .where(
          (user) =>
              user.startedAt == null ||
              now.difference(user.startedAt!).inSeconds < 10,
        )
        .toList();

    final filteredTypingUsers = indicator.typingUsers
        .where((user) => user.userId.toString() != currentUserId)
        .toList();

    final mergedTypingUsers = [...validCurrentTypingUsers];
    for (final newUser in filteredTypingUsers) {
      final existingIndex = mergedTypingUsers.indexWhere(
        (u) => u.userId == newUser.userId,
      );
      if (existingIndex == -1) {
        mergedTypingUsers.add(newUser);
      } else {
        mergedTypingUsers[existingIndex] = newUser;
      }
    }

    final finalTypingUsers = mergedTypingUsers
        .where(
          (user) => indicator.typingUsers.any(
            (newUser) => newUser.userId == user.userId,
          ),
        )
        .toList();

    currentTypingData[indicator.groupId] = finalTypingUsers;
    _typingDataUI.value = currentTypingData;
  }

  void _handleTypingStop(dynamic data) {
    final indicator = TypingIndicator.fromJson(data);
    final currentTypingData = Map<num, List<TypingUser>>.from(
      _typingDataUI.value,
    );
    currentTypingData[indicator.groupId] = indicator.typingUsers;

    if (indicator.typingUsers.isEmpty) {
      currentTypingData.remove(indicator.groupId);
    }

    _typingDataUI.value = currentTypingData;
  }

  // Message handlers
  void _handleMessagesRead(dynamic data) {
    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);

    if (groupId != null && messageIds.isNotEmpty) {
      // Update messages in UI
      _messages.value = _messages.value.map((group) {
        if (group.groupId.toString() == groupId.toString()) {
          final updatedMessages = group.messages.map((msg) {
            if (messageIds.contains(msg.id)) {
              final readBy = List<dynamic>.from(msg.readBy ?? []);
              final userId = data['userId']?.toString();
              if (userId != null &&
                  !readBy.any(
                    (read) => read is Map
                        ? read['user']?.toString() == userId ||
                              read['userId']?.toString() == userId
                        : read.toString() == userId,
                  )) {
                readBy.add(userId);
              }

              return msg.copyWith(status: 'read', readBy: readBy);
            }
            return msg;
          }).toList();

          return MessageGroup(
            groupId: group.groupId,
            messages: updatedMessages,
          );
        }
        return group;
      }).toList();
    }
  }

  // FIXED: Handle null groupId in messages_retrieved
  void _handleMessagesRetrievedFromIsolate(dynamic data) {
    try {
      final groupId = data['groupId'];
      final messagesData = List<Map<String, dynamic>>.from(
        data['messages'] ?? [],
      );
      final hasNext = data['hasNext'] ?? false;

      // Handle null groupId case
      if (groupId == null) {
        debugPrint(
          '⚠️ groupId is null in messages_retrieved, using current group: $_currentGroupId',
        );
      }

      final effectiveGroupId = groupId ?? _currentGroupId;

      if (effectiveGroupId == null) {
        debugPrint('❌ Cannot process messages: no groupId available');
        return;
      }

      final messages = messagesData.map((m) => Message.fromJson(m)).toList();

      // Update UI
      final existingGroups = List<MessageGroup>.from(_messages.value);
      final groupIndex = existingGroups.indexWhere(
        (g) => g.groupId == effectiveGroupId,
      );

      if (groupIndex != -1) {
        final existingMessages = existingGroups[groupIndex].messages;
        final updatedMessages = [...existingMessages, ...messages]
          ..sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );
        existingGroups[groupIndex] = MessageGroup(
          groupId: effectiveGroupId,
          messages: updatedMessages,
        );
      } else {
        existingGroups.add(
          MessageGroup(groupId: effectiveGroupId, messages: messages),
        );
      }

      _messages.value = existingGroups;

      _emitEvent('messages_retrieved', {
        'groupId': effectiveGroupId,
        'messages': messages,
        'hasNext': hasNext,
      });
    } catch (e) {
      debugPrint('❌ Error handling messages retrieved: $e');
      debugPrint('Data that caused error: $data');
    }
  }

  void _handleMessageReadReceipt(dynamic data) {
    if (_isDisposed) return;

    try {
      final messageIds = List<String>.from(data['messageIds'] ?? []);
      final groupId = data['groupId'];
      final userId = data['userId']?.toString();

      if (groupId != null && messageIds.isNotEmpty) {
        _messages.value = _messages.value.map((group) {
          if (group.groupId.toString() == groupId.toString()) {
            final updatedMessages = group.messages.map((msg) {
              if (messageIds.contains(msg.id)) {
                final readBy = List<dynamic>.from(msg.readBy ?? []);
                if (!readBy.any(
                  (read) => read is Map
                      ? read['user']?.toString() == userId ||
                            read['userId']?.toString() == userId
                      : read.toString() == userId,
                )) {
                  readBy.add(userId ?? _userId);
                }

                return msg.copyWith(status: 'read', readBy: readBy);
              }
              return msg;
            }).toList();

            return MessageGroup(
              groupId: group.groupId,
              messages: updatedMessages,
            );
          }
          return group;
        }).toList();

        // Remove from unread messages
        final currentUnread = Map<num, Set<String>>.from(
          _unreadMessagesUI.value,
        );
        final groupUnread = currentUnread[groupId];
        if (groupUnread != null) {
          messageIds.forEach(groupUnread.remove);
          if (groupUnread.isEmpty) {
            currentUnread.remove(groupId);
          } else {
            currentUnread[groupId] = groupUnread;
          }
          _unreadMessagesUI.value = currentUnread;
        }
      }

      _emitEvent('message_read_receipt', data);
    } catch (e) {
      debugPrint('❌ Error handling message_read_receipt: $e');
    }
  }

  void _handleReactionReceived(dynamic data, bool isAdded) {
    if (_isDisposed) return;

    try {
      final emoji = data['emoji'] ?? data['reaction']?['emoji'];
      final userIdStr = (data['userId'] ?? data['reaction']?['userId'])
          ?.toString();
      final userName = data['userName'] ?? data['reaction']?['userName'];
      final messageId = data['messageId'];
      final groupId = data['groupId'];

      if (emoji == null ||
          userIdStr == null ||
          messageId == null ||
          groupId == null) {
        return;
      }

      _messages.value = _messages.value.map((group) {
        if (group.groupId.toString() == groupId.toString()) {
          final updatedMessages = group.messages.map((msg) {
            if (msg.id == messageId) {
              final reactions = List<Map<String, dynamic>>.from(
                msg.reactions ?? [],
              );
              final existingIndex = reactions.indexWhere(
                (r) => r['emoji'] == emoji,
              );

              final userObj = {
                'userId': num.tryParse(userIdStr),
                'userName': userName,
                'reactedAt': DateTime.now().toIso8601String(),
              };

              if (isAdded) {
                if (existingIndex != -1) {
                  final existing = reactions[existingIndex];
                  final users = List<dynamic>.from(existing['users'] ?? []);
                  final alreadyReacted = users.any(
                    (u) => u is Map
                        ? u['userId']?.toString() == userIdStr
                        : u.toString() == userIdStr,
                  );

                  if (!alreadyReacted) {
                    users.add(userObj);
                    reactions[existingIndex] = {
                      ...existing,
                      'users': users,
                      'count': users.length,
                    };
                  }
                } else {
                  reactions.add({
                    'emoji': emoji,
                    'users': [userObj],
                    'count': 1,
                  });
                }
              } else {
                if (existingIndex != -1) {
                  final existing = reactions[existingIndex];
                  var users = List<dynamic>.from(existing['users'] ?? []);
                  users = users
                      .where(
                        (u) => u is Map
                            ? u['userId']?.toString() != userIdStr
                            : u.toString() != userIdStr,
                      )
                      .toList();

                  if (users.isEmpty) {
                    reactions.removeAt(existingIndex);
                  } else {
                    reactions[existingIndex] = {
                      ...existing,
                      'users': users,
                      'count': users.length,
                    };
                  }
                }
              }

              return msg.copyWith(reactions: reactions);
            }
            return msg;
          }).toList();

          return MessageGroup(
            groupId: group.groupId,
            messages: updatedMessages,
          );
        }
        return group;
      }).toList();

      _emitEvent(
        isAdded ? 'reaction_added_success' : 'reaction_removed_success',
        data,
      );
    } catch (e) {
      debugPrint('❌ Error handling reaction: $e');
    }
  }

  // UI Update Methods
  void _updateMessagesFromIsolate(List<dynamic> messagesData) {
    if (_isDisposed || messagesData.isEmpty) return;

    final processedMessages = <Message>[];
    for (final messageData in messagesData) {
      try {
        final message = Message.fromJson(messageData);
        processedMessages.add(message);
        _addMessageToGroupUI(message.group, message);
      } catch (e) {
        debugPrint('❌ Error updating message from isolate: $e');
      }
    }

    _notifyListeners();
  }

  void _updateTypingFromIsolate(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final groupId = data['groupId'];
    final typingUsers = List<dynamic>.from(
      data['typingUsers'] ?? [],
    ).map((u) => TypingUser.fromJson(u)).toList();

    final currentData = Map<num, List<TypingUser>>.from(_typingDataUI.value);
    currentData[groupId] = typingUsers;
    _typingDataUI.value = currentData;

    _notifyListeners();
    _emitEvent('typing_update', data);
  }

  void _updatePresenceFromIsolate(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final groupId = data['groupId'];
    final users = List<num>.from(data['users'] ?? []);

    if (groupId != null) {
      final currentMap = Map<num, Set<num>>.from(_onlineUsersByGroupUI.value);
      currentMap[groupId] = users.toSet();
      _onlineUsersByGroupUI.value = currentMap;
    }

    final currentUsers = _onlineUsersUI.value.toSet();
    currentUsers.clear();
    currentUsers.addAll(users);
    _onlineUsersUI.value = currentUsers;

    _notifyListeners();
    _emitEvent('presence_update', data);
  }

  void _handleCallFromIsolate(Map<String, dynamic> data) {
    if (_isDisposed) return;

    try {
      final callData = CallData.fromJson(data);
      webrtcManager.setIncomingCall(callData);
      _emitEvent('call_processed', data);
    } catch (e) {
      debugPrint('❌ Error handling call from isolate: $e');
    }
  }

  void _updateUnreadFromIsolate(Map<String, dynamic> data) {
    if (_isDisposed) return;

    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);

    if (groupId != null) {
      final currentUnread = Map<num, Set<String>>.from(_unreadMessagesUI.value);
      final groupUnread = currentUnread[groupId];
      if (groupUnread != null) {
        messageIds.forEach(groupUnread.remove);
        if (groupUnread.isEmpty) {
          currentUnread.remove(groupId);
        } else {
          currentUnread[groupId] = groupUnread;
        }
        _unreadMessagesUI.value = currentUnread;
      }
    }

    _notifyListeners();
  }

  void _updateMessageFromIsolate(Map<String, dynamic> messageData) {
    if (_isDisposed) return;

    try {
      final message = Message.fromJson(messageData);
      final groupId = message.group;

      _messages.value = _messages.value.map((group) {
        if (group.groupId == groupId) {
          final messageIndex = group.messages.indexWhere(
            (m) => m.id == message.id,
          );

          if (messageIndex != -1) {
            final updatedMessages = List<Message>.from(group.messages);
            updatedMessages[messageIndex] = message;
            return MessageGroup(
              groupId: group.groupId,
              messages: updatedMessages,
            );
          }
        }
        return group;
      }).toList();

      _notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating single message from isolate: $e');
    }
  }

  void _updateSingleMessageUI(dynamic messageData) {
    if (_isDisposed) return;

    try {
      final message = Message.fromJson(messageData);

      _messages.value = _messages.value.map((group) {
        if (group.groupId == message.group) {
          final updatedMessages = group.messages.map((m) {
            if (m.id == message.id) {
              return message.copyWith(status: 'edited');
            }
            return m;
          }).toList();

          return MessageGroup(
            groupId: group.groupId,
            messages: updatedMessages,
          );
        }
        return group;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error updating single message: $e');
    }
  }

  // Add message to UI
  void _addMessageToGroupUI(num groupId, Message message) {
    if (_isDisposed) return;

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
      final currentUnread = Map<num, Set<String>>.from(_unreadMessagesUI.value);
      currentUnread.putIfAbsent(groupId, () => <String>{});
      currentUnread[groupId]!.add(message.id);
      _unreadMessagesUI.value = currentUnread;

      if (_currentGroupId == groupId) {
        markMessageAsRead(message.id, groupId);
      }
    }

    // Add to UI state
    final currentMessages = List<MessageGroup>.from(_messages.value);
    final groupIndex = currentMessages.indexWhere((g) => g.groupId == groupId);
    if (groupIndex == -1) {
      currentMessages.add(MessageGroup(groupId: groupId, messages: [message]));
    } else {
      final existingMessages = currentMessages[groupIndex].messages;
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

    _messages.value = currentMessages;
    _emitEvent('message_received', message);
  }

  void _handleMessageDeletedInUI(dynamic data) {
    if (_isDisposed) return;

    final serializableData = _makeSerializable(data);
    final messageId = serializableData['messageId'];
    final groupId = serializableData['groupId'];

    _messages.value = _messages.value.map((group) {
      if (group.groupId.toString() == groupId.toString()) {
        final updatedMessages = group.messages
            .where((m) => m.id != messageId)
            .toList();
        return MessageGroup(groupId: group.groupId, messages: updatedMessages);
      }
      return group;
    }).toList();

    _notifyListeners();
    _emitEvent('message_deleted', serializableData);
  }

  void _handleCallStarted(dynamic data) {
    if (_isDisposed) return;

    try {
      debugPrint('📞 Incoming call received: $data');
      final callData = CallData.fromJson(data);
      debugPrint('📞 Incoming call received: ${callData.toJson()}');
      webrtcManager.setIncomingCall(callData);
      _emitEvent('call_started', data);
    } on Exception catch (e) {
      debugPrint("Error handling call: ${e.toString()}");
    }
  }

  void _emitEvent(String event, [dynamic data]) {
    if (_isDisposed) return;

    // CRITICAL FIX: Add debouncing to prevent rapid event emission
    final now = DateTime.now();
    final lastEvent = _lastEventTime[event];

    if (lastEvent != null && now.difference(lastEvent) < _eventDebounceTime) {
      debugPrint('⚠️ Debouncing event: $event');
      return;
    }

    _lastEventTime[event] = now;

    final handlers = _eventHandlers[event];
    if (handlers != null) {
      for (final handler in handlers) {
        try {
          handler(data);
        } catch (e) {
          debugPrint('❌ Error in event handler for $event: $e');
        }
      }
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

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

    _cancelReconnect();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _chatInitializedDebounceTimer?.cancel();
    _authDebounceTimer?.cancel();
  }

  void _processMessageQueue() {
    if (_isDisposed || _isProcessingQueue || _messageQueue.isEmpty) return;

    _isProcessingQueue = true;

    try {
      while (_messageQueue.isNotEmpty) {
        final message = _messageQueue.removeAt(0);
        final event = message['event'];
        final data = message['data'];

        if (_isConnected.value) {
          emit(event, data ?? {});
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  void _queueMessage(String event, [dynamic data]) {
    if (_isDisposed) return;

    final serializableData = _makeSerializable(data);
    _messageQueue.add({'event': event, 'data': serializableData});
  }

  void emit(String event, [dynamic data]) {
    if (_isDisposed || !socketService.isConnected) {
      debugPrint('⚠️ Cannot emit $event: Socket not connected or disposed');
      _queueMessage(event, data);
      return;
    }

    try {
      // CRITICAL FIX: Prevent recursive emits when sending messages
      if (event == 'send_message') {
        if (_isEmittingMessage) {
          debugPrint('⚠️ Already emitting a message, skipping duplicate');
          return;
        }

        try {
          _isEmittingMessage = true;
          socketService.socket?.emit(event, _makeSerializable(data) ?? {});
          debugPrint('📤 Emitted event: $event');
        } finally {
          _isEmittingMessage = false;
        }
      } else {
        socketService.socket?.emit(event, _makeSerializable(data) ?? {});
        debugPrint('📤 Emitted event: $event');
      }
    } catch (e) {
      debugPrint('❌ Error emitting event $event: $e');
    }
  }

  // Batch Processing
  void _queueMessageForBatch(dynamic data) {
    if (_isDisposed) return;

    _messageBatch.add(_makeSerializable(data));

    if (_batchTimer == null || !_batchTimer!.isActive) {
      _batchTimer = Timer(_batchDelay, _processMessageBatch);
    }

    if (_messageBatch.length >= _batchSize) {
      _batchTimer?.cancel();
      _processMessageBatch();
    }
  }

  void _processMessageBatch() {
    if (_isDisposed || _messageBatch.isEmpty) return;

    final batch = List.from(_messageBatch);
    _messageBatch.clear();

    _sendToIsolate(IsolateMessage(type: 'process_message_batch', data: batch));
  }

  // Public API Methods
  // FIXED: Check if we have a current group before getting messages
  void getMessages({int page = 1, int limit = 50, String? before}) {
    if (!_isConnected.value) {
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
        data: {'page': page, 'limit': limit, 'before': before},
      ),
    );

    emit('get_messages', {'page': page, 'limit': limit, 'before': before});
  }

   Map<String, dynamic> sendMessage(SendMessageParams params) {
    final messageData = params.toJson();

    // CRITICAL FIX: Track tempId before sending to prevent duplicate processing
    final tempId = params.tempId;
    if (tempId != null) {
      _processingTempIds.add(tempId);
    }

    // Send to isolate for processing
    _sendToIsolate(IsolateMessage(type: 'update_message', data: messageData));

    if (!_isConnected.value) {
      _queueMessage('send_message', messageData);
      return messageData;
    }

    emit('send_message', messageData);
    return messageData;
  }
  
  // Map<String, dynamic> sendMessage(SendMessageParams params) {
  //   final messageData = params.toJson();

  //   // CRITICAL FIX: Track tempId before sending to prevent duplicate processing
  //   final tempId = params.tempId;
  //   if (tempId != null) {
  //     _processingTempIds.add(tempId);
  //   }

  //   // Send to isolate for processing
  //   _sendToIsolate(IsolateMessage(type: 'update_message', data: messageData));

  //   if (!_isConnected.value) {
  //     _queueMessage('send_message', messageData);
  //     return messageData;
  //   }

  //   emit('send_message', messageData);
  //   return messageData;
  // }

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

  void markMessageAsRead(String messageId, num groupId) {
    if (_isDisposed) return;

    // Update UI immediately
    final currentUnread = Map<num, Set<String>>.from(_unreadMessagesUI.value);
    final groupUnread = currentUnread[groupId];
    if (groupUnread != null) {
      groupUnread.remove(messageId);
      if (groupUnread.isEmpty) {
        currentUnread.remove(groupId);
      } else {
        currentUnread[groupId] = groupUnread;
      }
      _unreadMessagesUI.value = currentUnread;
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

    // Update local messages state
    _messages.value = _messages.value.map((group) {
      if (group.groupId == groupId) {
        final updatedMessages = group.messages.map((msg) {
          if (msg.id == messageId) {
            final readBy = List<dynamic>.from(msg.readBy ?? []);
            if (!readBy.any(
              (read) => read is Map
                  ? read['user']?.toString() == _userId ||
                        read['userId']?.toString() == _userId
                  : read.toString() == _userId,
            )) {
              readBy.add(_userId);
            }

            return msg.copyWith(status: 'read', readBy: readBy);
          }
          return msg;
        }).toList();

        return MessageGroup(groupId: group.groupId, messages: updatedMessages);
      }
      return group;
    }).toList();

    _lastReadMessageId.value = messageId;

    if (!_isConnected.value) {
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
    if (_isDisposed) return;

    if (!_isConnected.value) {
      _queueMessage('mark_messages_read', {
        'messageIds': messageIds,
        'groupId': groupId,
      });
      return;
    }

    // Update UI immediately
    final currentUnread = Map<num, Set<String>>.from(_unreadMessagesUI.value);
    final groupUnread = currentUnread[groupId];
    if (groupUnread != null) {
      messageIds.forEach(groupUnread.remove);
      if (groupUnread.isEmpty) {
        currentUnread.remove(groupId);
      } else {
        currentUnread[groupId] = groupUnread;
      }
      _unreadMessagesUI.value = currentUnread;
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

    // Update local messages
    _messages.value = _messages.value.map((group) {
      if (group.groupId == groupId) {
        final updatedMessages = group.messages.map((msg) {
          if (messageIds.contains(msg.id)) {
            final readBy = List<dynamic>.from(msg.readBy ?? []);
            if (!readBy.any(
              (read) => read is Map
                  ? read['user']?.toString() == _userId ||
                        read['userId']?.toString() == _userId
                  : read.toString() == _userId,
            )) {
              readBy.add(_userId);
            }

            return msg.copyWith(status: 'read', readBy: readBy);
          }
          return msg;
        }).toList();

        return MessageGroup(groupId: group.groupId, messages: updatedMessages);
      }
      return group;
    }).toList();

    if (messageIds.isNotEmpty) {
      _lastReadMessageId.value = messageIds.last;
    }

    emit('mark_messages_read', {
      'messageIds': messageIds,
      'groupId': groupId,
      'userId': _userId,
      'userName': _userName,
    });
  }

  void markAllGroupMessagesAsRead(num groupId) {
    if (!_isConnected.value) {
      _queueMessage('mark_group_read', {'groupId': groupId});
      return;
    }

    // Clear unread messages for this group
    final currentUnread = Map<num, Set<String>>.from(_unreadMessagesUI.value);
    currentUnread.remove(groupId);
    _unreadMessagesUI.value = currentUnread;

    // Update all messages in this group to read status
    _messages.value = _messages.value.map((group) {
      if (group.groupId == groupId) {
        final updatedMessages = group.messages.map((msg) {
          final readBy = List<dynamic>.from(msg.readBy ?? []);
          if (!readBy.any(
            (read) => read is Map
                ? read['user']?.toString() == _userId ||
                      read['userId']?.toString() == _userId
                : read.toString() == _userId,
          )) {
            readBy.add(_userId);
          }

          return msg.copyWith(status: 'read', readBy: readBy);
        }).toList();

        return MessageGroup(groupId: group.groupId, messages: updatedMessages);
      }
      return group;
    }).toList();

    emit('mark_group_read', {'groupId': groupId});
    _notifyListeners();
  }

  void markAllMessagesAsRead() {
    if (!_isConnected.value) {
      _queueMessage('mark_all_read', {});
      return;
    }

    // Clear all unread messages
    _unreadMessagesUI.value = {};

    // Update all messages to read status
    _messages.value = _messages.value.map((group) {
      final updatedMessages = group.messages.map((msg) {
        final readBy = List<dynamic>.from(msg.readBy ?? []);
        if (!readBy.any(
          (read) => read is Map
              ? read['user']?.toString() == _userId ||
                    read['userId']?.toString() == _userId
              : read.toString() == _userId,
        )) {
          readBy.add(_userId);
        }

        return msg.copyWith(status: 'read', readBy: readBy);
      }).toList();

      return MessageGroup(groupId: group.groupId, messages: updatedMessages);
    }).toList();

    emit('mark_all_read');
    _notifyListeners();
  }

  void addReaction(String messageId, String emoji, String groupId) {
    if (_isDisposed) return;

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

    if (!_isConnected.value) {
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

  void deleteMessage(String messageId, num groupId) {
    if (!_isConnected.value) {
      _queueMessage('delete_message', {
        'messageId': messageId,
        'groupId': groupId,
      });
      return;
    }

    emit('delete_message', {'messageId': messageId, 'groupId': groupId});
  }

  void editMessage(String messageId, num groupId, String content) {
    if (!_isConnected.value) {
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

  // Presence methods
  void getOnlineUsers({String? groupId}) {
    if (!_isConnected.value) {
      if (groupId != null) {
        _queueMessage('get_online_users', {'groupId': groupId});
      } else {
        _queueMessage('get_online_users', {});
      }
      return;
    }

    // Send cached data immediately for UI
    if (_onlineUsersByGroupUI.value.isNotEmpty ||
        _onlineUsersUI.value.isNotEmpty) {
      final cachedData = {
        'users': _onlineUsersUI.value.toList(),
        'groupUsers': Map.from(
          _onlineUsersByGroupUI.value,
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

  List<num> getOnlineUsersForGroup(dynamic groupId) {
    final groupKey = groupId;
    final users = _onlineUsersByGroupUI.value[groupKey];
    return users?.toList() ?? [];
  }

  int getOnlineCountForGroup(dynamic groupId) {
    final groupKey = groupId;
    final users = _onlineUsersByGroupUI.value[groupKey];
    return users?.length ?? 0;
  }

  // Typing methods
  void startTyping(String groupId) {
    if (!_isConnected.value) {
      _queueMessage('typing_start', {'groupId': groupId});
      return;
    }

    final now = DateTime.now();
    final lastSent = _lastTypingSent[groupId];
    if (lastSent != null && now.difference(lastSent).inSeconds < 1) {
      return; // Throttle to once per second
    }

    _lastTypingSent[groupId] = now;
    emit('typing_start', {'groupId': groupId});

    // Auto stop after 5 seconds if not called again
    if (_typingTimeout != null) {
      _typingTimeout!.cancel();
    }
    _typingTimeout = Timer(Duration(seconds: 5), () {
      stopTyping(groupId);
    });
  }

  void stopTyping(String groupId) {
    if (!_isConnected.value) {
      _queueMessage('typing_stop', {'groupId': groupId});
      return;
    }

    if (_typingTimeout != null) {
      _typingTimeout!.cancel();
      _typingTimeout = null;
    }

    _lastTypingSent.remove(groupId);
    emit('typing_stop', {'groupId': groupId});
  }

  // Typing helper methods
  List<TypingUser> getTypingUsers(num groupId) {
    return _typingDataUI.value[groupId] ?? [];
  }

  bool isUserTyping(num groupId, String userId) {
    final typers = getTypingUsers(groupId);
    return typers.any((user) => user.userId.toString() == userId);
  }

  String getTypingDisplayText(num groupId) {
    final typers = getTypingUsers(groupId);
    if (typers.isEmpty) {
      return '';
    }

    final names = typers.map((user) => user.userName).toList();
    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return '${names[0]}, ${names[1]} and ${names.length - 2} others are typing...';
    }
  }

  // Group management
  void joinGroup(num groupId) {
    _currentGroupId = groupId;
    if (!_isConnected.value) {
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
    if (!_isConnected.value) {
      _queueMessage('leave_chat', {'groupId': groupId});
      return;
    }
    emit('leave_chat', {'groupId': groupId});
  }

  void joinNewGroup(num groupId) {
    if (!_isConnected.value) {
      _queueMessage('join_new_group', {'groupId': groupId});
      return;
    }

    emit('join_new_group', {'groupId': groupId});
  }

  void refreshGroups() {
    if (!_isConnected.value) {
      _queueMessage('refresh_groups', {});
      return;
    }

    emit('refresh_groups');
  }

  // WebRTC methods
  Future<void> _initializeWebRTCManager() async {
    try {
      final userId = await _getUserIdFromTokenManager();
      final userName = await _getUserName();

      _webrtcManager = WebRTCManager();
      _webrtcManager.initialize(
        this,
        userId != null ? int.tryParse(userId) ?? 1 : 1,
        userName ?? 'User',
      );

      callKitIntegration = CallKitIntegration();
      await callKitIntegration.initialize(_webrtcManager);

      _webrtcManager.onIncomingCall = (callData) {
        debugPrint("📨 Incoming call received via WebRTC");
        audio.play(SynthSoundType.ringtone);
        callKitIntegration.handleIncomingCallFromWebRTC(callData);
      };

      _webrtcManager.onCallStarted = (callData) {
        debugPrint('📞 Call started via WebRTC');
        _activeCall.value = callData;
        _isCallActive.value = true;
      };

      _webrtcManager.onCallEnded = (callData) {
        debugPrint('📞 Call ended via WebRTC');
        audio.stop();
        _activeCall.value = null;
        _isCallActive.value = false;
        _incomingCall.value = null;
      };

      _webrtcManager.onAudioMuted = (isMuted) {
        _isAudioMuted.value = isMuted;
      };

      _webrtcManager.onVideoMuted = (isMuted) {
        _isVideoMuted.value = isMuted;
      };

      debugPrint('✅ WebRTC Manager initialized');
    } catch (e, stack) {
      debugPrint('❌ Error initializing WebRTC Manager: $e\n$stack');
    }
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
      _activeCall.value = callData;
      _isCallActive.value = true;
    } catch (e) {
      debugPrint('❌ Error joining WebRTC call: $e');
      rethrow;
    }
  }

  void endWebRTCCall() {
    _webrtcManager.endCall();
    debugPrint('✅ Ended WebRTC call');
    _activeCall.value = null;
    _isCallActive.value = false;
  }

  void rejectWebRTCCall() {
    _webrtcManager.rejectCall();
    debugPrint('✅ Rejected WebRTC call');
    _incomingCall.value = null;
  }

  void sendWebRTCOffer(Map<String, dynamic> data) {
    emit('webrtc_offer', _makeSerializable(data));
  }

  void sendWebRTCAnswer(Map<String, dynamic> data) {
    emit('webrtc_answer', _makeSerializable(data));
  }

  void sendWebRTCICECandidate(Map<String, dynamic> data) {
    emit('webrtc_ice_candidate', _makeSerializable(data));
  }

  // File upload (simplified)
  Future<String> uploadFile(File file, String groupId) async {
    // Implement actual file upload here
    throw UnimplementedError('File upload not implemented');
  }

  // Helper methods
  dynamic _makeSerializable(dynamic data) {
    if (data == null) return null;
    if (data is Map ||
        data is List ||
        data is String ||
        data is num ||
        data is bool) {
      return data;
    }

    try {
      if (data is TypingIndicator) return data.toJson();
      if (data is Message) return data.toJson();
      if (data is CallData) return data.toJson();
      if (data is MessageGroup) return (data as MessageGroup).toJson();
      if (data is TypingUser) return data.toJson();
      if (data is SendMessageParams) return data.toJson();
      return {};
    } catch (e) {
      debugPrint('❌ Warning: Could not serialize data: $e');
      return {};
    }
  }

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
    return 'User'; // Implement actual user name retrieval
  }

  // Token Management
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
    _typingDataUI.value.clear();
    _unreadMessagesUI.value.clear();
    _onlineUsersUI.value.clear();
    _onlineUsersByGroupUI.value.clear();
    _lastReadMessageId.value = null;
    _hasRequestedInitialData = false;
    _lastChatInitializedData = null;
    _processedMessageIds.clear();
    _processingTempIds.clear();
    _notifyListeners();
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

  void disconnect() {
    _cancelReconnect();
    debugPrint('🔌 Disconnecting from chat socket...');
    socketService.disconnect();
    _isConnected.value = false;
    _isAuthenticated = false;
    _connectionStatus.value = 'disconnected';
    _handlersRegisteredWithSocket = false;
    _hasRequestedInitialData = false;
    _lastChatInitializedData = null;
    _notifyListeners();
  }

  void reconnect() {
    _cancelReconnect();
    debugPrint('🔄 Reconnecting chat socket...');
    socketService.reconnect();
  }

  void _notifyListeners() {
    if (_isDisposed || !hasListeners) return;
    notifyListeners();
  }

  // Cleanup
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isInitialized = false;

    debugPrint('🧹 Disposing ChatWebSocketHandler...');

    // Clear singleton reference
    if (_instance == this) {
      _instance = null;
    }

    // Shutdown isolate
    try {
      if (_isolateSendPort != null) {
        _sendToIsolate(IsolateMessage(type: 'shutdown'));
      }
      _isolate?.kill(priority: Isolate.immediate);
      _isolateReceivePort?.close();
    } catch (e) {
      debugPrint('❌ Error shutting down isolate: $e');
    }

    _stopTokenMonitoring();
    _cancelReconnect();
    audio.stop();

    // Clear all handlers
    _eventHandlers.clear();
    _messageQueue.clear();
    _processedMessageIds.clear();
    _processingTempIds.clear();

    socketService.dispose();
    _batchTimer?.cancel();
    _typingTimeout?.cancel();
    _typingDebounceTimer?.cancel();
    _chatInitializedDebounceTimer?.cancel();
    _authDebounceTimer?.cancel();
    _clearChatData();

    super.dispose();
  }

  // Utility methods
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isConnected.value && _isAuthenticated) {
      return true;
    }

    return Completer<bool>().future.timeout(timeout, onTimeout: () => false);
  }

  Future<bool> healthCheck() async {
    if (!_isConnected.value) {
      return false;
    }

    return Completer<bool>().future.timeout(
      Duration(seconds: 3),
      onTimeout: () => false,
    );
  }

  // Audio generation (optional)
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