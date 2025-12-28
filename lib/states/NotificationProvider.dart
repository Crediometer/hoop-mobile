// // lib/providers/notification_provider.dart
// import 'package:flutter/foundation.dart';
// import 'package:hoop/dtos/podos/tokens/token_manager.dart';
// import 'dart:async';
// import 'package:hoop/dtos/responses/notifications/notification.dart';
// import 'package:audio_session/audio_session.dart';
// import 'package:hoop/services/websocket_service.dart';
// import 'package:hoop/states/ws/notification_socket.dart';
// import 'package:vibration/vibration.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// // Assuming these types exist, if not we need to define them
// // import 'package:hoop/dtos/responses/notifications/notification_preference.dart';
// // import 'package:hoop/dtos/responses/notifications/quiet_hours.dart';

// class NotificationPreferences {
//   // Define your notification preferences structure here
//   // This should match your actual model
// }

// class QuietHours {
//   // Define your quiet hours structure here
//   // This should match your actual model
// }

// class NotificationProvider with ChangeNotifier {
//   // Use NotificationWebSocketHandler instead of NotificationWebSocketService
//   late NotificationWebSocketHandler _socketHandler;
//   bool _socketInitialized = false;
//   Timer? _tokenCheckTimer;
  
//   // Notification state (these will be synced from the handler)
//   List<NotificationModel> _notifications = [];
//   NotificationModel? _lastNotification;
//   int _unreadCount = 0;
//   int _readCount = 0;
//   int _totalCount = 0;
//   bool _loading = false;
//   String? _error;
  
//   // Preference state
//   late NotificationPreferenceService _preferenceService;
//   bool _preferencesLoading = false;
//   String? _preferencesError;
//   bool _hasUnsavedChanges = false;
  
//   // Pagination
//   int _currentPage = 1;
//   bool _hasMore = true;
  
//   // Getters
//   List<NotificationModel> get notifications => _notifications;
//   NotificationModel? get lastNotification => _lastNotification;
//   int get unreadCount => _unreadCount;
//   int get readCount => _readCount;
//   int get totalCount => _totalCount;
//   bool get loading => _loading;
//   String? get error => _error;
  
//   // Delegate to socket handler
//   bool get isConnected => _socketHandler.isConnected;
//   bool get isConnecting => _socketHandler.isConnecting;
//   String? get connectionError => _socketHandler.connectionError;
  
//   NotificationPreferences? get preferences => _preferenceService.preferences;
//   bool get preferencesLoading => _preferenceService.preferencesLoading;
//   String? get preferencesError => _preferenceService.preferencesError;
//   bool get hasUnsavedChanges => _hasUnsavedChanges;
  
//   bool get isSubscribed => _preferenceService.isSubscribed;
//   String? get browserPermission => _preferenceService.browserPermission;
//   bool? get pushSupported => _preferenceService.pushSupported;
//   bool get pushLoading => _preferenceService.pushLoading;
  
//   int get currentPage => _currentPage;
//   bool get hasMore => _hasMore;

//   NotificationProvider({
//     required String baseUrl,
//     String namespace = '/notifications',
//   }) {
//     // Create base socket service
//     final baseSocketService = BaseWebSocketService(
//       baseUrl: baseUrl,
//       namespace: namespace,
//     );
    
//     // Create the notification web socket handler
//     _socketHandler = NotificationWebSocketHandler(
//       socketService: baseSocketService,
//       tokenManager: TokenManager.instance,
//     );
    
//     _preferenceService = NotificationPreferenceService();
    
//     // Listen to socket handler changes
//     _socketHandler.addListener(_onSocketHandlerChange);
    
//     // Listen to preference service changes
//     _preferenceService.addListener(_onPreferenceChange);
    
//     // Initialize
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     await loadPreferences();
//     _socketInitialized = true;
//   }

//   void _onSocketHandlerChange() {
//     // Update state from socket handler
//     _notifications = _socketHandler.notifications;
//     _lastNotification = _socketHandler.lastNotification;
//     _unreadCount = _socketHandler.unreadCount;
//     _totalCount = _socketHandler.totalCount;
//     _loading = _socketHandler.loading;
//     _error = _socketHandler.error;
    
//     // Calculate read count
//     _readCount = _totalCount - _unreadCount;
    
//     notifyListeners();
//   }

//   void _onPreferenceChange() {
//     // Update hasUnsavedChanges flag
//     // Note: You might want to implement logic to track changes
//     // For now, we'll keep it simple
//     notifyListeners();
//   }

//   // Token management
//   Future<String?> _getToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getString('authToken');
//     } catch (e) {
//       debugPrint('Error getting token: $e');
//       return null;
//     }
//   }

//   Future<String?> _getUserIdFromToken() async {
//     try {
//       final token = await _getToken();
//       if (token == null) return null;

//       final parts = token.split('.');
//       if (parts.length != 3) return null;

//       final payload = parts[1];
//       final normalized = base64Url.normalize(payload);
//       final decoded = utf8.decode(base64Url.decode(normalized));
//       final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
//       return payloadMap['userId']?.toString() ?? payloadMap['sub']?.toString();
//     } catch (e) {
//       debugPrint('Error parsing token: $e');
//       return null;
//     }
//   }

//   // Socket connection management
//   Future<void> connect() async {
//     if (_socketHandler.isConnected || _socketHandler.isConnecting) return;
    
//     await _socketHandler.connect();
//   }

//   void disconnect() {
//     _socketHandler.disconnect();
//   }

//   void reconnect() {
//     _socketHandler.reconnect();
//   }

//   // Notification methods
//   void refreshNotifications({int page = 1, int limit = 20, bool unreadOnly = false}) {
//     _socketHandler.refreshNotifications(
//       page: page,
//       limit: limit,
//       unreadOnly: unreadOnly,
//     );
//   }

//   void markAsRead(String notificationId) {
//     _socketHandler.markAsRead(notificationId);
//   }

//   void markAllAsRead() {
//     _socketHandler.markAllAsRead();
//   }

//   void deleteNotification(String notificationId) {
//     _socketHandler.deleteNotification(notificationId);
//   }

//   void getCount() {
//     _socketHandler.getCount();
//   }

//   void getSystemLastNotification() {
//     _socketHandler.getLastSystemNotification();
//   }

//   // Load more notifications for pagination
//   Future<void> loadMoreNotifications({bool unreadOnly = false}) async {
//     if (!_hasMore || _loading) return;
    
//     _loading = true;
//     notifyListeners();
    
//     try {
//       final nextPage = _currentPage + 1;
//       // You might need to implement pagination logic here
//       // This would typically call an HTTP endpoint for paginated results
      
//       // For now, we'll just refresh with socket
//       refreshNotifications(page: nextPage, unreadOnly: unreadOnly);
//       _currentPage = nextPage;
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _loading = false;
//       notifyListeners();
//     }
//   }

//   // Play notification sound
//   Future<void> playNotificationSound() async {
//     try {
//       final session = await AudioSession.instance;
//       await session.configure(const AudioSessionConfiguration.music());
      
//       // Play sound using audio players package
//       // Example with just_audio:
//       // final player = AudioPlayer();
//       // await player.setAsset('assets/sounds/notification.mp3');
//       // await player.play();
//     } catch (e) {
//       debugPrint('Error playing notification sound: $e');
//     }
//   }

//   // Vibrate
//   Future<void> vibrate() async {
//     try {
//       if (await Vibration.hasVibrator() ?? false) {
//         await Vibration.vibrate(duration: 500);
//       }
//     } catch (e) {
//       debugPrint('Error vibrating: $e');
//     }
//   }

//   // Filter notifications by type
//   List<NotificationModel> getNotificationsByType(String type) {
//     return _notifications.where((n) => n.type?.toString() == type).toList();
//   }

//   // Filter notifications by search query
//   List<NotificationModel> searchNotifications(String query) {
//     if (query.isEmpty) return _notifications;
    
//     final lowerQuery = query.toLowerCase();
//     return _notifications.where((notification) {
//       return notification.title.toLowerCase().contains(lowerQuery) ||
//              (notification.body?.toLowerCase().contains(lowerQuery) ?? false);
//     }).toList();
//   }

//   // Get notification by ID
//   NotificationModel? getNotificationById(String id) {
//     return _notifications.firstWhere((n) => n.id == id);
//   }

//   // Get notification statistics
//   Map<String, int> getNotificationStats() {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
    
//     final todayNotifications = _notifications.where((n) => 
//       n.createdAt.isAfter(today)
//     ).length;
    
//     final thisWeekNotifications = _notifications.where((n) => 
//       n.createdAt.isAfter(now.subtract(const Duration(days: 7)))
//     ).length;
    
//     final highPriorityNotifications = _notifications.where((n) => 
//       n.priority == NotificationPriority.HIGH || 
//       n.priority == NotificationPriority.URGENT
//     ).length;
    
//     return {
//       'today': todayNotifications,
//       'thisWeek': thisWeekNotifications,
//       'highPriority': highPriorityNotifications,
//       'total': _totalCount,
//       'unread': _unreadCount,
//       'read': _readCount,
//     };
//   }

//   // Preference methods
//   Future<void> loadPreferences() async {
//     await _preferenceService.loadPreferences();
//   }

//   Future<void> updatePreference(String code, bool enabled) async {
//     _preferenceService.updatePreference(code, enabled);
//     _hasUnsavedChanges = true;
//     notifyListeners();
//   }

//   Future<void> updateQuietHours(QuietHours quietHours) async {
//     _preferenceService.updateQuietHours(quietHours);
//     _hasUnsavedChanges = true;
//     notifyListeners();
//   }

//   Future<void> savePreferences() async {
//     try {
//       await _preferenceService.savePreferences();
//       _hasUnsavedChanges = false;
//       notifyListeners();
//       // Show success toast
//     } catch (e) {
//       // Show error toast
//       rethrow;
//     }
//   }

//   void resetPreferences() {
//     // Note: You'll need to implement reset logic in preference service
//     _hasUnsavedChanges = false;
//     notifyListeners();
//   }

//   Future<void> enableAllNotifications() async {
//     await _preferenceService.enableAllNotifications();
//     _hasUnsavedChanges = false;
//     notifyListeners();
//   }

//   Future<void> disableAllNotifications() async {
//     await _preferenceService.disableAllNotifications();
//     _hasUnsavedChanges = false;
//     notifyListeners();
//   }

//   // Push notification methods
//   Future<void> checkBrowserPermission() async {
//     await _preferenceService.checkBrowserPermission();
//   }

//   Future<void> subscribeToPush() async {
//     await _preferenceService.subscribeToPush();
//   }

//   Future<void> unsubscribeFromPush() async {
//     await _preferenceService.unsubscribeFromPush();
//   }

//   Future<void> testPushNotification() async {
//     // Implement test push notification
//   }

//   // Clear error
//   void clearError() {
//     _error = null;
//     _socketHandler.clearError();
//     notifyListeners();
//   }

//   // Clear notifications
//   void clearNotifications() {
//     _socketHandler.clearNotifications();
//   }

//   @override
//   void dispose() {
//     _socketHandler.removeListener(_onSocketHandlerChange);
//     _preferenceService.removeListener(_onPreferenceChange);
//     _socketHandler.dispose();
//     _tokenCheckTimer?.cancel();
//     super.dispose();
//   }
// }