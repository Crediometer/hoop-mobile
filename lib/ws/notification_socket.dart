// lib/services/notification_websocket_service.dart
import 'package:flutter/foundation.dart';
import 'package:hoop/dtos/responses/Notifications/notification.dart';
import 'package:hoop/ws/websocket_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:audio_session/audio_session.dart';
import 'package:vibration/vibration.dart';

class NotificationWebSocketService extends BaseWebSocketService {
  List<NotificationModel> _notifications = [];
  NotificationModel? _lastNotification;
  int _unreadCount = 0;
  int _totalCount = 0;
  bool _loading = false;
  String? _error;

  NotificationWebSocketService({
    required super.baseUrl,
    super.namespace = '/notifications',
    super.reconnectInterval = const Duration(seconds: 3),
    super.maxReconnectAttempts = 10,
  });

  // Getters
  List<NotificationModel> get notifications => _notifications;
  NotificationModel? get lastNotification => _lastNotification;
  int get unreadCount => _unreadCount;
  int get totalCount => _totalCount;
  bool get loading => _loading;
  String? get error => _error;

  @override
  void onConnect() {
    debugPrint('Notification socket connected');
    
    // Load initial data
    _loadInitialData();
    
    // Setup specific listeners
    _setupNotificationListeners();
  }

  @override
  void onDisconnect(String reason) {
    debugPrint('Notification socket disconnected: $reason');
  }

  @override
  void onError(dynamic error) {
    _error = error.toString();
    notifyListeners();
  }

  @override
  void onNotification(NotificationModel notification) {
    debugPrint('New notification received: ${notification.title}');
    
    // Add to beginning of list
    _notifications.insert(0, notification);
    _lastNotification = notification;
    _unreadCount++;
    _totalCount++;
    
    // Play sound and vibrate for important notifications
    _playNotificationSound();
    _vibrate();
    
    notifyListeners();
  }

  @override
  void onMessage(ChatMessage message) {
    // Notifications service doesn't handle chat messages
  }

  void _setupNotificationListeners() {
    on('notifications_list', (data) {
      try {
        final notifications = (data as List)
            .map((item) => NotificationModel.fromJson(item))
            .toList();
        
        _notifications = notifications;
        _calculateCounts();
        _loading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing notifications list: $e');
      }
    });

    on('notification_marked_read', (data) {
      final notificationId = data['notificationId'];
      _markAsRead(notificationId);
    });

    on('all_notifications_read', (_) {
      for (final notification in _notifications) {
        notification.read = true;
      }
      _unreadCount = 0;
      notifyListeners();
    });

    on('notification_deleted', (data) {
      final notificationId = data['notificationId'];
      _deleteNotification(notificationId);
    });

    on('counts_updated', (data) {
      _unreadCount = data['unreadCount'] ?? 0;
      _totalCount = data['totalCount'] ?? 0;
      notifyListeners();
    });

    on('last_system_message', (data) {
      if (data != null) {
        _lastNotification = NotificationModel.fromJson(data);
        notifyListeners();
      }
    });
  }

  void _loadInitialData() {
    _loading = true;
    notifyListeners();
    
    emit('get_notifications', {
      'page': 1,
      'limit': 20,
      'unreadOnly': false,
    });
    
    emit('get_counts');
    emit('get_last_system_message');
  }

  void refreshNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) {
    emit('get_notifications', {
      'page': page,
      'limit': limit,
      'unreadOnly': unreadOnly,
    });
  }

  void markAsRead(String notificationId) {
    emit('mark_notification_read', {'notificationId': notificationId});
    _markAsRead(notificationId);
  }

  void _markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].read = true;
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    emit('mark_all_notifications_read');
    for (final notification in _notifications) {
      notification.read = true;
    }
    _unreadCount = 0;
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    emit('delete_notification', {'notificationId': notificationId});
    _deleteNotification(notificationId);
  }

  void _deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _calculateCounts();
    notifyListeners();
  }

  void getCount() {
    emit('get_counts');
  }

  void getSystemLastNotification() {
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
      
      // You would typically play an audio file here
      // For now, we'll just configure the session
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      debugPrint('Error vibrating: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}