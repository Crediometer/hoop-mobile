// // lib/services/notification_service.dart
// import 'dart:convert';
// import 'package:hoop/dtos/responses/ApiResponse.dart';
// import 'package:hoop/dtos/responses/Notifications/notification.dart';
// import 'package:hoop/services/base_http.dart';

// class NotificationService extends BaseHttpService {
//   NotificationService() : super(baseUrl: 'https://your-api.com/api');

//   // ==================== NOTIFICATION PREFERENCES ====================

//   // Get notification settings
//   Future<ApiResponse<UserPreferencesResponse>> getNotificationSettings() async {
//     return getTyped<UserPreferencesResponse>(
//       'notifications/preferences',
//       fromJson: (json) => UserPreferencesResponse.fromJson(json),
//     );
//   }

//   // Update notification settings
//   Future<ApiResponse<UserPreferencesResponse>> updateNotificationSettings(
//     UserPreferencesRequest request,
//   ) async {
//     return putTyped<UserPreferencesResponse>(
//       'notifications/preferences',
//       body: request.toJson(),
//       fromJson: (json) => UserPreferencesResponse.fromJson(json),
//     );
//   }

//   // Update quiet hours
//   Future<ApiResponse<QuietHours>> updateQuietHours(QuietHours quietHours) async {
//     return putTyped<QuietHours>(
//       'notifications/quiet-hours',
//       body: quietHours.toJson(),
//       fromJson: (json) => QuietHours.fromJson(json),
//     );
//   }

//   // Enable all notifications
//   Future<ApiResponse<UserPreferencesResponse>> enableAllNotifications() async {
//     return postTyped<UserPreferencesResponse>(
//       'notifications/enable-all',
//       fromJson: (json) => UserPreferencesResponse.fromJson(json),
//     );
//   }

//   // Disable all notifications
//   Future<ApiResponse<UserPreferencesResponse>> disableAllNotifications() async {
//     return postTyped<UserPreferencesResponse>(
//       'notifications/disable-all',
//       fromJson: (json) => UserPreferencesResponse.fromJson(json),
//     );
//   }

//   // ==================== PUSH NOTIFICATIONS ====================

//   // Subscribe to push notifications
//   Future<ApiResponse<PushSubscriptionResponse>> subscribeToPush(
//     Map<String, dynamic> subscription,
//     Map<String, dynamic> deviceInfo,
//   ) async {
//     final body = {
//       'subscription': subscription,
//       'deviceInfo': deviceInfo,
//     };

//     return postTyped<PushSubscriptionResponse>(
//       'notifications/push/subscribe',
//       body: body,
//       fromJson: (json) => PushSubscriptionResponse.fromJson(json),
//     );
//   }

//   // Unsubscribe from push notifications
//   Future<ApiResponse<void>> unsubscribeFromPush(String subscriptionId) async {
//     return deleteTyped<void>(
//       'notifications/push/unsubscribe/$subscriptionId',
//       fromJson: (_) => null,
//     );
//   }

//   // Get push subscription status
//   Future<ApiResponse<bool>> getPushSubscriptionStatus() async {
//     return getTyped<bool>(
//       'notifications/push/status',
//       fromJson: (json) => json['isSubscribed'] ?? false,
//     );
//   }

//   // Test push notification
//   Future<ApiResponse<void>> testPushNotification() async {
//     return postTyped<void>(
//       'notifications/push/test',
//       fromJson: (_) => null,
//     );
//   }

//   // ==================== NOTIFICATION HISTORY ====================

//   // Get notifications with pagination
//   Future<ApiResponse<NotificationListResponse>> getNotifications({
//     int page = 1,
//     int limit = 20,
//     bool unreadOnly = false,
//   }) async {
//     final params = {
//       'page': page.toString(),
//       'limit': limit.toString(),
//       'unreadOnly': unreadOnly.toString(),
//     };

//     return getTyped<NotificationListResponse>(
//       'notifications',
//       queryParameters: params,
//       fromJson: (json) => NotificationListResponse.fromJson(json),
//     );
//   }

//   // Mark notification as read
//   Future<ApiResponse<void>> markAsRead(String notificationId) async {
//     return putTyped<void>(
//       'notifications/$notificationId/read',
//       fromJson: (_) => null,
//     );
//   }

//   // Mark all notifications as read
//   Future<ApiResponse<void>> markAllAsRead() async {
//     return putTyped<void>(
//       'notifications/mark-all-read',
//       fromJson: (_) => null,
//     );
//   }

//   // Delete notification
//   Future<ApiResponse<void>> deleteNotification(String notificationId) async {
//     return deleteTyped<void>(
//       'notifications/$notificationId',
//       fromJson: (_) => null,
//     );
//   }

//   // Get notification counts
//   Future<ApiResponse<NotificationCounts>> getNotificationCounts() async {
//     return getTyped<NotificationCounts>(
//       'notifications/counts',
//       fromJson: (json) => NotificationCounts.fromJson(json),
//     );
//   }

//   // Get last system notification
//   Future<ApiResponse<NotificationModel>> getLastSystemNotification() async {
//     return getTyped<NotificationModel>(
//       'notifications/last-system',
//       fromJson: (json) => NotificationModel.fromJson(json),
//     );
//   }

//   // ==================== DEVICE REGISTRATION ====================

//   // Register device for push
//   Future<ApiResponse<void>> registerDevice(Map<String, dynamic> deviceData) async {
//     return postTyped<void>(
//       'notifications/device/register',
//       body: deviceData,
//       fromJson: (_) => null,
//     );
//   }

//   // Unregister device
//   Future<ApiResponse<void>> unregisterDevice(String deviceId) async {
//     return deleteTyped<void>(
//       'notifications/device/$deviceId',
//       fromJson: (_) => null,
//     );
//   }

//   // Get registered devices
//   Future<ApiResponse<List<DeviceInfo>>> getRegisteredDevices() async {
//     return getTyped<List<DeviceInfo>>(
//       'notifications/devices',
//       fromJson: (json) {
//         if (json is List) {
//           return json.map((item) => DeviceInfo.fromJson(item)).toList();
//         }
//         return [];
//       },
//     );
//   }
// }

// // Response models
// class NotificationListResponse {
//   final List<NotificationModel> notifications;
//   final int currentPage;
//   final int totalPages;
//   final int totalItems;
//   final bool hasMore;

//   NotificationListResponse({
//     required this.notifications,
//     required this.currentPage,
//     required this.totalPages,
//     required this.totalItems,
//     required this.hasMore,
//   });

//   factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
//     return NotificationListResponse(
//       notifications: (json['notifications'] as List)
//           .map((item) => NotificationModel.fromJson(item))
//           .toList(),
//       currentPage: json['currentPage'] ?? 1,
//       totalPages: json['totalPages'] ?? 1,
//       totalItems: json['totalItems'] ?? 0,
//       hasMore: json['hasMore'] ?? false,
//     );
//   }
// }

// class NotificationCounts {
//   final int totalCount;
//   final int unreadCount;
//   final int readCount;

//   NotificationCounts({
//     required this.totalCount,
//     required this.unreadCount,
//     required this.readCount,
//   });

//   factory NotificationCounts.fromJson(Map<String, dynamic> json) {
//     return NotificationCounts(
//       totalCount: json['totalCount'] ?? 0,
//       unreadCount: json['unreadCount'] ?? 0,
//       readCount: json['readCount'] ?? 0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'totalCount': totalCount,
//       'unreadCount': unreadCount,
//       'readCount': readCount,
//     };
//   }
// }

// class DeviceInfo {
//   final String id;
//   final String deviceType;
//   final String deviceName;
//   final DateTime registeredAt;
//   final DateTime? lastSeenAt;

//   DeviceInfo({
//     required this.id,
//     required this.deviceType,
//     required this.deviceName,
//     required this.registeredAt,
//     this.lastSeenAt,
//   });

//   factory DeviceInfo.fromJson(Map<String, dynamic> json) {
//     return DeviceInfo(
//       id: json['id'] ?? '',
//       deviceType: json['deviceType'] ?? '',
//       deviceName: json['deviceName'] ?? '',
//       registeredAt: DateTime.parse(json['registeredAt']),
//       lastSeenAt: json['lastSeenAt'] != null 
//           ? DateTime.parse(json['lastSeenAt'])
//           : null,
//     );
//   }
// }