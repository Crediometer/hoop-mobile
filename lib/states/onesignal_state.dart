import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoop/dtos/podos/calls/call_models.dart';
import 'package:hoop/services/callkit_integration.dart';
import 'package:hoop/states/webrtc_manager.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService extends ChangeNotifier {
  // Singleton instance
  static OneSignalService? _instance;
  static OneSignalService get instance {
    _instance ??= OneSignalService._internal();
    return _instance!;
  }

  late WebRTCManager _webrtcManager;
  WebRTCManager get webrtcManager => _webrtcManager;
  // State
  String _debugLabelString = "";
  bool _initialized = false;
  bool _enableConsentButton = false;
  bool _requireConsent = false;
  String? _externalUserId;
  String? _language;
  late CallKitIntegration callKitIntegration;

  // Permission state
  bool _hasPermission = false;
  bool _permissionRequested = false;
  bool _isLoading = false;
  OSNotificationPermission? _permissionStatus;

  // Notification counts
  int _notificationCount = 0;
  int _unreadCount = 0;

  // Getters
  String get debugLabelString => _debugLabelString;
  bool get initialized => _initialized;
  bool get enableConsentButton => _enableConsentButton;
  bool get hasPermission => _hasPermission;
  bool get permissionRequested => _permissionRequested;
  bool get isLoading => _isLoading;
  int get notificationCount => _notificationCount;
  int get unreadCount => _unreadCount;
  OSNotificationPermission? get permissionStatus => _permissionStatus;

  // Notification handlers
  Function(OSNotificationClickEvent)? _onNotificationClick;
  Function(OSNotificationWillDisplayEvent)? _onForegroundNotification;

  // Tags for different notification types
  final Map<String, String> _notificationTags = {};

  // Context for navigation
  BuildContext? _context;

  // Stream controllers for real-time updates
  final StreamController<int> _notificationCountController =
      StreamController<int>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  final StreamController<bool> _permissionController =
      StreamController<bool>.broadcast();

  // Streams
  Stream<int> get notificationCountStream =>
      _notificationCountController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<bool> get permissionStream => _permissionController.stream;

  OneSignalService._internal();

  Future<void> initialize({
    required BuildContext context,
    String? appId,
    bool requireConsent = false,
    Function(OSNotificationClickEvent)? onNotificationClick,
    Function(OSNotificationWillDisplayEvent)? onForegroundNotification,
    bool requestPermissionAutomatically = true,
  }) async {
    if (_initialized) return;

    _context = context;
    _requireConsent = requireConsent;
    _onNotificationClick = onNotificationClick;
    _onForegroundNotification = onForegroundNotification;
    _isLoading = true;
    notifyListeners();

    try {
      // Configure OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      OneSignal.consentRequired(_requireConsent);

      // Initialize with your app ID
      OneSignal.initialize(appId ?? "474a1dcb-a9e3-4671-bce2-5d530387cba3");

      // Set up notification handlers
      _setupNotificationHandlers();

      // Check current permission status
      await _checkPermissionStatus();

      // Request permission automatically if configured
      if (requestPermissionAutomatically &&
          !_hasPermission &&
          !_permissionRequested) {
        // await _requestPermissionWithDialog();
      }

      // Set up live activities
      OneSignal.LiveActivities.setupDefault();

      // Clear all notifications
      OneSignal.Notifications.clearAll();

      _webrtcManager = WebRTCManager();

      _webrtcManager.initialize(
        ChatWebSocketHandler(),
        1,
        "Raji",
      ); // todo: change this
      callKitIntegration = CallKitIntegration();

      callKitIntegration.initialize(webrtcManager);
      // Setup callbacks
      _webrtcManager.onIncomingCall = (callData) {
        debugPrint(
          "📨 Incoming call received via WebRTC : Never allow it able $callData",
        );
        // Send notification via existing chat system
        // audio.play(SynthSoundType.ringtone);
        callKitIntegration.handleIncomingCallFromWebRTC(callData);
        // You can also show a notification or update UI
        // This will be handled by your CallKit integration
      };

      _initialized = true;
    } catch (error) {
      print('Error initializing OneSignal: $error');
      _debugLabelString = 'Error initializing OneSignal: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final status = await OneSignal.Notifications.requestPermission(true);

      _hasPermission = status;
      _permissionController.add(_hasPermission);
      notifyListeners();
      print(
        'Current permission status: $status, Has permission: $_hasPermission',
      );
    } catch (error) {
      print('Error checking permission status: $error');
    }
  }

  Future<bool> requestPermission({bool showDialog = true}) async {
    if (_permissionRequested && _hasPermission) return true;

    _permissionRequested = true;
    _isLoading = true;
    notifyListeners();

    try {
      if (showDialog && _context != null && _context!.mounted) {
        final shouldRequest = await _showPermissionRequestDialog();
        if (!shouldRequest) {
          _isLoading = false;
          _debugLabelString = 'Permission request cancelled.';
          notifyListeners();
          return false;
        }
      }

      final result = await OneSignal.Notifications.requestPermission(true);
      _hasPermission = result;
      _permissionController.add(result);

      if (result) {
        _debugLabelString = 'Permission granted! Notifications enabled.';

        // Subscribe to default topics after permission granted
        await _subscribeToDefaultTopics();

        // Show success message
        if (_context != null && _context!.mounted) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Text('Notifications enabled!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _debugLabelString =
            'Permission denied. You can enable notifications in settings.';

        if (_context != null && _context!.mounted && showDialog) {
          _showPermissionDeniedDialog();
        }
      }

      notifyListeners();
      return result;
    } catch (error) {
      print('Error requesting permission: $error');
      _debugLabelString = 'Error requesting permission: $error';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _showPermissionRequestDialog() async {
    return await showDialog<bool>(
          context: _context!,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Enable Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 48,
                  color: Color(0xFFF97316),
                ),
                SizedBox(height: 16),
                Text(
                  'Stay updated with:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                SizedBox(height: 8),
                _buildPermissionFeature(
                  'Group activities and messages',
                  Icons.people,
                ),
                _buildPermissionFeature(
                  'Payment reminders and updates',
                  Icons.payments,
                ),
                _buildPermissionFeature(
                  'Meeting schedules and alerts',
                  Icons.calendar_today,
                ),
                _buildPermissionFeature(
                  'Important announcements',
                  Icons.announcement,
                ),
                SizedBox(height: 16),
                Text(
                  'Never miss important updates from your groups!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Enable Notifications'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildPermissionFeature(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFFF97316).withOpacity(0.8)),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _subscribeToDefaultTopics() async {
    try {
      await subscribeToTopics([
        'GROUP_STARTED',
        'CONTRIBUTION_RECEIVED',
        'PAYMENT_MISSED',
        'MEETING_SCHEDULED',
        'MENTION',
        'GROUP_GOAL_ACHIEVED',
        'WEEKLY_POLL_UPDATE',
        'SYSTEM_ALERT',
      ]);

      await setNotificationPreferences(
        groupNotifications: true,
        paymentNotifications: true,
        meetingNotifications: true,
        mentionNotifications: true,
        systemNotifications: true,
        goalNotifications: true,
        pollNotifications: true,
      );

      print('Subscribed to default notification topics');
    } catch (error) {
      print('Error subscribing to topics: $error');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text('Notifications Disabled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'To enable notifications and stay updated:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            _buildSettingStep('1. Go to Settings', Icons.settings),
            _buildSettingStep('2. Tap "Notifications"', Icons.notifications),
            _buildSettingStep('3. Find this app', Icons.apps),
            _buildSettingStep('4. Enable notifications', Icons.toggle_on),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF97316),
              foregroundColor: Colors.white,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingStep(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFFF97316)),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    try {
      print('Opening app settings...');

      // Fallback: Show instructions
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('Please enable notifications in your device settings'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
    } catch (error) {
      print('Error opening settings: $error');
    }
  }

  void _setupNotificationHandlers() {
    // Permission observer
    OneSignal.Notifications.addPermissionObserver((state) {
      print("Permission changed: $state");
      _hasPermission = state;
      _permissionController.add(_hasPermission);
      notifyListeners();
    });

    // Push subscription observer
    OneSignal.User.pushSubscription.addObserver((state) {
      print('Push Subscription Changed:');
      print('Opted In: ${OneSignal.User.pushSubscription.optedIn}');
      print('ID: ${OneSignal.User.pushSubscription.id}');
      print('Token: ${OneSignal.User.pushSubscription.token}');
      notifyListeners();
    });

    // User observer
    OneSignal.User.addObserver((state) {
      print('OneSignal user changed: ${state.jsonRepresentation()}');
      notifyListeners();
    });

    // Notification click listener
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICKED: ${event.notification.jsonRepresentation()}');

      // Update unread count
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      _unreadCountController.add(_unreadCount);

      // Call custom handler if provided
      _onNotificationClick?.call(event);

      // Update debug label
      _debugLabelString =
          "Clicked notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      notifyListeners();

      // Handle different notification types
      _handleNotificationClick(event);
    });

    // Foreground notification listener
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('FOREGROUND NOTIFICATION: ${event.notification.additionalData}');

      // Update counts
      _notificationCount++;
      _unreadCount++;
      _notificationCountController.add(_notificationCount);
      _unreadCountController.add(_unreadCount);

      if (event.notification.rawPayload?['type'] == 'call') {
        // destiny...
        _webrtcManager.setIncomingCall(
          CallData.fromJson(event.notification.rawPayload!),
        );
      } else {
        // Call custom handler if provided
        _onForegroundNotification?.call(event);
      }
      //

      // Update debug label
      _debugLabelString =
          "Notification received: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      notifyListeners();
    });

    // In-app message listeners
    _setupInAppMessageHandlers();
  }

  // In OneSignalService class

  Future<void> subscribeToGroupTags(List<num> groupIds) async {
    try {
      final tags = <String, String>{};

      for (final groupId in groupIds) {
        // Format: group_8 -> true
        tags['group_$groupId'] = 'true';
      }

      await OneSignal.User.addTags(tags);

      // Update local cache
      _notificationTags.addAll(tags);

      print('✅ Subscribed to group tags: ${tags.keys.join(', ')}');
      notifyListeners();
    } catch (error) {
      print('❌ Error subscribing to group tags: $error');
    }
  }

  Future<void> unsubscribeFromGroupTags(List<num> groupIds) async {
    try {
      for (final groupId in groupIds) {
        await OneSignal.User.removeTag('group_$groupId');
        _notificationTags.remove('group_$groupId');
      }

      print(
        '✅ Unsubscribed from group tags: ${groupIds.map((id) => 'group_$id').join(', ')}',
      );
      notifyListeners();
    } catch (error) {
      print('❌ Error unsubscribing from group tags: $error');
    }
  }

  void _setupInAppMessageHandlers() {
    OneSignal.InAppMessages.addClickListener((event) {
      _debugLabelString =
          "In App Message Clicked: \n${event.result.jsonRepresentation().replaceAll("\\n", "\n")}";
      notifyListeners();
    });

    OneSignal.InAppMessages.addWillDisplayListener((event) {
      print("WILL DISPLAY IN APP MESSAGE ${event.message.messageId}");
    });

    OneSignal.InAppMessages.addDidDisplayListener((event) {
      print("DID DISPLAY IN APP MESSAGE ${event.message.messageId}");
    });
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    final notification = event.notification;
    final additionalData = notification.additionalData;

    if (additionalData != null) {
      final type = additionalData['type']?.toString();
      final action = additionalData['action']?.toString();
      final payload = additionalData['payload']?.toString();

      print('Notification Type: $type, Action: $action, Payload: $payload');

      // Handle navigation based on type
      _handleNotificationNavigation(type, additionalData);
    }
  }

  void _handleNotificationNavigation(String? type, Map<String, dynamic> data) {
    if (_context == null || !_context!.mounted) return;

    switch (type) {
      case 'GROUP_STARTED':
        // Navigate to group
        break;
      case 'CONTRIBUTION_RECEIVED':
      case 'PAYMENT_MISSED':
        // Navigate to payments
        break;
      case 'MEETING_SCHEDULED':
        // Navigate to meetings
        break;
      case 'MENTION':
        // Navigate to chat
        break;
      // Add more cases as needed
    }
  }

  // Public API Methods

  Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      // await OneSignal.User.addTag("topic_$topic", "subscribed");
    }
    _notificationTags.addAll({
      for (var topic in topics) "topic_$topic": "subscribed",
    });
    notifyListeners();
  }

  Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      await OneSignal.User.removeTag("topic_$topic");
    }
    topics.forEach((topic) => _notificationTags.remove("topic_$topic"));
    notifyListeners();
  }

  Future<void> setNotificationPreferences({
    bool? groupNotifications,
    bool? paymentNotifications,
    bool? meetingNotifications,
    bool? mentionNotifications,
    bool? systemNotifications,
    bool? goalNotifications,
    bool? pollNotifications,
  }) async {
    final Map<String, String> tags = {};

    if (groupNotifications != null) {
      tags['pref_group'] = groupNotifications.toString();
    }
    if (paymentNotifications != null) {
      tags['pref_payment'] = paymentNotifications.toString();
    }
    if (meetingNotifications != null) {
      tags['pref_meeting'] = meetingNotifications.toString();
    }
    if (mentionNotifications != null) {
      tags['pref_mention'] = mentionNotifications.toString();
    }
    if (systemNotifications != null) {
      tags['pref_system'] = systemNotifications.toString();
    }
    if (goalNotifications != null) {
      tags['pref_goal'] = goalNotifications.toString();
    }
    if (pollNotifications != null) {
      tags['pref_poll'] = pollNotifications.toString();
    }

    await OneSignal.User.addTags(tags);
    _notificationTags.addAll(tags);
    notifyListeners();
  }

  Future<void> login(String externalUserId) async {
    _externalUserId = externalUserId;
    await OneSignal.login(externalUserId);
    notifyListeners();
  }

  Future<void> logout() async {
    await OneSignal.logout();
    _externalUserId = null;
    notifyListeners();
  }

  Future<void> setEmail(String email) async {
    await OneSignal.User.addEmail(email);
    notifyListeners();
  }

  Future<void> setSMS(String sms) async {
    await OneSignal.User.addSms(sms);
    notifyListeners();
  }

  Future<void> addTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
    _notificationTags.addAll(tags);
    notifyListeners();
  }

  Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
    keys.forEach((key) => _notificationTags.remove(key));
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await OneSignal.User.setLanguage(language);
    notifyListeners();
  }

  void giveConsent() {
    OneSignal.consentGiven(true);
    _enableConsentButton = false;
    notifyListeners();
  }

  Future<void> setLocationShared(bool shared) async {
    await OneSignal.Location.setShared(shared);
    notifyListeners();
  }

  Future<void> optIn() async {
    await OneSignal.User.pushSubscription.optIn();
    notifyListeners();
  }

  Future<void> optOut() async {
    await OneSignal.User.pushSubscription.optOut();
    notifyListeners();
  }

  Future<void> startLiveActivity(
    String activityId,
    Map<String, dynamic> data,
  ) async {
    await OneSignal.LiveActivities.startDefault(activityId, {
      "title": "Live Activity",
    }, data);
  }

  Future<void> enterLiveActivity(String activityId, String token) async {
    await OneSignal.LiveActivities.enterLiveActivity(activityId, token);
  }

  Future<void> exitLiveActivity(String activityId) async {
    await OneSignal.LiveActivities.exitLiveActivity(activityId);
  }

  // Getters
  Future<String?> getExternalId() async {
    return await OneSignal.User.getExternalId();
  }

  Future<String?> getOneSignalId() async {
    return await OneSignal.User.getOnesignalId();
  }

  Future<Map<String, dynamic>?> getTags() async {
    return await OneSignal.User.getTags();
  }

  // Notification factory methods
  static Map<String, dynamic> createNotificationData({
    required String type,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? payload,
    List<Map<String, dynamic>>? actions,
  }) {
    final data = {
      'type': type,
      'title': title,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (payload != null) 'payload': payload,
      if (actions != null) 'actions': actions,
    };

    return data;
  }

  // Reset counts
  void resetCounts() {
    _notificationCount = 0;
    _unreadCount = 0;
    _notificationCountController.add(0);
    _unreadCountController.add(0);
    notifyListeners();
  }

  // Update context
  void updateContext(BuildContext context) {
    _context = context;
  }

  @override
  void dispose() {
    _notificationCountController.close();
    _unreadCountController.close();
    _permissionController.close();
    super.dispose();
  }
}
