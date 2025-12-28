// lib/providers/notification_websocket_handler.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:hoop/dtos/responses/notifications/notification.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hoop/services/websocket_service.dart';
import 'package:vibration/vibration.dart';

class NotificationWebSocketHandler with ChangeNotifier {
  final BaseWebSocketService socketService;
  final TokenManager tokenManager = TokenManager.instance;
  
  // State
  final List<NotificationModel> _notifications = [];
  NotificationModel? _lastNotification;
  int _unreadCount = 0;
  int _totalCount = 0;
  bool _loading = false;
  String? _error;
  String? _currentUserId;
  
  // Pending event handlers (to be registered when socket is ready)
  final List<MapEntry<String, Function(dynamic)>> _pendingHandlers = [];
  
  // Token monitoring
  Timer? _tokenCheckTimer;
  String? _currentToken;
  bool _tokenMonitoringStarted = false;
  final Duration _tokenCheckInterval = const Duration(seconds: 2);

  NotificationWebSocketHandler({
    required this.socketService,
  }) {
    _initialize();
  }

  // Getters
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  NotificationModel? get lastNotification => _lastNotification;
  int get unreadCount => _unreadCount;
  int get totalCount => _totalCount;
  bool get loading => _loading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  
  bool get isConnected => socketService.isConnected;
  bool get isConnecting => socketService.isConnecting;
  String? get connectionError => socketService.connectionError;

  Future<void> _initialize() async {
    // Setup connection event handlers first
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
    _unreadCount = 0;
    _totalCount = 0;
    _notifyListeners();
  }

  // Connection Event Handlers
  void _handleConnected() {
    debugPrint('🎉 Notification socket connected');
    
    // Register all pending event handlers now that socket is connected
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

  // Event Management Methods
  void on(String event, Function(dynamic) handler) {
    debugPrint('📝 Registering event listener for: $event');
    
    if (socketService.socket != null && socketService.isConnected) {
      // Socket is already connected, register immediately
      socketService.socket!.on(event, handler);
      debugPrint('✅ Immediately registered event listener for: $event');
    } else {
      // Socket not ready yet, queue the handler
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

  // Setup notification event handlers (queues them until socket is ready)
  void _setupNotificationHandlers() {
    // Queue event handlers instead of trying to register them immediately
    on('new_notification', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        _handleNewNotification(notification);
      } catch (e) {
        debugPrint('❌ Error parsing new notification: $e');
      }
    });

    on('notifications_list', (data) {
      try {
        final notifications = (data['notifications'] as List)
            .map((item) => NotificationModel.fromJson(item))
            .toList();
        
        _handleNotificationsList(notifications);
      } catch (e) {
        debugPrint('❌ Error parsing notifications list: $e');
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
      final unreadCount = data['unreadCount'] ?? 0;
      final totalCount = data['totalCount'] ?? 0;
      _handleCountsUpdated(unreadCount, totalCount);
    });

    on('last_system_message', (data) {
      if (data != null) {
        _lastNotification = NotificationModel.fromJson(data);
        _notifyListeners();
      }
    });

    on('notification_updated', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        _handleNotificationUpdated(notification);
      } catch (e) {
        debugPrint('❌ Error updating notification: $e');
      }
    });

    on('ping', (_) {
      emit('pong', {'timestamp': DateTime.now().millisecondsSinceEpoch});
    });
  }

  // Notification Event Handlers
  void _handleNewNotification(NotificationModel notification) {
    debugPrint('📬 New notification received: ${notification.title}');
    
    _notifications.insert(0, notification);
    _lastNotification = notification;
    _unreadCount++;
    _totalCount++;
    
    // Always play sound/vibrate for new notifications
    _playNotificationSound();
    _vibrate();
    
    _notifyListeners();
  }

  void _handleNotificationsList(List<NotificationModel> notifications) {
    _notifications.clear();
    _notifications.addAll(notifications);
    _calculateCounts();
    _loading = false;
    
    debugPrint('📋 Loaded ${notifications.length} notifications');
    _notifyListeners();
  }

  void _handleNotificationRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].read = true;
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      
      debugPrint('✅ Marked notification $notificationId as read');
      _notifyListeners();
    }
  }

  void _handleAllNotificationsRead() {
    for (final notification in _notifications) {
      notification.read = true;
    }
    _unreadCount = 0;
    
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

  void _handleCountsUpdated(int unreadCount, int totalCount) {
    _unreadCount = unreadCount;
    _totalCount = totalCount;
    
    debugPrint('📊 Counts updated: $_unreadCount unread, $_totalCount total');
    _notifyListeners();
  }

  void _handleNotificationUpdated(NotificationModel notification) {
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      _notifications[index] = notification;
      _calculateCounts();
      
      debugPrint('🔄 Notification updated: ${notification.title}');
      _notifyListeners();
    }
  }

  // Public API Methods
  void _loadInitialData() {
    _loading = true;
    _notifyListeners();
    
    emit('get_notifications', {
      'page': 1,
      'limit': 20,
      'unreadOnly': false,
    });
    
    emit('get_counts');
    emit('get_last_system_message');
  }

  void refreshNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) {
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

  void _calculateCounts() {
    _unreadCount = _notifications.where((n) => !n.read).length;
    _totalCount = _notifications.length;
  }

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
    _unreadCount = 0;
    _totalCount = 0;
    _lastNotification = null;
    _notifyListeners();
  }

  // Helper methods for UI
  int get readCount => _totalCount - _unreadCount;
  
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;
    
    final lowerQuery = query.toLowerCase();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(lowerQuery) ||
             (notification.message?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.read).toList();
  }

  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type.toString().contains(type)).toList();
  }

  void _notifyListeners() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTokenMonitoring();
    
    // Clear all pending handlers
    _pendingHandlers.clear();
    
    super.dispose();
  }
}