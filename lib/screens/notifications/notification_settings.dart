
// // services/notification_preference_service.dart
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/notification_preference.dart';

// class NotificationPreferenceService extends ChangeNotifier {
//   NotificationPreferences? _preferences;
//   bool _preferencesLoading = false;
//   String? _preferencesError;
//   bool _hasUnsavedChanges = false;
  
//   // Push notification states
//   bool _isSubscribed = false;
//   String? _browserPermission;
//   bool? _pushSupported;
//   bool _pushLoading = false;

//   NotificationPreferences? get preferences => _preferences;
//   bool get preferencesLoading => _preferencesLoading;
//   String? get preferencesError => _preferencesError;
//   bool get hasUnsavedChanges => _hasUnsavedChanges;
  
//   bool get isSubscribed => _isSubscribed;
//   String? get browserPermission => _browserPermission;
//   bool? get pushSupported => _pushSupported;
//   bool get pushLoading => _pushLoading;

//   Future<void> loadPreferences() async {
//     _preferencesLoading = true;
//     _preferencesError = null;
//     notifyListeners();

//     try {
//       // TODO: Implement your API call
//       // final response = await http.get(Uri.parse('$apiUrl/notification-preferences'));
//       // if (response.statusCode == 200) {
//       //   _preferences = NotificationPreferences.fromJson(jsonDecode(response.body));
//       // } else {
//       //   throw Exception('Failed to load preferences');
//       // }
      
//       // For now, use mock data
//       await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
//       _preferences = _getMockPreferences();
      
//       // Check push notification status
//       await _checkPushNotificationStatus();
//     } catch (e) {
//       _preferencesError = e.toString();
//     } finally {
//       _preferencesLoading = false;
//       _hasUnsavedChanges = false;
//       notifyListeners();
//     }
//   }

//   void updatePreference(String code, bool enabled) {
//     if (_preferences == null) return;
    
//     final updatedPreferences = _preferences!;
    
//     // Find and update the preference
//     final allPreferences = [
//       ...updatedPreferences.general,
//       ...updatedPreferences.groupActivity,
//       ...updatedPreferences.other,
//     ];
    
//     final preferenceIndex = allPreferences.indexWhere((p) => p.code == code);
//     if (preferenceIndex != -1) {
//       // Update the preference
//       final updatedPreference = allPreferences[preferenceIndex].copyWith(enabled: enabled);
      
//       // Update the appropriate list
//       if (updatedPreferences.general.any((p) => p.code == code)) {
//         final index = updatedPreferences.general.indexWhere((p) => p.code == code);
//         updatedPreferences.general[index] = updatedPreference;
//       } else if (updatedPreferences.groupActivity.any((p) => p.code == code)) {
//         final index = updatedPreferences.groupActivity.indexWhere((p) => p.code == code);
//         updatedPreferences.groupActivity[index] = updatedPreference;
//       } else if (updatedPreferences.other.any((p) => p.code == code)) {
//         final index = updatedPreferences.other.indexWhere((p) => p.code == code);
//         updatedPreferences.other[index] = updatedPreference;
//       }
      
//       _preferences = updatedPreferences;
//       _hasUnsavedChanges = true;
//       notifyListeners();
//     }
//   }

//   void updateQuietHours(QuietHours quietHours) {
//     if (_preferences == null) return;
    
//     _preferences = _preferences!.copyWith(quietHours: quietHours);
//     _hasUnsavedChanges = true;
//     notifyListeners();
//   }

//   Future<void> savePreferences() async {
//     if (_preferences == null) return;
    
//     try {
//       // TODO: Implement your API call
//       // final response = await http.post(
//       //   Uri.parse('$apiUrl/notification-preferences'),
//       //   body: jsonEncode(_preferences!.toJson()),
//       //   headers: {'Content-Type': 'application/json'},
//       // );
//       // 
//       // if (response.statusCode != 200) {
//       //   throw Exception('Failed to save preferences');
//       // }
      
//       await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
//       _hasUnsavedChanges = false;
//       notifyListeners();
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // Push notification methods
//   Future<void> checkBrowserPermission() async {
//     if (kIsWeb) {
//       // Check if browser supports notifications
//       _pushSupported = await _checkBrowserSupport();
      
//       if (_pushSupported!) {
//         // Check current permission
//         final result = await _getNotificationPermission();
//         _browserPermission = result;
//         _isSubscribed = result == 'granted';
//       }
      
//       notifyListeners();
//     }
//   }

//   Future<bool> _checkBrowserSupport() async {
//     if (kIsWeb) {
//       try {
//         // Check if Notification API is available
//         return await _evaluateJavaScript('return "Notification" in window') == 'true';
//       } catch (e) {
//         return false;
//       }
//     }
//     return false;
//   }

//   Future<String> _getNotificationPermission() async {
//     if (kIsWeb) {
//       try {
//         final result = await _evaluateJavaScript('return Notification.permission');
//         return result;
//       } catch (e) {
//         return 'default';
//       }
//     }
//     return 'default';
//   }

//   Future<String> _evaluateJavaScript(String code) async {
//     // For Flutter web, you might need to use dart:js or package:js
//     // This is a simplified version
//     try {
//       // Using MethodChannel for demonstration
//       const platform = MethodChannel('notifications');
//       final result = await platform.invokeMethod('evaluateJavaScript', code);
//       return result.toString();
//     } catch (e) {
//       print('Error evaluating JavaScript: $e');
//       return '';
//     }
//   }

//   Future<void> _checkPushNotificationStatus() async {
//     // This would check with your backend if the user is subscribed
//     // For now, we'll simulate
//     await Future.delayed(const Duration(milliseconds: 100));
//     _isSubscribed = false;
//     notifyListeners();
//   }

//   Future<void> subscribeToPush([int? userId]) async {
//     _pushLoading = true;
//     notifyListeners();

//     try {
//       // For Flutter web, you would typically:
//       // 1. Request permission
//       // 2. Get the subscription token
//       // 3. Send token to your backend
      
//       if (kIsWeb) {
//         // Request notification permission
//         final permission = await _requestNotificationPermission();
        
//         if (permission != 'granted') {
//           throw Exception('Permission not granted');
//         }
        
//         // Update state
//         _browserPermission = permission;
//         _isSubscribed = true;
        
//         // Update the preference
//         updatePreference('PUSH_NOTIFICATIONS', true);
        
//         // TODO: Send subscription to backend
//         // if (userId != null) {
//         //   await http.post(
//         //     Uri.parse('$apiUrl/push/subscribe'),
//         //     body: jsonEncode({'userId': userId, 'token': 'your-token'}),
//         //   );
//         // }
//       }
      
//       // For mobile, you would use Firebase Cloud Messaging
//       // TODO: Implement FCM integration for mobile
      
//     } catch (e) {
//       rethrow;
//     } finally {
//       _pushLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<String> _requestNotificationPermission() async {
//     if (kIsWeb) {
//       try {
//         // Using eval to request permission
//         const platform = MethodChannel('notifications');
//         final result = await platform.invokeMethod('requestNotificationPermission');
//         return result.toString();
//       } catch (e) {
//         print('Error requesting permission: $e');
//         return 'default';
//       }
//     }
//     return 'default';
//   }

//   Future<void> unsubscribeFromPush() async {
//     _pushLoading = true;
//     notifyListeners();

//     try {
//       if (kIsWeb) {
//         // TODO: Implement unsubscribe logic for web
//         // This would typically involve:
//         // 1. Getting the subscription
//         // 2. Unsubscribing
//         // 3. Notifying backend
        
//         _isSubscribed = false;
//         _browserPermission = 'default';
        
//         // Update the preference
//         updatePreference('PUSH_NOTIFICATIONS', false);
        
//         // TODO: Notify backend
//         // await http.post(
//         //   Uri.parse('$apiUrl/push/unsubscribe'),
//         // );
//       }
      
//       // For mobile, unsubscribe from FCM
//       // TODO: Implement FCM unsubscribe
      
//     } catch (e) {
//       rethrow;
//     } finally {
//       _pushLoading = false;
//       notifyListeners();
//     }
//   }

//   // Helper method for mock data
//   NotificationPreferences _getMockPreferences() {
//     return NotificationPreferences(
//       general: [
//         NotificationPreference(
//           code: 'PUSH_NOTIFICATIONS',
//           name: 'Push Notifications',
//           description: 'Receive notifications on your device',
//           category: 'general',
//           enabled: false,
//         ),
//         NotificationPreference(
//           code: 'EMAIL_NOTIFICATIONS',
//           name: 'Email Notifications',
//           description: 'Get updates via email',
//           category: 'general',
//           enabled: true,
//         ),
//       ],
//       groupActivity: [
//         NotificationPreference(
//           code: 'GROUP_MESSAGES',
//           name: 'Group Messages',
//           description: 'New messages in your groups',
//           category: 'group',
//           enabled: true,
//         ),
//         NotificationPreference(
//           code: 'CONTRIBUTION_REMINDERS',
//           name: 'Contribution Reminders',
//           description: 'Reminders for upcoming contributions',
//           category: 'group',
//           enabled: true,
//         ),
//         NotificationPreference(
//           code: 'GROUP_UPDATES',
//           name: 'Group Updates',
//           description: 'Member joins, leaves, and group changes',
//           category: 'group',
//           enabled: true,
//         ),
//       ],
//       other: [
//         NotificationPreference(
//           code: 'SECURITY_ALERTS',
//           name: 'Security Alerts',
//           description: 'Login attempts and security changes',
//           category: 'other',
//           enabled: true,
//         ),
//         NotificationPreference(
//           code: 'MARKETING_EMAILS',
//           name: 'Marketing Emails',
//           description: 'Product updates and promotions',
//           category: 'other',
//           enabled: false,
//         ),
//         NotificationPreference(
//           code: 'WEEKLY_DIGEST',
//           name: 'Weekly Digest',
//           description: 'Summary of your weekly activity',
//           category: 'other',
//           enabled: true,
//         ),
//       ],
//       quietHours: QuietHours(
//         enabled: false,
//         startTime: '22:00',
//         endTime: '07:00',
//       ),
//     );
//   }

//   // For Flutter mobile, you would need these extensions
//   ExtensionNotificationPreferences? _preferencesCopyWith({
//     List<NotificationPreference>? general,
//     List<NotificationPreference>? groupActivity,
//     List<NotificationPreference>? other,
//     QuietHours? quietHours,
//   }) {
//     if (_preferences == null) return null;
    
//     return NotificationPreferences(
//       general: general ?? _preferences!.general,
//       groupActivity: groupActivity ?? _preferences!.groupActivity,
//       other: other ?? _preferences!.other,
//       quietHours: quietHours ?? _preferences!.quietHours,
//     );
//   }
// }

// // Helper class for type safety
// class ExtensionNotificationPreferences extends NotificationPreferences {
//   ExtensionNotificationPreferences({
//     required super.general,
//     required super.groupActivity,
//     required super.other,
//     required super.quietHours,
//   });
// }