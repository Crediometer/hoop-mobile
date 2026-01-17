// lib/providers/notification_websocket_handler.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'package:hoop/dtos/responses/notifications/notification.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:vibration/vibration.dart';

// Isolate communication model
class NotificationIsolateMessage {
  final String type;
  final dynamic data;
  final SendPort? replyPort;

  NotificationIsolateMessage({required this.type, this.data, this.replyPort});

  Map<String, dynamic> toJson() => {'type': type, 'data': data};
}

// Isolate worker class
class NotificationIsolateWorker {
  final SendPort _sendPort;
  final List<Map<String, dynamic>> _notifications = [];
  final Map<String, List<Map<String, dynamic>>> _notificationsByType = {};
  final Map<String, int> _notificationCounts = {};
  final Map<String, List<Map<String, dynamic>>> _searchCache = {};

  NotificationIsolateWorker(this._sendPort);

  void handleMessage(NotificationIsolateMessage message) {
    try {
      switch (message.type) {
        case 'process_notification_batch':
          _processNotificationBatch(message.data);
          break;
        case 'parse_notifications_json':
          _parseNotificationsJson(message.data);
          break;
        case 'search_notifications':
          _searchNotifications(message.data);
          break;
        case 'filter_by_type':
          _filterByType(message.data);
          break;
        case 'calculate_counts':
          _calculateCounts(message.data);
          break;
        case 'update_notification':
          _updateNotification(message.data);
          break;
        case 'get_notifications':
          _getNotifications(message.data);
          break;
        case 'shutdown':
          _shutdown();
          break;
      }
    } catch (e, stack) {
      debugPrint('❌ Error in notification isolate: $e\n$stack');
      _sendPort.send(
        NotificationIsolateMessage(
          type: 'error',
          data: {'error': e.toString(), 'stack': stack.toString()},
        ),
      );
    }
  }

  void _processNotificationBatch(List<dynamic> notificationsData) {
    final processed = <Map<String, dynamic>>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final data in notificationsData) {
      try {
        final notification = _parseSingleNotification(data);
        processed.add(notification);

        // Add to main list
        _notifications.add(notification);

        // Index by type for faster filtering
        final type = notification['type']?.toString() ?? 'unknown';
        _notificationsByType.putIfAbsent(type, () => []);
        _notificationsByType[type]!.add(notification);

        // Update counts
        if (!(notification['read'] ?? true)) {
          _notificationCounts[type] = (_notificationCounts[type] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('❌ Error processing notification in isolate: $e');
      }
    }

    // Sort by created date (newest first)
    _notifications.sort((a, b) {
      final dateA = a['createdAt'] is String
          ? DateTime.parse(a['createdAt']).millisecondsSinceEpoch
          : a['createdAt'] ?? 0;
      final dateB = b['createdAt'] is String
          ? DateTime.parse(b['createdAt']).millisecondsSinceEpoch
          : b['createdAt'] ?? 0;
      return dateB.compareTo(dateA);
    });

    _sendPort.send(
      NotificationIsolateMessage(
        type: 'notifications_processed',
        data: {
          'processed': processed,
          'counts': _notificationCounts,
          'timestamp': now,
        },
      ),
    );
  }

  void _parseNotificationsJson(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      final notificationsData = List<Map<String, dynamic>>.from(
        parsed['notifications'] ?? [],
      );
      final processed = notificationsData
          .map(_parseSingleNotification)
          .toList();

      _sendPort.send(
        NotificationIsolateMessage(
          type: 'notifications_parsed',
          data: processed,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error parsing notifications JSON in isolate: $e');
    }
  }

  Map<String, dynamic> _parseSingleNotification(dynamic data) {
    try {
      if (data is NotificationModel) {
        return {
          'id': data.id,
          'title': data.title,
          'message': data.message,
          'type': data.type.toString(),
          'read': data.read,
          'createdAt': data.createdAt?.toIso8601String(),
          // 'metadata': data.metadata,
          'senderId': data.senderId,
          // 'senderName': data.senderName,
          'actionUrl': data.actionUrl,
          // 'priority': data.priority,
          '_processedAt': DateTime.now().millisecondsSinceEpoch,
        };
      } else if (data is Map) {
        return {
          'id': data['id'] ?? data['_id'] ?? '',
          'title': data['title'] ?? data['subject'] ?? 'Notification',
          'message': data['message'] ?? data['body'] ?? data['content'] ?? '',
          'type':
              data['type']?.toString() ??
              data['notificationType']?.toString() ??
              'unknown',
          'read': data['read'] ?? data['status'] == 'read' ?? false,
          'createdAt': data['createdAt'] is String
              ? data['createdAt']
              : (data['createdAt'] is DateTime
                    ? (data['createdAt'] as DateTime).toIso8601String()
                    : DateTime.now().toIso8601String()),
          'metadata': data['metadata'] ?? data['data'] ?? {},
          'senderId': data['senderId'] ?? data['fromUserId'] ?? data['userId'],
          'senderName':
              data['senderName'] ??
              data['userName'] ??
              data['fromUserName'] ??
              'Unknown',
          'actionUrl': data['actionUrl'] ?? data['url'] ?? data['link'],
          'priority': data['priority'] ?? data['importance'] ?? 'normal',
          '_processedAt': DateTime.now().millisecondsSinceEpoch,
        };
      }
      return {'error': 'Invalid notification data type'};
    } catch (e) {
      debugPrint('❌ Error parsing single notification: $e');
      return {'error': e.toString()};
    }
  }

  void _searchNotifications(Map<String, dynamic> data) {
    final query = (data['query'] as String?)?.toLowerCase() ?? '';
    final typeFilter = data['type'] as String?;

    if (query.isEmpty && typeFilter == null) {
      _sendPort.send(
        NotificationIsolateMessage(
          type: 'search_results',
          data: {
            'query': query,
            'results': _notifications,
            'count': _notifications.length,
          },
        ),
      );
      return;
    }

    // Check cache first
    final cacheKey = '${query}_${typeFilter}';
    if (_searchCache.containsKey(cacheKey)) {
      _sendPort.send(
        NotificationIsolateMessage(
          type: 'search_results',
          data: {
            'query': query,
            'results': _searchCache[cacheKey],
            'count': _searchCache[cacheKey]!.length,
            'cached': true,
          },
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> results = [];

    for (final notification in _notifications) {
      bool matches = true;

      // Type filter
      if (typeFilter != null) {
        final notificationType = notification['type']?.toString() ?? '';
        if (!notificationType.contains(typeFilter)) {
          matches = false;
        }
      }

      // Search query
      if (query.isNotEmpty && matches) {
        final title = (notification['title'] as String? ?? '').toLowerCase();
        final message = (notification['message'] as String? ?? '')
            .toLowerCase();

        if (!title.contains(query) && !message.contains(query)) {
          matches = false;
        }
      }

      if (matches) {
        results.add(notification);
      }
    }

    // Cache results
    _searchCache[cacheKey] = results;

    // Limit cache size
    if (_searchCache.length > 20) {
      final keys = _searchCache.keys.toList();
      for (int i = 0; i < keys.length - 10; i++) {
        _searchCache.remove(keys[i]);
      }
    }

    _sendPort.send(
      NotificationIsolateMessage(
        type: 'search_results',
        data: {'query': query, 'results': results, 'count': results.length},
      ),
    );
  }

  void _filterByType(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final includeRead = data['includeRead'] as bool? ?? true;

    final filtered = _notifications.where((notification) {
      final notificationType = notification['type']?.toString() ?? '';
      final isRead = notification['read'] as bool? ?? false;

      bool matchesType = type.isEmpty || notificationType.contains(type);
      bool matchesRead = includeRead || !isRead;

      return matchesType && matchesRead;
    }).toList();

    _sendPort.send(
      NotificationIsolateMessage(
        type: 'filtered_results',
        data: {'type': type, 'results': filtered, 'count': filtered.length},
      ),
    );
  }

  void _calculateCounts(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> notifications = List.from(
      data['notifications'] ?? [],
    );

    int unreadCount = 0;
    int totalCount = notifications.length;
    final typeCounts = <String, int>{};
    final priorityCounts = <String, int>{};

    for (final notification in notifications) {
      final isRead = notification['read'] as bool? ?? false;
      if (!isRead) {
        unreadCount++;

        final type = notification['type']?.toString() ?? 'unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;

        final priority = notification['priority']?.toString() ?? 'normal';
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
      }
    }

    _sendPort.send(
      NotificationIsolateMessage(
        type: 'counts_calculated',
        data: {
          'unreadCount': unreadCount,
          'totalCount': totalCount,
          'readCount': totalCount - unreadCount,
          'typeCounts': typeCounts,
          'priorityCounts': priorityCounts,
        },
      ),
    );
  }

  void _updateNotification(Map<String, dynamic> data) {
    final notificationId =
        data['id'] as String? ?? data['notificationId'] as String?;
    final updates = data['updates'] as Map<String, dynamic>? ?? {};

    if (notificationId == null) return;

    // Update in main list
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index] = {..._notifications[index], ...updates};

      // Update type index if type changed
      final oldType = _notifications[index]['type']?.toString() ?? 'unknown';
      final newType = updates['type']?.toString() ?? oldType;

      if (oldType != newType) {
        // Remove from old type list
        _notificationsByType[oldType]?.removeWhere(
          (n) => n['id'] == notificationId,
        );
        // Add to new type list
        _notificationsByType.putIfAbsent(newType, () => []);
        _notificationsByType[newType]!.add(_notifications[index]);
      }

      // Update counts if read status changed
      if (updates.containsKey('read')) {
        final isRead = updates['read'] as bool? ?? false;
        final type = newType;

        if (isRead) {
          _notificationCounts[type] = (_notificationCounts[type] ?? 1) - 1;
          if (_notificationCounts[type]! <= 0) {
            _notificationCounts.remove(type);
          }
        } else {
          _notificationCounts[type] = (_notificationCounts[type] ?? 0) + 1;
        }
      }

      // Clear search cache since data changed
      _searchCache.clear();

      _sendPort.send(
        NotificationIsolateMessage(
          type: 'notification_updated',
          data: _notifications[index],
        ),
      );
    }
  }

  void _getNotifications(Map<String, dynamic> params) {
    final page = (params['page'] as int?) ?? 1;
    final limit = (params['limit'] as int?) ?? 20;
    final unreadOnly = params['unreadOnly'] as bool? ?? false;
    final type = params['type'] as String?;

    List<Map<String, dynamic>> source = _notifications;

    if (unreadOnly) {
      source = source.where((n) => !(n['read'] as bool? ?? true)).toList();
    }

    if (type != null && type.isNotEmpty) {
      source = source
          .where((n) => (n['type'] as String? ?? '').contains(type))
          .toList();
    }

    final start = (page - 1) * limit;
    final end = start + limit;
    final paginated = source.sublist(
      start.clamp(0, source.length),
      end.clamp(0, source.length),
    );

    _sendPort.send(
      NotificationIsolateMessage(
        type: 'notifications_retrieved',
        data: {
          'notifications': paginated,
          'page': page,
          'limit': limit,
          'total': source.length,
          'hasMore': end < source.length,
        },
      ),
    );
  }

  void _shutdown() {
    _notifications.clear();
    _notificationsByType.clear();
    _notificationCounts.clear();
    _searchCache.clear();
  }
}

// Main Notification Handler with Isolate Support
class NotificationWebSocketHandler with ChangeNotifier {
  final BaseWebSocketService socketService;
  final TokenManager tokenManager = TokenManager.instance;

  // Isolate Management
  Isolate? _isolate;
  ReceivePort? _isolateReceivePort;
  SendPort? _isolateSendPort;
  bool _isolateInitialized = false;
  final Map<String, Completer<dynamic>> _isolateCompleters = {};
  int _isolateRequestId = 0;

  // UI State (lightweight)
  final List<NotificationModel> _notifications = [];
  NotificationModel? _lastNotification;
  ValueNotifier<int> _unreadCount = ValueNotifier(0);
  int _totalCount = 0;
  bool _loading = false;
  String? _error;
  String? _currentUserId;

  // Pending event handlers
  final List<MapEntry<String, Function(dynamic)>> _pendingHandlers = [];

  // Token monitoring
  Timer? _tokenCheckTimer;
  String? _currentToken;
  bool _tokenMonitoringStarted = false;
  final Duration _tokenCheckInterval = const Duration(seconds: 2);

  // Batch processing
  final List<Map<String, dynamic>> _notificationBatch = [];
  Timer? _batchTimer;
  final Duration _batchDelay = const Duration(milliseconds: 100);
  final int _batchSize = 30;

  NotificationWebSocketHandler({required this.socketService}) {
    _initialize();
  }

  // Getters
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  NotificationModel? get lastNotification => _lastNotification;
  ValueNotifier<int>  get unreadCount => _unreadCount;
  int get totalCount => _totalCount;
  bool get loading => _loading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  bool get isConnected => socketService.isConnected;
  bool get isConnecting => socketService.isConnecting;
  String? get connectionError => socketService.connectionError;

  int get readCount => _totalCount - _unreadCount.value;

  // Isolate Initialization
  Future<void> _initializeIsolate() async {
    if (_isolateInitialized) return;

    _isolateReceivePort = ReceivePort();

    try {
      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _isolateReceivePort!.sendPort,
        debugName: 'NotificationWebSocketIsolate',
        errorsAreFatal: true,
      );

      _isolateReceivePort!.listen(_handleIsolateMessage);
      _isolateInitialized = true;
      debugPrint('✅ Notification isolate initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification isolate: $e');
      _isolateReceivePort?.close();
      _isolateInitialized = false;
    }
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    final worker = NotificationIsolateWorker(sendPort);

    receivePort.listen((message) {
      if (message is NotificationIsolateMessage) {
        worker.handleMessage(message);
      }
    });
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
      // Send initialization message
      _sendToIsolate(NotificationIsolateMessage(type: 'initialize'));
      return;
    }

    if (message is NotificationIsolateMessage) {
      switch (message.type) {
        case 'notifications_processed':
          _updateNotificationsFromIsolate(message.data['processed']);
          _updateCountsFromIsolate(message.data['counts']);
          break;
        case 'notifications_parsed':
          _updateNotificationsFromIsolate(message.data);
          break;
        case 'search_results':
          _handleSearchResults(message.data);
          break;
        case 'filtered_results':
          _handleFilteredResults(message.data);
          break;
        case 'counts_calculated':
          _updateCountsFromIsolate(message.data);
          break;
        case 'notification_updated':
          _updateSingleNotificationFromIsolate(message.data);
          break;
        case 'notifications_retrieved':
          _updateNotificationsFromIsolate(message.data['notifications']);
          _emitEvent('notifications_loaded', message.data);
          break;
        case 'error':
          debugPrint('❌ Isolate error: ${message.data?['error']}');
          break;
      }

      // Complete pending completers
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
    NotificationIsolateMessage message, {
    bool waitForResponse = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isolateInitialized || _isolateSendPort == null) {
      await _initializeIsolate();
      if (_isolateSendPort == null) {
        throw Exception('Notification isolate not ready');
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
        completer.completeError(
          TimeoutException('Notification isolate response timeout'),
        );
        _isolateCompleters.remove(completerKey);
      }
    });

    _isolateSendPort!.send(
      NotificationIsolateMessage(
        type: message.type,
        data: message.data,
        replyPort: _isolateReceivePort!.sendPort,
      ),
    );

    return completer.future;
  }

  // UI Update Methods from Isolate
  void _updateNotificationsFromIsolate(List<dynamic> notificationsData) {
    if (notificationsData.isEmpty) return;

    // Process in chunks for UI responsiveness
    final chunkSize = 15;
    final total = notificationsData.length;
    int processed = 0;

    void processChunk() {
      final end = processed + chunkSize;
      final chunk = notificationsData.sublist(
        processed,
        end > total ? total : end,
      );

      for (final notificationData in chunk) {
        try {
          final notification = NotificationModel.fromJson(notificationData);
          _addNotificationToUI(notification);
        } catch (e) {
          debugPrint('❌ Error updating notification from isolate: $e');
        }
      }

      processed = end;

      if (processed < total) {
        Future.microtask(() => processChunk());
      } else {
        _calculateCounts();
        _notifyListeners();
      }
    }

    processChunk();
  }

  void _updateCountsFromIsolate(Map<String, dynamic> countsData) {
    _unreadCount = countsData['unreadCount'] ?? 0;
    _totalCount = countsData['totalCount'] ?? 0;
    _notifyListeners();
    _emitEvent('counts_updated', countsData);
  }

  void _handleSearchResults(Map<String, dynamic> data) {
    final results = List<Map<String, dynamic>>.from(data['results'] ?? []);
    final searchResults = results
        .map((n) => NotificationModel.fromJson(n))
        .toList();

    _emitEvent('search_results', {
      'query': data['query'],
      'results': searchResults,
      'count': data['count'],
      'cached': data['cached'] ?? false,
    });
  }

  void _handleFilteredResults(Map<String, dynamic> data) {
    final results = List<Map<String, dynamic>>.from(data['results'] ?? []);
    final filteredResults = results
        .map((n) => NotificationModel.fromJson(n))
        .toList();

    _emitEvent('filtered_results', {
      'type': data['type'],
      'results': filteredResults,
      'count': data['count'],
    });
  }

  void _updateSingleNotificationFromIsolate(
    Map<String, dynamic> notificationData,
  ) {
    try {
      final notification = NotificationModel.fromJson(notificationData);

      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification;
        _calculateCounts();
        _notifyListeners();
        _emitEvent('notification_updated', notification);
      }
    } catch (e) {
      debugPrint('❌ Error updating single notification from isolate: $e');
    }
  }

  void _addNotificationToUI(NotificationModel notification) {
    // Check if notification already exists
    final existingIndex = _notifications.indexWhere(
      (n) => n.id == notification.id,
    );

    if (existingIndex != -1) {
      // Update existing notification
      _notifications[existingIndex] = notification;
    } else {
      // Add new notification at the beginning
      _notifications.insert(0, notification);
      _lastNotification = notification;
    }

    // Play sound/vibrate for new unread notifications
    if (!notification.read) {
      _playNotificationSound();
      _vibrate();
    }
  }

  // Batch Processing
  void _queueNotificationForBatch(dynamic data) {
    _notificationBatch.add(data);

    if (_batchTimer == null || !_batchTimer!.isActive) {
      _batchTimer = Timer(_batchDelay, _processNotificationBatch);
    }

    if (_notificationBatch.length >= _batchSize) {
      _batchTimer?.cancel();
      _processNotificationBatch();
    }
  }

  void _processNotificationBatch() {
    if (_notificationBatch.isEmpty) return;

    final batch = List.from(_notificationBatch);
    _notificationBatch.clear();

    _sendToIsolate(
      NotificationIsolateMessage(
        type: 'process_notification_batch',
        data: batch,
      ),
    );
  }

  // Main Initialization
  Future<void> _initialize() async {
    await _initializeIsolate();

    // Setup connection event handlers
    socketService.onConnected(_handleConnected);
    socketService.onDisconnected(_handleDisconnected);
    socketService.onError(_handleError);
    socketService.onConnecting(_handleConnecting);
    socketService.onReconnectAttempt(_handleReconnectAttempt);

    // Setup notification-specific event handlers
    _setupNotificationHandlers();

    // Start token monitoring
    _startTokenMonitoring();

    // Check initial token and connect if available
    await _checkAndConnect();
  }

  // Connection Event Handlers
  void _handleConnected() {
    debugPrint('🎉 Notification socket connected');

    // Register all pending event handlers
    _registerPendingHandlers();

    _loadInitialData();
  }

  void _handleConnecting() {
    debugPrint('🔄 Connecting to notification socket...');
    _loading = true;
    _notifyListeners();
  }

  void _handleDisconnected(String reason) {
    debugPrint('🔌 Notification socket disconnected: $reason');
    _loading = false;
    _notifyListeners();
  }

  void _handleError(dynamic error) {
    debugPrint('❌ Notification socket error: $error');
    _error = error.toString();
    _notifyListeners();
  }

  void _handleReconnectAttempt(int attempt) {
    debugPrint('🔄 Notification socket reconnect attempt: $attempt');
  }

  // Register pending event handlers
  void _registerPendingHandlers() {
    for (final handlerEntry in _pendingHandlers) {
      final event = handlerEntry.key;
      final handler = handlerEntry.value;

      socketService.socket?.on(event, handler);
      debugPrint('✅ Registered event listener for: $event');
    }

    _pendingHandlers.clear();
  }

  // Event Management
  void on(String event, Function(dynamic) handler) {
    debugPrint('📝 Registering event listener for: $event');

    if (socketService.socket != null && socketService.isConnected) {
      socketService.socket!.on(event, handler);
      debugPrint('✅ Immediately registered event listener for: $event');
    } else {
      _pendingHandlers.add(MapEntry(event, handler));
      debugPrint('⏳ Queued event listener for: $event');
    }
  }

  void off(String event, [Function(dynamic)? handler]) {
    socketService.socket?.off(event);
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

  void _emitEvent(String event, [dynamic data]) {
    // Internal event emission for UI updates
    notifyListeners();
  }

  // Setup notification event handlers
  void _setupNotificationHandlers() {
    on('new_notification', (data) {
      _queueNotificationForBatch(data);
      _emitEvent('new_notification_received', data);
    });

    on('notifications_list', (data) async {
      try {
        // Send to isolate for parsing
        await _sendToIsolate(
          NotificationIsolateMessage(
            type: 'parse_notifications_json',
            data: jsonEncode(data),
          ),
        );

        _loading = false;
        _emitEvent('notifications_list_processed', data);
      } catch (e) {
        debugPrint('❌ Error processing notifications list: $e');
        _error = e.toString();
        _loading = false;
        _notifyListeners();
      }
    });

    on('notification_marked_read', (data) {
      final notificationId = data['notificationId'];
      _handleNotificationRead(notificationId);
    });

    on('all_notifications_read', (_) {
      _handleAllNotificationsRead();
    });

    on('notification_deleted', (data) {
      final notificationId = data['notificationId'];
      _handleNotificationDeleted(notificationId);
    });

    on('counts_updated', (data) {
      // Send to isolate for calculation
      _sendToIsolate(
        NotificationIsolateMessage(type: 'calculate_counts', data: data),
      );
    });

    on('last_system_message', (data) {
      if (data != null) {
        try {
          _lastNotification = NotificationModel.fromJson(data);
          _notifyListeners();
        } catch (e) {
          debugPrint('❌ Error parsing last system message: $e');
        }
      }
    });

    on('notification_updated', (data) {
      // Send to isolate for processing
      _sendToIsolate(
        NotificationIsolateMessage(type: 'update_notification', data: data),
      );
    });

    on('ping', (_) {
      emit('pong', {'timestamp': DateTime.now().millisecondsSinceEpoch});
    });
  }

  // Notification Event Handlers (UI updates only)
  void _handleNotificationRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _calculateCounts();

      debugPrint('✅ Marked notification $notificationId as read');
      _notifyListeners();
    }
  }

  void _handleAllNotificationsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    _calculateCounts();

    debugPrint('✅ All notifications marked as read');
    _notifyListeners();
  }

  void _handleNotificationDeleted(String notificationId) {
    final initialLength = _notifications.length;
    _notifications.removeWhere((n) => n.id == notificationId);

    if (_notifications.length != initialLength) {
      _calculateCounts();

      debugPrint('🗑️ Deleted notification $notificationId');
      _notifyListeners();
    }
  }

  void _calculateCounts() {
    _unreadCount.value = _notifications.where((n) => !n.read).length;
    _totalCount = _notifications.length;
  }

  // Public API Methods
  void _loadInitialData() {
    _loading = true;
    _notifyListeners();

    emit('get_notifications', {'page': 1, 'limit': 20, 'unreadOnly': false});

    emit('get_counts');
    emit('get_last_system_message');
  }

  void refreshNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) {
    _loading = true;
    _notifyListeners();

    emit('get_notifications', {
      'page': page,
      'limit': limit,
      'unreadOnly': unreadOnly,
    });
  }

  void markAsRead(String notificationId) {
    emit('mark_notification_read', {'notificationId': notificationId});
    _handleNotificationRead(notificationId);
  }

  void markAllAsRead() {
    emit('mark_all_notifications_read');
    _handleAllNotificationsRead();
  }

  void deleteNotification(String notificationId) {
    emit('delete_notification', {'notificationId': notificationId});
    _handleNotificationDeleted(notificationId);
  }

  void getCounts() {
    emit('get_counts');
  }

  void getLastSystemNotification() {
    emit('get_last_system_message');
  }

  // Search and filtering using isolate
  Future<List<NotificationModel>> searchNotifications(String query) async {
    try {
      final results =
          await _sendToIsolate(
                NotificationIsolateMessage(
                  type: 'search_notifications',
                  data: {'query': query},
                ),
                waitForResponse: true,
              )
              as Map<String, dynamic>;

      final resultsData = List<Map<String, dynamic>>.from(
        results['results'] ?? [],
      );
      return resultsData.map((n) => NotificationModel.fromJson(n)).toList();
    } catch (e) {
      debugPrint('❌ Error searching notifications: $e');
      // Fallback to local search
      if (query.isEmpty) return _notifications;

      final lowerQuery = query.toLowerCase();
      return _notifications.where((notification) {
        return notification.title.toLowerCase().contains(lowerQuery) ||
            (notification.message?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
  }

  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    try {
      final results =
          await _sendToIsolate(
                NotificationIsolateMessage(
                  type: 'filter_by_type',
                  data: {'type': type, 'includeRead': true},
                ),
                waitForResponse: true,
              )
              as Map<String, dynamic>;

      final resultsData = List<Map<String, dynamic>>.from(
        results['results'] ?? [],
      );
      return resultsData.map((n) => NotificationModel.fromJson(n)).toList();
    } catch (e) {
      debugPrint('❌ Error filtering by type: $e');
      // Fallback
      return _notifications
          .where((n) => n.type.toString().contains(type))
          .toList();
    }
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.read).toList();
  }

  // Audio and vibration
  Future<void> _playNotificationSound() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('🔔 Playing notification sound');
    } catch (e) {
      debugPrint('❌ Error playing notification sound: $e');
    }
  }

  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 500);
        debugPrint('📳 Vibrating');
      }
    } catch (e) {
      debugPrint('❌ Error vibrating: $e');
    }
  }

  // Token Monitoring Methods
  void _startTokenMonitoring() {
    if (_tokenMonitoringStarted) return;

    _tokenMonitoringStarted = true;

    _tokenCheckTimer = Timer.periodic(_tokenCheckInterval, (_) async {
      await _checkTokenAndReconnect();
    });

    debugPrint('🔐 Started token monitoring for notifications');
  }

  void _stopTokenMonitoring() {
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = null;
    _tokenMonitoringStarted = false;

    debugPrint('🔐 Stopped token monitoring for notifications');
  }

  Future<void> _checkTokenAndReconnect() async {
    try {
      final token = await tokenManager.getToken();
      final userId = await _getUserIdFromTokenManager();

      if (token != _currentToken || userId != _currentUserId) {
        debugPrint('🔄 Token/user ID changed, reconnecting...');
        await _handleTokenChange(token, userId);
      }

      if (token != null) {
        final isExpired = await tokenManager.isTokenExpired();
        if (isExpired) {
          debugPrint('⚠️ Token expired, disconnecting...');
          disconnect();
          _clearNotificationData();
        }
      } else if (_currentToken != null) {
        debugPrint('⚠️ Token removed, disconnecting...');
        disconnect();
        _clearNotificationData();
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
        _clearNotificationData();
      }
    } catch (e) {
      debugPrint('❌ Error checking initial token: $e');
    }
  }

  Future<void> _handleTokenChange(String? newToken, String? newUserId) async {
    final oldToken = _currentToken;
    final oldUserId = _currentUserId;

    _currentToken = newToken;
    _currentUserId = newUserId;

    if (newToken == null || newUserId == null) {
      debugPrint('🔒 No valid token or user ID, disconnecting...');
      disconnect();
      _clearNotificationData();
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

  void _clearNotificationData() {
    _notifications.clear();
    _lastNotification = null;
    _unreadCount.value = 0;
    _totalCount = 0;
    _notifyListeners();
  }

  // Connection Management
  Future<void> connect() async {
    final token = await tokenManager.getToken();
    final userId = await _getUserIdFromTokenManager();

    if (token == null || userId == null) {
      debugPrint('⚠️ Cannot connect: No token or user ID available');
      return;
    }

    debugPrint('🔌 Connecting to notification socket...');
    await socketService.connect();
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting from notification socket...');
    socketService.disconnect();
  }

  void reconnect() {
    debugPrint('🔄 Reconnecting notification socket...');
    socketService.reconnect();
  }

  // Utility Methods
  void clearError() {
    _error = null;
    socketService.clearError();
    _notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount.value = 0;
    _totalCount = 0;
    _lastNotification = null;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Shutdown isolate
    if (_isolateInitialized) {
      _sendToIsolate(NotificationIsolateMessage(type: 'shutdown'));
      _isolate?.kill(priority: Isolate.immediate);
      _isolateReceivePort?.close();
    }

    _stopTokenMonitoring();
    _pendingHandlers.clear();
    _batchTimer?.cancel();
    _isolateCompleters.clear();

    super.dispose();
  }
}
