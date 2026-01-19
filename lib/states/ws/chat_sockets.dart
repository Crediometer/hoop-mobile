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
import 'package:hoop/main.dart';
import 'package:hoop/screens/calls/call_screen.dart';
import 'package:hoop/services/audio/SynthNotificationAudio.dart';
import 'package:hoop/services/callkit_integration.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:hoop/states/onesignal_state.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:vibration/vibration.dart';

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
      case 'initialize':
        _initialize();
        break;
    }
  }

  void _initialize() {
    debugPrint('🔄 ChatIsolateWorker initialized');
  }

  void _processMessagesList(dynamic data) {
    try {
      if (data is! List<dynamic>) {
        debugPrint('❌ Expected List in isolate but got: ${data.runtimeType}');
        _sendPort.send(
          IsolateMessage(type: 'messages_list_processed', data: []),
        );
        return;
      }

      debugPrint(
        '📝 messages_list data is a List of ${data.length} items in isolate',
      );

      final allMessages = <Map<String, dynamic>>[];

      if (data.isEmpty) {
        debugPrint('⚠️ Empty messages_list received in isolate');
        _sendPort.send(
          IsolateMessage(type: 'messages_list_processed', data: []),
        );
        return;
      }

      final firstItem = data[0];

      // Strategy 1: List of groups with messages format: [{group: X, messages: [...]}]
      if (firstItem is Map &&
          (firstItem.containsKey('group') ||
              firstItem.containsKey('groupId'))) {
        debugPrint('📝 Processing as list of groups with messages');
        _processGroupsFormat(data, allMessages);
      }
      // Strategy 2: Direct list of message objects
      else if (firstItem is Map && firstItem.containsKey('id')) {
        debugPrint('📝 Processing as list of message objects');
        _processMessagesFormat(data, allMessages);
      }
      // Strategy 3: Complex nested format (server format)
      else if (firstItem is Map && firstItem.containsKey('groups')) {
        debugPrint('📝 Processing as server groups format');
        _processServerGroupsFormat(data, allMessages);
      }
      // Strategy 4: Try generic parsing
      else {
        debugPrint('📝 Trying generic parsing for unknown format');
        _processGenericFormat(data, allMessages);
      }

      debugPrint('📝 Processed ${allMessages.length} messages in isolate');

      // Sort all groups by timestamp
      _messages.forEach((groupId, messages) {
        messages.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );
      });

      _sendPort.send(
        IsolateMessage(type: 'messages_list_processed', data: allMessages),
      );
    } catch (e) {
      debugPrint('❌ Error processing messages_list in isolate: $e');
      debugPrint('Stack trace: ${e.toString()}');
      // Send empty list to prevent UI freeze
      _sendPort.send(IsolateMessage(type: 'messages_list_processed', data: []));
    }
  }

  void _processGroupsFormat(
    List<dynamic> data,
    List<Map<String, dynamic>> allMessages,
  ) {
    for (final groupData in data) {
      try {
        final groupMap = Map<String, dynamic>.from(groupData);
        final groupId = groupMap['group'] ?? groupMap['groupId'];

        // FIXED: Better handling of messages extraction
        dynamic messagesRaw = groupMap['messages'];
        List<dynamic> messagesData = [];

        if (messagesRaw is List) {
          messagesData = messagesRaw;
        } else if (messagesRaw != null) {
          debugPrint(
            '⚠️ messagesRaw is not List: ${messagesRaw.runtimeType}, value: $messagesRaw',
          );
          // Try to convert if it's a String that might be JSON
          if (messagesRaw is String) {
            try {
              final parsed = jsonDecode(messagesRaw);
              if (parsed is List) {
                messagesData = parsed;
              }
            } catch (e) {
              debugPrint('❌ Failed to parse messages as JSON: $e');
            }
          }
        }

        if (groupId == null) {
          debugPrint('⚠️ Skipping group with null ID');
          continue;
        }

        debugPrint(
          '📝 Processing group $groupId with ${messagesData.length} messages',
        );

        _messages.putIfAbsent(groupId, () => []);

        for (final messageData in messagesData) {
          try {
            final messageMap = Map<String, dynamic>.from(messageData);
            // Ensure message has groupId
            if (!messageMap.containsKey('group') &&
                !messageMap.containsKey('groupId')) {
              messageMap['group'] = groupId;
            }

            final message = Message.fromJson(messageMap);
            final exists = _messages[groupId]!.any((m) => m.id == message.id);

            if (!exists) {
              _messages[groupId]!.add(message);
              allMessages.add(message.toJson());

              // Track unread messages
              _trackUnreadMessage(message);
            } else {
              debugPrint(
                '⚠️ Message ${message.id} already exists in group $groupId',
              );
            }
          } catch (e) {
            debugPrint('❌ Error processing message in group $groupId: $e');
            debugPrint('Problematic message data: $messageData');
          }
        }
      } catch (e) {
        debugPrint('❌ Error processing group data: $e');
      }
    }
  }

  void _processMessagesFormat(
    List<dynamic> data,
    List<Map<String, dynamic>> allMessages,
  ) {
    for (final messageData in data) {
      try {
        final message = Message.fromJson(messageData);
        final groupId = message.group;

        if (groupId == null) {
          debugPrint('⚠️ Skipping message with null group ID: ${message.id}');
          continue;
        }

        _messages.putIfAbsent(groupId, () => []);

        final exists = _messages[groupId]!.any((m) => m.id == message.id);
        if (!exists) {
          _messages[groupId]!.add(message);
          allMessages.add(message.toJson());

          // Track unread messages
          _trackUnreadMessage(message);
        }
      } catch (e) {
        debugPrint('❌ Error processing message object: $e');
        debugPrint('Problematic message data: $messageData');
      }
    }
  }

  void _processServerGroupsFormat(
    List<dynamic> data,
    List<Map<String, dynamic>> allMessages,
  ) {
    for (final item in data) {
      try {
        final itemMap = Map<String, dynamic>.from(item);
        final groups = itemMap['groups'] as Map<String, dynamic>? ?? {};

        groups.forEach((groupIdStr, groupData) {
          try {
            final groupId = num.tryParse(groupIdStr) ?? 0;
            if (groupId == 0) {
              debugPrint('⚠️ Invalid group ID: $groupIdStr');
              return;
            }

            if (groupData is! List) {
              debugPrint(
                '⚠️ groupData is not a List for group $groupId, type: ${groupData.runtimeType}',
              );
              return;
            }

            debugPrint(
              '📝 Processing server group $groupId with ${groupData.length} messages',
            );

            _messages.putIfAbsent(groupId, () => []);

            for (final messageData in groupData) {
              try {
                final messageMap = Map<String, dynamic>.from(messageData);
                // Ensure message has groupId
                if (!messageMap.containsKey('group') &&
                    !messageMap.containsKey('groupId')) {
                  messageMap['group'] = groupId;
                }

                final message = Message.fromJson(messageMap);
                final exists = _messages[groupId]!.any(
                  (m) => m.id == message.id,
                );

                if (!exists) {
                  _messages[groupId]!.add(message);
                  allMessages.add(message.toJson());

                  // Track unread messages
                  _trackUnreadMessage(message);
                }
              } catch (e) {
                debugPrint(
                  '❌ Error processing message in server group $groupId: $e',
                );
              }
            }
          } catch (e) {
            debugPrint('❌ Error processing server group $groupIdStr: $e');
          }
        });
      } catch (e) {
        debugPrint('❌ Error processing server format item: $e');
      }
    }
  }

  void _processGenericFormat(
    List<dynamic> data,
    List<Map<String, dynamic>> allMessages,
  ) {
    debugPrint('🔍 First item in generic format: ${data[0]}');
    debugPrint('🔍 First item type: ${data[0].runtimeType}');

    if (data[0] is Map) {
      final firstMap = Map<String, dynamic>.from(data[0]);
      debugPrint('🔍 First item keys: ${firstMap.keys}');
    }

    for (final item in data) {
      if (item is Map) {
        try {
          final itemMap = Map<String, dynamic>.from(item);

          // Check if this looks like a message
          if (itemMap.containsKey('id') &&
              (itemMap.containsKey('content') ||
                  itemMap.containsKey('message'))) {
            // Try to extract groupId
            num? groupId;
            if (itemMap.containsKey('group')) {
              groupId = itemMap['group'] is num
                  ? itemMap['group']
                  : num.tryParse(itemMap['group'].toString());
            } else if (itemMap.containsKey('groupId')) {
              groupId = itemMap['groupId'] is num
                  ? itemMap['groupId']
                  : num.tryParse(itemMap['groupId'].toString());
            }

            if (groupId == null) {
              debugPrint('⚠️ Skipping message without group ID');
              continue;
            }

            final message = Message.fromJson(itemMap);
            _messages.putIfAbsent(groupId, () => []);

            final exists = _messages[groupId]!.any((m) => m.id == message.id);
            if (!exists) {
              _messages[groupId]!.add(message);
              allMessages.add(message.toJson());

              // Track unread messages
              _trackUnreadMessage(message);
            }
          }
        } catch (e) {
          debugPrint('❌ Error in generic parsing: $e');
          continue;
        }
      }
    }
  }

  void _trackUnreadMessage(Message message) {
    // Note: We don't have userId in isolate, so we can't determine if message is unread
    // This will be handled in the main thread
    debugPrint('📝 Tracked message ${message.id} in group ${message.group}');
  }

  void _processMessageBatch(List<dynamic> messages) {
    final processed = <Map<String, dynamic>>[];

    for (final messageData in messages) {
      try {
        final message = Message.fromJson(messageData);
        final groupId = message.group;

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
      final indicator = TypingIndicator.fromJson({
        ...data,
        'groupId': num.parse(data['groupId']),
      });
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
              ?.map((u) {
                if (u is num) return u;
                if (u is String) return num.tryParse(u) ?? 0;
                if (u is int) return u as num;
                return 0;
              })
              .where((id) => id > 0)
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
    try {
      final groupId = params['groupId'];
      final page = params['page'] ?? 1;
      final limit = params['limit'] ?? 50;

      final messages = _messages[groupId] ?? [];
      final start = (page - 1) * limit;
      final end = start + limit;

      final safeStart = start.clamp(0, messages.length);
      final safeEnd = end.clamp(0, messages.length);

      final paginated = messages.sublist(safeStart, safeEnd);

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
    } catch (e) {
      debugPrint('❌ Error in _getMessages: $e');
      _sendPort.send(
        IsolateMessage(
          type: 'messages_retrieved',
          data: {
            'groupId': null,
            'messages': [],
            'page': 1,
            'total': 0,
            'hasNext': false,
          },
        ),
      );
    }
  }

  void _markMessagesRead(Map<String, dynamic> data) {
    try {
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
    } catch (e) {
      debugPrint('❌ Error in _markMessagesRead: $e');
    }
  }

  void _addReaction(Map<String, dynamic> data) {
    try {
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
            IsolateMessage(
              type: 'reaction_added',
              data: updatedMessage.toJson(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _addReaction: $e');
    }
  }

  void _updateMessage(Map<String, dynamic> data) {
    try {
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
    } catch (e) {
      debugPrint('❌ Error in _updateMessage: $e');
    }
  }

  void _shutdown() {
    _messages.clear();
    _typingData.clear();
    _unreadMessages.clear();
    _onlineUsers.clear();
    _onlineUsersByGroup.clear();
    debugPrint('🔄 ChatIsolateWorker shutdown complete');
  }
}

class ChatWebSocketHandler with ChangeNotifier {
  final BaseWebSocketService socketService = BaseWebSocketService(
    namespace: '/group-chat',
  );
  final TokenManager tokenManager = TokenManager.instance;

  static ChatWebSocketHandler? _instance;

  factory ChatWebSocketHandler() {
    return _instance ??= ChatWebSocketHandler._internal();
  }

  ChatWebSocketHandler._internal();
  final OneSignalService oneSignalService = OneSignalService.instance;

  // Isolate Management
  Isolate? _isolate;
  ReceivePort? _isolateReceivePort;
  SendPort? _isolateSendPort;
  bool _isolateInitialized = false;
  final Map<String, Completer<dynamic>> _isolateCompleters = {};
  int _isolateRequestId = 0;

  // UI State
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

  // Getters
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

  // Track registered handlers
  final Set<String> _registeredSocketEvents = {};
  bool _handlersRegisteredWithSocket = false;

  // Prevent duplicate handler setup
  bool _handlersSetup = false;
  bool _isProcessingChatInitialized = false;
  bool _hasRequestedInitialData = false;
  Timer? _chatInitializedDebounceTimer;
  Timer? _authDebounceTimer;
  String? _lastChatInitializedData;

  // Tracking for processed messages
  final Set<String> _processedMessageIds = {};
  final Set<String> _processingTempIds = {};
  final Map<String, DateTime> _lastEventTime = {};
  final Duration _eventDebounceTime = Duration(milliseconds: 100);
  bool _isEmittingMessage = false;
  bool _isProcessingNewMessage = false;

  // Current user groups
  final Set<num> _currentGroups = {};

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    debugPrint('🚀 Initializing ChatWebSocketHandler...');

    try {
      await _initializeIsolate();

      _userId = await _getUserIdFromTokenManager();
      _userName = await _getUserName();

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

      _setupConnectionHandlers();
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

      if (data is! List<dynamic>) {
        debugPrint('❌ Expected List but got: ${data.runtimeType}');
        return;
      }

      final messagesData = List<Map<String, dynamic>>.from(data);
      debugPrint(
        '📋 Processing ${messagesData.length} messages from messages_list',
      );

      // CRITICAL FIX: If no messages were processed in isolate, skip UI update
      if (messagesData.isEmpty) {
        debugPrint(
          '⚠️ No messages to process from isolate, skipping UI update',
        );
        return;
      }

      final Map<num, List<Message>> groupedMessages = {};
      final Map<num, Set<String>> newUnreadMessages = {};

      // Process all messages
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
      final List<MessageGroup> transformedMessages = [];
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

      // Update UI state - IMPORTANT: Assign new value to trigger listeners
      _messages.value = transformedMessages;
      _unreadMessagesUI.value = newUnreadMessages;

      _emitEvent('messages_list', transformedMessages);
      notifyListeners();

      debugPrint(
        '✅ Successfully processed ${transformedMessages.length} groups with total ${transformedMessages.fold(0, (sum, group) => sum + group.messages.length)} messages',
      );
    } catch (e) {
      debugPrint('❌ Error handling messages_list from isolate: $e');
      debugPrint('Data that caused error: $data');
    }
  }

  // Update UI directly without isolate for immediate display
  void _updateMessagesDirectly(List<MessageGroup> messageGroups) {
    try {
      if (_isDisposed || messageGroups.isEmpty) {
        debugPrint('⚠️ Skipping direct UI update: empty or disposed');
        return;
      }

      debugPrint('🔄 Updating UI directly with ${messageGroups.length} groups');

      // Check if we actually have messages
      int totalMessages = 0;
      for (final group in messageGroups) {
        totalMessages += group.messages.length;
      }

      if (totalMessages == 0) {
        debugPrint('⚠️ No messages in groups, skipping UI update');
        return;
      }

      debugPrint('📊 Total messages to display: $totalMessages');

      // Create a map to merge with existing messages
      final Map<num, List<Message>> newGroups = {};

      for (final group in messageGroups) {
        newGroups[group.groupId] = List<Message>.from(group.messages);
      }

      // Merge with existing messages
      final List<MessageGroup> updatedGroups = [];

      // First, update existing groups
      for (final existingGroup in _messages.value) {
        if (newGroups.containsKey(existingGroup.groupId)) {
          // Merge messages
          final existingMessages = List<Message>.from(existingGroup.messages);
          final newMessages = newGroups[existingGroup.groupId]!;

          // Add only new messages that don't exist
          for (final newMessage in newMessages) {
            if (!existingMessages.any((m) => m.id == newMessage.id)) {
              existingMessages.add(newMessage);
            }
          }

          // Sort by date
          existingMessages.sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );

          updatedGroups.add(
            MessageGroup(
              groupId: existingGroup.groupId,
              messages: existingMessages,
            ),
          );

          newGroups.remove(existingGroup.groupId);
        } else {
          updatedGroups.add(existingGroup);
        }
      }

      // Add new groups that didn't exist before
      newGroups.forEach((groupId, messages) {
        messages.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );

        updatedGroups.add(MessageGroup(groupId: groupId, messages: messages));
      });

      // Update UI
      _messages.value = updatedGroups;
      notifyListeners();

      debugPrint(
        '✅ Direct UI update completed with ${updatedGroups.length} groups, ${updatedGroups.fold(0, (sum, group) => sum + group.messages.length)} total messages',
      );
    } catch (e) {
      debugPrint('❌ Error in direct UI update: $e');
    }
  }

  // Helper method to process and update UI messages
  void _processAndUpdateUIMessages(List<Map<String, dynamic>> messagesData) {
    try {
      final Map<num, List<Message>> groupedMessages = {};

      for (final messageData in messagesData) {
        try {
          final message = Message.fromJson(messageData);
          final groupId = message.group;

          groupedMessages.putIfAbsent(groupId, () => []);
          groupedMessages[groupId]!.add(message);
        } catch (e) {
          debugPrint('❌ Error creating message: $e');
          debugPrint('Problematic message data: $messageData');
        }
      }

      // Create MessageGroup objects
      final List<MessageGroup> messageGroups = [];
      groupedMessages.forEach((groupId, messages) {
        messages.sort(
          (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          ),
        );

        messageGroups.add(MessageGroup(groupId: groupId, messages: messages));
      });

      debugPrint(
        '🔄 Created ${messageGroups.length} groups from ${messagesData.length} messages',
      );

      // Update UI
      _updateMessagesDirectly(messageGroups);
    } catch (e) {
      debugPrint('❌ Error in _processAndUpdateUIMessages: $e');
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

  // Setup chat handlers - FIXED VERSION
  void _setupChatHandlers() {
    if (_handlersSetup) {
      debugPrint('⚠️ Chat handlers already setup, skipping');
      return;
    }

    debugPrint('🔄 Setting up chat handlers...');

    final handlerMap = <String, Function(dynamic)>{
      'chat_authenticated': (data) {
        debugPrint('✅ chat_authenticated received: $data');
        _isAuthenticated = true;
        _emitEvent('chat_authenticated', data);
      },

      'chat_initialized': (data) {
        debugPrint("✅ Chat initialized event received: $data");

        if (_isAuthenticated && _hasRequestedInitialData) {
          debugPrint('⚠️ Already initialized, skipping');
          return;
        }

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

            _isAuthenticated = true;
            _handleGroupsFromChatInitialized(data);

            if (!_hasRequestedInitialData) {
              _hasRequestedInitialData = true;
              debugPrint('📡 Requesting initial data...');

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

      // FIXED: messages_list handler with proper data structure handling
      'messages_list': (data) {
        debugPrint('📋 messages_list received: ${data.runtimeType}');

        // Log the actual data structure for debugging
        if (data is List && data.isNotEmpty) {
          debugPrint(
            '📋 messages_list data preview: ${data.toString().substring(0, min(200, data.toString().length))}...',
          );
          debugPrint('🔍 Full structure inspection:');
          for (int i = 0; i < min(3, data.length); i++) {
            debugPrint('🔍 Item $i type: ${data[i].runtimeType}');
            if (data[i] is Map) {
              final map = Map<String, dynamic>.from(data[i]);
              debugPrint('🔍 Item $i keys: ${map.keys}');
              if (map.containsKey('messages')) {
                debugPrint('🔍 messages type: ${map['messages'].runtimeType}');
                debugPrint(
                  '🔍 messages length: ${map['messages'] is List ? (map['messages'] as List).length : 'N/A'}',
                );
              }
            }
          }
        }

        // Handle different data types
        if (data is List<MessageGroup>) {
          // This should be from our direct update, not from server
          debugPrint(
            '📋 Received MessageGroup list from local update, skipping isolate processing',
          );
          return;
        } else if (data is List<dynamic>) {
          debugPrint(
            '📋 Sending List data to isolate with ${data.length} items',
          );

          if (data.isEmpty) {
            debugPrint('⚠️ Empty messages_list received from server');
            return;
          }

          // Check what format the data is in by examining the first item
          final firstItem = data[0];

          if (firstItem is Map<String, dynamic>) {
            debugPrint('📋 First item keys: ${firstItem.keys}');

            // Check for the actual server format based on your logs
            if (firstItem.containsKey('groups')) {
              debugPrint(
                '📋 Detected server groups format with groups: ${firstItem['groups'].runtimeType}',
              );

              // Extract messages from the complex server format
              final allMessages = <Map<String, dynamic>>[];
              final groups = firstItem['groups'] as Map<String, dynamic>? ?? {};

              debugPrint('📋 Processing ${groups.length} groups from server');

              groups.forEach((groupIdStr, groupData) {
                try {
                  final groupId = num.tryParse(groupIdStr) ?? 0;
                  if (groupId == 0) return;

                  debugPrint(
                    '📋 Processing group $groupId with data: ${groupData.runtimeType}',
                  );

                  if (groupData is List) {
                    debugPrint(
                      '📋 Group $groupId has ${groupData.length} messages',
                    );

                    for (final messageData in groupData) {
                      try {
                        final messageMap = Map<String, dynamic>.from(
                          messageData,
                        );
                        // Ensure each message has the groupId
                        messageMap['group'] = groupId;
                        allMessages.add(messageMap);

                        debugPrint(
                          '📋 Added message for group $groupId: ${messageMap['id'] ?? 'unknown'}',
                        );
                      } catch (e) {
                        debugPrint(
                          '❌ Error processing message in group $groupId: $e',
                        );
                      }
                    }
                  } else {
                    debugPrint(
                      '⚠️ Group data is not a List: ${groupData.runtimeType}',
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Error processing group $groupIdStr: $e');
                }
              });

              debugPrint(
                '📋 Extracted ${allMessages.length} messages from server format',
              );

              if (allMessages.isNotEmpty) {
                // Send to isolate for processing
                _sendToIsolate(
                  IsolateMessage(type: 'messages_list', data: allMessages),
                );

                // Also update UI directly for immediate display
                try {
                  _processAndUpdateUIMessages(allMessages);
                } catch (e) {
                  debugPrint('❌ Error in direct UI update: $e');
                }
              } else {
                debugPrint('⚠️ No messages extracted from server format');
              }
            } else if (firstItem.containsKey('group') ||
                firstItem.containsKey('groupId')) {
              debugPrint('📋 Detected list of groups format');

              // Process as list of groups with messages
              final allMessages = <Map<String, dynamic>>[];

              for (final groupData in data) {
                try {
                  final groupMap = Map<String, dynamic>.from(groupData);
                  final groupId = groupMap['group'] ?? groupMap['groupId'];

                  // FIXED: Better handling of messages extraction
                  dynamic messagesRaw = groupMap['messages'];
                  List<dynamic> messagesData = [];

                  if (messagesRaw is List) {
                    messagesData = messagesRaw;
                  } else if (messagesRaw != null) {
                    debugPrint(
                      '⚠️ messagesRaw is not List: ${messagesRaw.runtimeType}, value: $messagesRaw',
                    );
                    // Try to convert if it's a String that might be JSON
                    if (messagesRaw is String) {
                      try {
                        final parsed = jsonDecode(messagesRaw);
                        if (parsed is List) {
                          messagesData = parsed;
                        }
                      } catch (e) {
                        debugPrint('❌ Failed to parse messages as JSON: $e');
                      }
                    }
                  }

                  debugPrint(
                    '📋 Processing group $groupId with ${messagesData.length} messages',
                  );

                  for (final messageData in messagesData) {
                    try {
                      final messageMap = Map<String, dynamic>.from(messageData);
                      // Ensure each message has the groupId
                      if (!messageMap.containsKey('group') &&
                          !messageMap.containsKey('groupId')) {
                        messageMap['group'] = groupId;
                      }
                      allMessages.add(messageMap);
                    } catch (e) {
                      debugPrint(
                        '❌ Error processing message in group $groupId: $e',
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('❌ Error processing group: $e');
                }
              }

              debugPrint(
                '📋 Extracted ${allMessages.length} messages from groups format',
              );

              if (allMessages.isNotEmpty) {
                _sendToIsolate(
                  IsolateMessage(type: 'messages_list', data: allMessages),
                );

                try {
                  _processAndUpdateUIMessages(allMessages);
                } catch (e) {
                  debugPrint('❌ Error in direct UI update: $e');
                }
              }
            } else if (firstItem.containsKey('id')) {
              debugPrint('📋 Detected list of messages format');
              _sendToIsolate(IsolateMessage(type: 'messages_list', data: data));
            } else {
              debugPrint('❌ Unknown list format in messages_list');
              debugPrint('Full first item: $firstItem');
            }
          } else {
            debugPrint('❌ First item is not a Map: ${firstItem.runtimeType}');
          }
        } else if (data is Map<String, dynamic>) {
          debugPrint('📋 Single Map format received');
          // Handle single map format if needed
        } else {
          debugPrint(
            '❌ Unexpected messages_list data type: ${data.runtimeType}',
          );
        }
      },

      'new_message': (data) {
        if (_isProcessingNewMessage) {
          debugPrint('⚠️ Already processing new_message, skipping');
          return;
        }

        debugPrint('📨 new_message received: ${data['id']}');

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
            if (_processedMessageIds.length > 1000) {
              final oldest = _processedMessageIds.take(500).toList();
              _processedMessageIds.removeAll(oldest);
            }
          }

          // Process message immediately for UI responsiveness
          try {
            final message = Message.fromJson(data);
            _addMessageToGroupUI(message.group, message);
          } catch (e) {
            debugPrint('❌ Error processing new_message: $e');
            debugPrint('Message data: $data');
          }

          // Also send to isolate for batch processing
          _queueMessageForBatch(data);
        } finally {
          _isProcessingNewMessage = false;
        }
      },

      'message_sent': (data) {
        debugPrint('📤 message_sent: $data');

        final tempId = data['tempId']?.toString();
        final messageId = data['messageId']?.toString();

        if (tempId != null) {
          _processingTempIds.add(tempId);
          Future.delayed(Duration(seconds: 5), () {
            _processingTempIds.remove(tempId);
          });
        }

        if (messageId != null) {
          _processedMessageIds.add(messageId);
        }

        _emitEvent('message_sent', data);
      },

      'online_users': (data) {
        debugPrint('👥 online_users: $data');
        _handleOnlineUsers(data);
      },

      // Other handlers...
      'chat_joined': (data) => _emitEvent('chat_joined', data),
      'chat_left': (data) => _emitEvent('chat_left', data),
      'group_joined': (data) => _emitEvent('group_joined', data),
      'groups_refreshed': (data) => _emitEvent('groups_refreshed', data),
      'reaction_added_success': (data) => _handleReactionReceived(data, true),
      'reaction_removed_success': (data) =>
          _handleReactionReceived(data, false),
      'message_edited': (data) {
        _sendToIsolate(IsolateMessage(type: 'update_message', data: data));
        _updateSingleMessageUI(data);
        _emitEvent('message_edited', data);
      },
      'message_deleted': (data) => _handleMessageDeletedInUI(data),
      'message_read': (data) => _emitEvent('message_read', data),
      'message_read_receipt': (data) => _handleMessageReadReceipt(data),
      'messages_read': (data) => _handleMessagesRead(data),
      'user_typing': (data) {
        _sendToIsolate(IsolateMessage(type: 'process_typing_data', data: data));
        _handleTypingStart(data);
      },
      'user_stopped_typing': (data) {
        _sendToIsolate(IsolateMessage(type: 'process_typing_data', data: data));
        _handleTypingStop(data);
      },
      'user_joined': (data) {
        _emitEvent('user_joined', data);
        _emitEvent('group_update', {
          'type': 'user_joined',
          'groupId': data['groupId'],
          'data': data,
          'timestamp': data['timestamp'],
        });
      },
      'user_left': (data) {
        _emitEvent('user_left', data);
        _emitEvent('group_update', {
          'type': 'user_left',
          'groupId': data['groupId'],
          'data': data,
          'timestamp': data['timestamp'],
        });
      },
      'user_online': (data) {
        _handleUserOnline(data);
        _emitEvent('user_online', data);
      },
      'user_offline': (data) {
        _handleUserOffline(data);
        _emitEvent('user_offline', data);
      },
      'call_started': (data) {
        _sendToIsolate(IsolateMessage(type: 'process_call_data', data: data));
        _handleCallStarted(data);
      },
      'call_answered': (data) {
        audio.stop();
        _emitEvent('call_answered', data);
      },
      'call_rejected': (data) {
        audio.stop();
        _emitEvent('call_rejected', data);
      },
      'call_ended': (data) {
        audio.stop();
        _emitEvent('call_ended', data);
      },
      'user_joined_call': (data) => _emitEvent('user_joined_call', data),
      'user_left_call': (data) => _emitEvent('user_left_call', data),
      'webrtc_offer': (data) => _emitEvent('webrtc_offer', data),
      'webrtc_answer': (data) => _emitEvent('webrtc_answer', data),
      'webrtc_ice_candidate': (data) =>
          _emitEvent('webrtc_ice_candidate', data),
      'error': (data) {
        debugPrint('❌ Chat error: $data');
        _emitEvent('error', data);
      },
      'ping': (_) {
        debugPrint('🏓 ping received');
        emit('pong', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      },
    };

    handlerMap.forEach((event, handler) {
      _registerSocketHandler(event, handler);
    });

    _handlersSetup = true;
    debugPrint('✅ Setup ${handlerMap.length} chat handlers');
  }

  void _setupConnectionHandlers() {
    debugPrint('🔄 Setting up connection handlers...');

    if (socketService.socket != null) {
      socketService.socket!.clearListeners();
    }

    socketService.onConnected(_handleConnected);
    socketService.onDisconnected(_handleDisconnected);
    socketService.onError(_handleError);
    socketService.onConnecting(_handleConnecting);
    socketService.onReconnectAttempt(_handleReconnectAttempt);

    debugPrint('✅ Setup connection handlers');
  }

  void _registerSocketHandler(String event, Function(dynamic) handler) {
    if (_isDisposed) return;

    _eventHandlers.putIfAbsent(event, () => {});
    final handlerSet = _eventHandlers[event]!;

    final handlerHash = identityHashCode(handler);
    final alreadyRegistered = handlerSet.any(
      (h) => identityHashCode(h) == handlerHash,
    );

    if (!alreadyRegistered) {
      handlerSet.add(handler);
      debugPrint('✅ Stored handler for event: $event');
    }

    if (socketService.socket != null && socketService.socket!.connected) {
      _registerHandlerWithSocket(event, handler);
    }
  }

  void _registerHandlerWithSocket(String event, Function(dynamic) handler) {
    if (_isDisposed || socketService.socket == null) return;

    try {
      if (_registeredSocketEvents.contains(event)) {
        return;
      }

      debugPrint('🔗 Registering socket handler for: $event');
      socketService.socket!.on(event, handler);
      _registeredSocketEvents.add(event);
    } catch (e) {
      debugPrint('❌ Error registering socket handler for $event: $e');
    }
  }

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

  void _handleGroupsFromChatInitialized(dynamic data) {
    try {
      final dataMap = _makeSerializable(data);
      final groups = dataMap['groups'] as List<dynamic>?;

      if (groups != null && groups.isNotEmpty) {
        final groupIds = groups
            .map((g) {
              if (g is num) return g;
              if (g is String) return num.tryParse(g) ?? 0;
              return 0;
            })
            .where((id) => id > 0)
            .toList();

        debugPrint('📋 Extracted group IDs from chat_initialized: $groupIds');

        if (groupIds.isNotEmpty) {
          oneSignalService.subscribeToGroupTags(groupIds);
          _updateUserGroups(groupIds);
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling groups from chat_initialized: $e');
    }
  }

  void _updateUserGroups(List<num> groupIds) {
    _currentGroups.clear();
    _currentGroups.addAll(groupIds);
  }

  bool isUserInGroup(num groupId) {
    return _currentGroups.contains(groupId);
  }

  void _registerAllHandlersWithSocket() {
    if (_isDisposed || socketService.socket == null) return;

    debugPrint('🔗 Registering all handlers with socket...');

    socketService.socket!.clearListeners();
    _registeredSocketEvents.clear();

    _eventHandlers.forEach((event, handlers) {
      for (final handler in handlers) {
        try {
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

  void _handleConnected() {
    if (_isDisposed) return;

    debugPrint('🎉 Chat socket connected');
    _isConnected.value = true;
    _connectionStatus.value = 'connected';
    _reconnectAttempts = 0;

    _isAuthenticated = false;
    _hasRequestedInitialData = false;

    _registerAllHandlersWithSocket();

    _processMessageQueue();
    notifyListeners();
    _emitEvent('connected');
  }

  void _handleConnecting() {
    if (_isDisposed) return;

    debugPrint('🔄 Connecting to chat socket...');
    _connectionStatus.value = 'connecting';
    notifyListeners();
  }

  void _handleDisconnected(String reason) {
    if (_isDisposed) return;

    debugPrint('🔌 Chat socket disconnected: $reason');
    _isConnected.value = false;
    _isAuthenticated = false;
    _connectionStatus.value = 'disconnected';
    _handlersRegisteredWithSocket = false;
    _hasRequestedInitialData = false;
    notifyListeners();
    _emitEvent('disconnected', {'reason': reason});
    _scheduleReconnect();
  }

  void _handleError(dynamic error) {
    if (_isDisposed) return;

    debugPrint('❌ Chat socket error: $error');
    _connectionStatus.value = 'disconnected';
    notifyListeners();
    _emitEvent('error', {'error': error.toString()});
  }

  void _handleReconnectAttempt(int attempt) {
    if (_isDisposed) return;

    debugPrint('🔄 Chat socket reconnect attempt: $attempt');
    _connectionStatus.value = 'reconnecting';
    _reconnectAttempts = attempt;
    notifyListeners();
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
    try {
      debugPrint('👥 Handling online_users: $data');

      if (data is Map<String, dynamic>) {
        final groups = data['groups'] as Map<String, dynamic>? ?? {};
        final count = data['count'] as int? ?? 0;

        // Extract all online users from all groups
        final allOnlineUsers = <num>{};
        final groupUsersMap = <num, Set<num>>{};

        groups.forEach((groupIdStr, usersData) {
          final groupId = num.tryParse(groupIdStr) ?? 0;
          if (groupId == 0) return;

          if (usersData is List) {
            final users = usersData
                .map((u) {
                  if (u is Map) {
                    return u['user'] as num? ?? 0;
                  } else if (u is num) {
                    return u;
                  } else if (u is String) {
                    return num.tryParse(u) ?? 0;
                  }
                  return 0;
                })
                .where((id) => id > 0)
                .toSet();

            groupUsersMap[groupId] = users;
            allOnlineUsers.addAll(users);
          }
        });

        // Update UI
        _onlineUsersUI.value = allOnlineUsers;
        _onlineUsersByGroupUI.value = groupUsersMap;

        debugPrint(
          '✅ Updated online users: $allOnlineUsers across ${groupUsersMap.length} groups',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error handling online_users: $e');
    }
  }

  // Typing handlers
  void _handleTypingStart(dynamic data) {
    final indicator = TypingIndicator.fromJson({
      ...data,
      'groupId': num.parse('${data['groupId']}'),
    });
    final currentUserId = _userId;

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

    notifyListeners();
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
    notifyListeners();
  }

  // Message handlers
  void _handleMessagesRead(dynamic data) {
    final groupId = data['groupId'];
    final messageIds = List<String>.from(data['messageIds'] ?? []);

    if (groupId != null && messageIds.isNotEmpty) {
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

      notifyListeners();
    }
  }

  void _handleMessagesRetrievedFromIsolate(dynamic data) {
    try {
      final groupId = data['groupId'];
      final messagesData = List<Map<String, dynamic>>.from(
        data['messages'] ?? [],
      );
      final hasNext = data['hasNext'] ?? false;

      if (groupId == null) {
        debugPrint('⚠️ groupId is null in messages_retrieved');
        return;
      }

      final messages = messagesData.map((m) => Message.fromJson(m)).toList();

      final existingGroups = List<MessageGroup>.from(_messages.value);
      final groupIndex = existingGroups.indexWhere((g) => g.groupId == groupId);

      if (groupIndex != -1) {
        final existingMessages = existingGroups[groupIndex].messages;
        final updatedMessages = [...existingMessages, ...messages]
          ..sort(
            (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
              b.createdAt ?? DateTime.now(),
            ),
          );
        existingGroups[groupIndex] = MessageGroup(
          groupId: groupId,
          messages: updatedMessages,
        );
      } else {
        existingGroups.add(MessageGroup(groupId: groupId, messages: messages));
      }

      _messages.value = existingGroups;
      notifyListeners();

      _emitEvent('messages_retrieved', {
        'groupId': groupId,
        'messages': messages,
        'hasNext': hasNext,
      });
    } catch (e) {
      debugPrint('❌ Error handling messages retrieved: $e');
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

        notifyListeners();
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

      notifyListeners();

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

    for (final messageData in messagesData) {
      try {
        final message = Message.fromJson(messageData);
        _addMessageToGroupUI(message.group, message);
      } catch (e) {
        debugPrint('❌ Error updating message from isolate: $e');
      }
    }

    notifyListeners();
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

    notifyListeners();
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

    notifyListeners();
    _emitEvent('presence_update', data);
  }

  void _handleCallFromIsolate(Map<String, dynamic> data) {
    // if (_isDisposed) return;

    // try {
    //   final callData = CallData.fromJson(data);
    //   // webrtcManager.setIncomingCall(callData);
    //   _emitEvent('call_processed', data);
    // } catch (e) {
    //   debugPrint('❌ Error handling call from isolate: $e');
    // }
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

    notifyListeners();
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

      notifyListeners();
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

      notifyListeners();
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
    }

    // Add to UI state
    final List<MessageGroup> currentMessages = List.from(_messages.value);
    final groupIndex = currentMessages.indexWhere((g) => g.groupId == groupId);

    if (groupIndex == -1) {
      // Create new group
      currentMessages.add(MessageGroup(groupId: groupId, messages: [message]));
    } else {
      // Update existing group
      final existingMessages = List<Message>.from(
        currentMessages[groupIndex].messages,
      );
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

        currentMessages[groupIndex] = MessageGroup(
          groupId: groupId,
          messages: existingMessages,
        );
      }
    }

    // IMPORTANT: Assign new list to trigger ValueNotifier update
    _messages.value = currentMessages;

    // Mark as read if this is the current group
    if (_currentGroupId == groupId) {
      markMessageAsRead(message.id, groupId);
    }

    notifyListeners();
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

    notifyListeners();
    _emitEvent('message_deleted', serializableData);
  }

  void _handleCallStarted(dynamic data) {
    if (_isDisposed) return;

    try {
      debugPrint('📞 Incoming call received: $data');
      final callData = CallData.fromJson(data);

      if (callData.initiatorId == _userId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentState != null &&
              navigatorKey.currentState!.mounted) {
            print('🚀 Navigating to CallScreen with call: ${callData.callId}');

            // Close any existing dialogs or modals
            navigatorKey.currentState!.popUntil((route) => route.isFirst);

            // Navigate to CallScreen
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  callData: callData,
                  webrtcManager: _webrtcManager,
                ),
                fullscreenDialog: true, // Makes it modal
              ),
            );
          } else {
            //   print('⚠️ Navigator not available yet, retrying...');
            //   // Retry after a delay
            //   Future.delayed(Duration(milliseconds: 500), () {
            //     _navigateToCallScreen();
            //   });
          }
        });
      }
      // webrtcManager.setIncomingCall(callData);
      _emitEvent('call_started', data);
    } on Exception catch (e) {
      debugPrint("Error handling call: ${e.toString()}");
    }
  }

  void _emitEvent(String event, [dynamic data]) {
    if (_isDisposed) return;

    final now = DateTime.now();
    final lastEvent = _lastEventTime[event];

    if (lastEvent != null && now.difference(lastEvent) < _eventDebounceTime) {
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

    final tempId = params.tempId;
    if (tempId != null) {
      _processingTempIds.add(tempId);
    }

    // Add to UI immediately for better UX
    try {
      final tempMessage = Message.fromJson({
        ...messageData,
        'id': tempId ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
        'sender': _userId,
        'senderName': _userName,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'sending',
        'tempId': tempId,
      });

      _addMessageToGroupUI(params.groupId, tempMessage);
    } catch (e) {
      debugPrint('❌ Error adding temp message to UI: $e');
    }

    // Send to isolate
    _sendToIsolate(IsolateMessage(type: 'update_message', data: messageData));

    if (!_isConnected.value) {
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

    // Update in isolate
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
    notifyListeners();

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

    notifyListeners();

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
    notifyListeners();
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
    notifyListeners();
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
      return;
    }

    _lastTypingSent[groupId] = now;
    emit('typing_start', {'groupId': groupId});

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
        debugPrint("📨 CHAT SOCKET Incoming call received via WebRTC");
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

  // File upload
  Future<String> uploadFile(File file, String groupId) async {
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
    return 'User';
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
    notifyListeners();
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
    notifyListeners();
  }

  void reconnect() {
    _cancelReconnect();
    debugPrint('🔄 Reconnecting chat socket...');
    socketService.reconnect();
  }

  // Cleanup
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isInitialized = false;

    debugPrint('🧹 Disposing ChatWebSocketHandler...');

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

  // Audio generation
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
