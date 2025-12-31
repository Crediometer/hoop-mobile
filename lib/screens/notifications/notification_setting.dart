import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/constants/themes.dart';

// Models
class NotificationPreference {
  final String code;
  final String name;
  final String description;
  final String category;
  final bool enabled;

  NotificationPreference({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.enabled,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'description': description,
    'category': category,
    'enabled': enabled,
  };

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      enabled: json['enabled'] ?? false,
    );
  }

  NotificationPreference copyWith({
    String? code,
    String? name,
    String? description,
    String? category,
    bool? enabled,
  }) {
    return NotificationPreference(
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
    );
  }
}

class QuietHours {
  final bool enabled;
  final String startTime;
  final String endTime;

  const QuietHours({
    this.enabled = false,
    this.startTime = '22:00',
    this.endTime = '07:00',
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'startTime': startTime,
    'endTime': endTime,
  };

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      enabled: json['enabled'] ?? false,
      startTime: json['startTime'] ?? '22:00',
      endTime: json['endTime'] ?? '07:00',
    );
  }

  QuietHours copyWith({bool? enabled, String? startTime, String? endTime}) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class NotificationPreferences {
  final List<NotificationPreference> general;
  final List<NotificationPreference> groupActivity;
  final List<NotificationPreference> other;
  final QuietHours quietHours;
  final bool hasUnsavedChanges;

  NotificationPreferences({
    this.general = const [],
    this.groupActivity = const [],
    this.other = const [],
    this.quietHours = const QuietHours(),
    this.hasUnsavedChanges = false,
  });

  Map<String, dynamic> toJson() => {
    'general': general.map((pref) => pref.toJson()).toList(),
    'groupActivity': groupActivity.map((pref) => pref.toJson()).toList(),
    'other': other.map((pref) => pref.toJson()).toList(),
    'quietHours': quietHours.toJson(),
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      general:
          (json['general'] as List?)
              ?.map((item) => NotificationPreference.fromJson(item))
              .toList() ??
          [],
      groupActivity:
          (json['groupActivity'] as List?)
              ?.map((item) => NotificationPreference.fromJson(item))
              .toList() ??
          [],
      other:
          (json['other'] as List?)
              ?.map((item) => NotificationPreference.fromJson(item))
              .toList() ??
          [],
      quietHours: json['quietHours'] != null
          ? QuietHours.fromJson(json['quietHours'])
          : QuietHours(),
    );
  }

  NotificationPreferences copyWith({
    List<NotificationPreference>? general,
    List<NotificationPreference>? groupActivity,
    List<NotificationPreference>? other,
    QuietHours? quietHours,
    bool? hasUnsavedChanges,
  }) {
    return NotificationPreferences(
      general: general ?? this.general,
      groupActivity: groupActivity ?? this.groupActivity,
      other: other ?? this.other,
      quietHours: quietHours ?? this.quietHours,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

// Notification codes
class NotificationCodes {
  static const String PUSH_NOTIFICATIONS = 'push_notifications';
  static const String EMAIL_NOTIFICATIONS = 'email_notifications';
  static const String GROUP_MESSAGES = 'group_messages';
  static const String CONTRIBUTION_REMINDERS = 'contribution_reminders';
  static const String GROUP_UPDATES = 'group_updates';
  static const String SECURITY_ALERTS = 'security_alerts';
  static const String MARKETING_EMAILS = 'marketing_emails';
  static const String WEEKLY_DIGEST = 'weekly_digest';
}

// Custom Switch Widget
class NotificationSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;
  final Color? activeColor;

  const NotificationSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? (disabled
                    ? Colors.grey
                    : (activeColor ?? HoopTheme.primaryBlue))
              : (disabled ? Colors.grey.shade300 : Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            Positioned(
              left: value ? 22 : 2,
              top: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPreferences _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Push notification states (simulated for web comparison)
  bool _pushSupported = true;
  bool _isSubscribed = false;
  bool _browserPermissionGranted = false;
  bool _browserPermissionDenied = false;
  bool _loadingPush = false;

  @override
  void initState() {
    super.initState();
    _preferences = NotificationPreferences();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // TODO: Replace with actual API call
      // final preferences = await yourNotificationService.loadPreferences();

      // For now, create default preferences
      final defaultPreferences = NotificationPreferences(
        general: [
          NotificationPreference(
            code: NotificationCodes.PUSH_NOTIFICATIONS,
            name: 'Push Notifications',
            description: 'Receive notifications on your device',
            category: 'general',
            enabled: false,
          ),
          NotificationPreference(
            code: NotificationCodes.EMAIL_NOTIFICATIONS,
            name: 'Email Notifications',
            description: 'Get updates via email',
            category: 'general',
            enabled: true,
          ),
        ],
        groupActivity: [
          NotificationPreference(
            code: NotificationCodes.GROUP_MESSAGES,
            name: 'Group Messages',
            description: 'New messages in your groups',
            category: 'group',
            enabled: true,
          ),
          NotificationPreference(
            code: NotificationCodes.CONTRIBUTION_REMINDERS,
            name: 'Contribution Reminders',
            description: 'Reminders for upcoming contributions',
            category: 'group',
            enabled: true,
          ),
          NotificationPreference(
            code: NotificationCodes.GROUP_UPDATES,
            name: 'Group Updates',
            description: 'Member joins, leaves, and group changes',
            category: 'group',
            enabled: true,
          ),
        ],
        other: [
          NotificationPreference(
            code: NotificationCodes.SECURITY_ALERTS,
            name: 'Security Alerts',
            description: 'Login attempts and security changes',
            category: 'other',
            enabled: true,
          ),
          NotificationPreference(
            code: NotificationCodes.MARKETING_EMAILS,
            name: 'Marketing Emails',
            description: 'Product updates and promotions',
            category: 'other',
            enabled: false,
          ),
          NotificationPreference(
            code: NotificationCodes.WEEKLY_DIGEST,
            name: 'Weekly Digest',
            description: 'Summary of your weekly activity',
            category: 'other',
            enabled: true,
          ),
        ],
        quietHours: QuietHours(
          enabled: false,
          startTime: '22:00',
          endTime: '07:00',
        ),
      );

      setState(() {
        _preferences = defaultPreferences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load preferences: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    // TODO: Replace with actual API call
    // try {
    //   await yourNotificationService.savePreferences(_preferences);
    //   setState(() {
    //     _preferences = _preferences.copyWith(hasUnsavedChanges: false);
    //   });
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Failed to save preferences'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _preferences = _preferences.copyWith(hasUnsavedChanges: false);
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification settings saved successfully'),
        backgroundColor: HoopTheme.successGreen,
      ),
    );
  }

  void _updatePreference(String code, bool enabled) {
    final updatedGeneral = _preferences.general.map((pref) {
      if (pref.code == code) {
        return pref.copyWith(enabled: enabled);
      }
      return pref;
    }).toList();

    final updatedGroupActivity = _preferences.groupActivity.map((pref) {
      if (pref.code == code) {
        return pref.copyWith(enabled: enabled);
      }
      return pref;
    }).toList();

    final updatedOther = _preferences.other.map((pref) {
      if (pref.code == code) {
        return pref.copyWith(enabled: enabled);
      }
      return pref;
    }).toList();

    setState(() {
      _preferences = _preferences.copyWith(
        general: updatedGeneral,
        groupActivity: updatedGroupActivity,
        other: updatedOther,
        hasUnsavedChanges: true,
      );
    });
  }

  void _updateQuietHours(QuietHours quietHours) {
    setState(() {
      _preferences = _preferences.copyWith(
        quietHours: quietHours,
        hasUnsavedChanges: true,
      );
    });
  }

  // Simulate push notification toggle (web equivalent)
  Future<void> _togglePushNotifications() async {
    if (_loadingPush) return;

    setState(() {
      _loadingPush = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!_isSubscribed) {
      // Request permission
      final granted = await _requestNotificationPermission();
      if (granted) {
        setState(() {
          _isSubscribed = true;
          _browserPermissionGranted = true;
          _browserPermissionDenied = false;
        });
        _updatePreference(NotificationCodes.PUSH_NOTIFICATIONS, true);
      } else {
        setState(() {
          _browserPermissionDenied = true;
          _browserPermissionGranted = false;
        });
      }
    } else {
      // Unsubscribe
      setState(() {
        _isSubscribed = false;
        _browserPermissionGranted = false;
      });
      _updatePreference(NotificationCodes.PUSH_NOTIFICATIONS, false);
    }

    setState(() {
      _loadingPush = false;
    });
  }

  Future<bool> _requestNotificationPermission() async {
    // This is a simulation - in a real app, you'd use a package like permission_handler
    // For web comparison, we'll simulate the permission request
    // return await Permission.notification.request().isGranted;

    // Simulate permission dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Allow notifications'),
        content: Text('Allow this app to send you notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Block'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Allow'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  List<String> _generateTimeOptions() {
    return List.generate(24, (index) {
      final hour = index.toString().padLeft(2, '0');
      return '$hour:00';
    });
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
         HoopBackButton(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  color: HoopTheme.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Manage your notification preferences',
                style: TextStyle(
                  color: HoopTheme.getTextSecondary(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HoopTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading preferences...',
            style: TextStyle(
              color: HoopTheme.getTextSecondary(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error loading preferences',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadPreferences, child: Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildGeneralNotificationsSection() {
    final pushNotification = _preferences.general.firstWhere(
      (pref) => pref.code == NotificationCodes.PUSH_NOTIFICATIONS,
      orElse: () => NotificationPreference(
        code: NotificationCodes.PUSH_NOTIFICATIONS,
        name: 'Push Notifications',
        description: 'Receive notifications on your device',
        category: 'general',
        enabled: false,
      ),
    );

    final emailNotification = _preferences.general.firstWhere(
      (pref) => pref.code == NotificationCodes.EMAIL_NOTIFICATIONS,
      orElse: () => NotificationPreference(
        code: NotificationCodes.EMAIL_NOTIFICATIONS,
        name: 'Email Notifications',
        description: 'Get updates via email',
        category: 'general',
        enabled: true,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Browser Support Warning
        if (!_pushSupported)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.yellow.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notifications Unsupported',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your browser does not support push notifications. Try using a modern browser like Chrome, Firefox, or Edge.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Browser Permission Alert
        if (_pushSupported && _browserPermissionDenied)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_off, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Push Notifications Blocked',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To receive notifications, please enable them in your browser settings.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('How to Enable Notifications'),
                        content: Text(
                          'To enable notifications:\n\n'
                          '1. Click the lock icon in your browser address bar\n'
                          '2. Click "Site settings"\n'
                          '3. Change "Notifications" to "Allow"',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  child: Text('How to Enable', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        // Enable Push Notification Prompt
        if (_pushSupported && !_browserPermissionGranted && !_isSubscribed)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Push Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay updated with real-time notifications. Use the toggle below to enable.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Notifications Enabled Banner
        if (_pushSupported && _browserPermissionGranted && _isSubscribed)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications Enabled',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ll receive push notifications on this device.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        Container(
          decoration: BoxDecoration(
            // color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Push Notifications
              _buildNotificationItem(
                title: pushNotification.name,
                description: _pushSupported
                    ? (_browserPermissionDenied
                          ? 'Blocked - Enable in browser settings'
                          : (_browserPermissionGranted
                                ? 'Receive notifications on your device'
                                : 'Allow notifications to stay updated'))
                    : 'Not supported in this browser',
                icon: Icons.smartphone,
                enabled: _isSubscribed,
                onChanged: (_) => _togglePushNotifications(),
                loading: _loadingPush,
                disabled: !_pushSupported,
                iconColor: _pushSupported && !_browserPermissionDenied
                    ? HoopTheme.primaryBlue
                    : Colors.grey,
              ),

              // Email Notifications
              _buildNotificationItem(
                title: emailNotification.name,
                description: emailNotification.description,
                icon: Icons.mail,
                enabled: emailNotification.enabled,
                onChanged: (value) =>
                    _updatePreference(emailNotification.code, value),
                iconColor: HoopTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupNotificationsSection() {
    final groupNotifications = [
      _preferences.groupActivity.firstWhere(
        (pref) => pref.code == NotificationCodes.GROUP_MESSAGES,
        orElse: () => NotificationPreference(
          code: NotificationCodes.GROUP_MESSAGES,
          name: 'Group Messages',
          description: 'New messages in your groups',
          category: 'group',
          enabled: true,
        ),
      ),
      _preferences.groupActivity.firstWhere(
        (pref) => pref.code == NotificationCodes.CONTRIBUTION_REMINDERS,
        orElse: () => NotificationPreference(
          code: NotificationCodes.CONTRIBUTION_REMINDERS,
          name: 'Contribution Reminders',
          description: 'Reminders for upcoming contributions',
          category: 'group',
          enabled: true,
        ),
      ),
      _preferences.groupActivity.firstWhere(
        (pref) => pref.code == NotificationCodes.GROUP_UPDATES,
        orElse: () => NotificationPreference(
          code: NotificationCodes.GROUP_UPDATES,
          name: 'Group Updates',
          description: 'Member joins, leaves, and group changes',
          category: 'group',
          enabled: true,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Activity',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            // color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            children: groupNotifications.map((notification) {
              return _buildNotificationItem(
                title: notification.name,
                description: notification.description,
                icon: _getIconForNotification(notification.code),
                enabled: notification.enabled,
                onChanged: (value) =>
                    _updatePreference(notification.code, value),
                iconColor: HoopTheme.successGreen,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherNotificationsSection() {
    final otherNotifications = [
      _preferences.other.firstWhere(
        (pref) => pref.code == NotificationCodes.SECURITY_ALERTS,
        orElse: () => NotificationPreference(
          code: NotificationCodes.SECURITY_ALERTS,
          name: 'Security Alerts',
          description: 'Login attempts and security changes',
          category: 'other',
          enabled: true,
        ),
      ),
      _preferences.other.firstWhere(
        (pref) => pref.code == NotificationCodes.MARKETING_EMAILS,
        orElse: () => NotificationPreference(
          code: NotificationCodes.MARKETING_EMAILS,
          name: 'Marketing Emails',
          description: 'Product updates and promotions',
          category: 'other',
          enabled: false,
        ),
      ),
      _preferences.other.firstWhere(
        (pref) => pref.code == NotificationCodes.WEEKLY_DIGEST,
        orElse: () => NotificationPreference(
          code: NotificationCodes.WEEKLY_DIGEST,
          name: 'Weekly Digest',
          description: 'Summary of your weekly activity',
          category: 'other',
          enabled: true,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            // color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            children: otherNotifications.map((notification) {
              return _buildNotificationItem(
                title: notification.name,
                description: notification.description,
                icon: _getIconForNotification(notification.code),
                enabled: notification.enabled,
                onChanged: (value) =>
                    _updatePreference(notification.code, value),
                iconColor: HoopTheme.vibrantOrange,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuietHoursSection() {
    final timeOptions = _generateTimeOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiet Hours',
          style: TextStyle(
            color: HoopTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            // color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HoopTheme.getBorderColor(
                Theme.of(context).brightness == Brightness.dark,
              ).withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HoopTheme.getMutedColor(
                            Theme.of(context).brightness == Brightness.dark,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: HoopTheme.getTextSecondary(
                            Theme.of(context).brightness == Brightness.dark,
                          ),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Quiet Hours',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: HoopTheme.getTextPrimary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          Text(
                            'Pause notifications during specified hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: HoopTheme.getTextSecondary(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  NotificationSwitch(
                    value: _preferences.quietHours.enabled,
                    onChanged: (value) => _updateQuietHours(
                      _preferences.quietHours.copyWith(enabled: value),
                    ),
                  ),
                ],
              ),

              if (_preferences.quietHours.enabled) ...[
                const SizedBox(height: 16),
                Divider(
                  color: HoopTheme.getBorderColor(
                    Theme.of(context).brightness == Brightness.dark,
                  ).withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: HoopTheme.getTextPrimary(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                        ),
                        Container(
                          width: 96,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: HoopTheme.getBorderColor(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _preferences.quietHours.startTime,
                              isExpanded: true,
                              items: timeOptions.map((time) {
                                return DropdownMenuItem<String>(
                                  value: time,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: HoopTheme.getTextPrimary(
                                        Theme.of(context).brightness ==
                                            Brightness.dark,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _updateQuietHours(
                                    _preferences.quietHours.copyWith(
                                      startTime: value,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: HoopTheme.getTextPrimary(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                        ),
                        Container(
                          width: 96,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: HoopTheme.getBorderColor(
                                Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _preferences.quietHours.endTime,
                              isExpanded: true,
                              items: timeOptions.map((time) {
                                return DropdownMenuItem<String>(
                                  value: time,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: HoopTheme.getTextPrimary(
                                        Theme.of(context).brightness ==
                                            Brightness.dark,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _updateQuietHours(
                                    _preferences.quietHours.copyWith(
                                      endTime: value,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _preferences.hasUnsavedChanges && !_isSaving
            ? _savePreferences
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: HoopTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        child: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _preferences.hasUnsavedChanges
                    ? 'Save Notification Settings'
                    : 'Settings Saved',
              ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String description,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    bool loading = false,
    bool disabled = false,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HoopTheme.getBorderColor(
              Theme.of(context).brightness == Brightness.dark,
            ).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? HoopTheme.primaryBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? HoopTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: HoopTheme.getTextPrimary(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: disabled
                          ? Colors.grey
                          : HoopTheme.getTextSecondary(
                              Theme.of(context).brightness == Brightness.dark,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: HoopTheme.primaryBlue,
                  ),
                )
              : NotificationSwitch(
                  value: enabled,
                  onChanged: disabled
                      ? (_) {}
                      : (value) {
                          onChanged(value);
                        },
                  disabled: disabled,
                  activeColor: iconColor,
                ),
        ],
      ),
    );
  }

  IconData _getIconForNotification(String code) {
    switch (code) {
      case NotificationCodes.GROUP_MESSAGES:
        return Icons.message;
      case NotificationCodes.CONTRIBUTION_REMINDERS:
        return Icons.attach_money;
      case NotificationCodes.GROUP_UPDATES:
        return Icons.people;
      case NotificationCodes.SECURITY_ALERTS:
        return Icons.security;
      case NotificationCodes.MARKETING_EMAILS:
        return Icons.campaign;
      case NotificationCodes.WEEKLY_DIGEST:
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildLoadingState()),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildErrorState()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralNotificationsSection(),
                    const SizedBox(height: 24),
                    _buildGroupNotificationsSection(),
                    const SizedBox(height: 24),
                    _buildOtherNotificationsSection(),
                    const SizedBox(height: 24),
                    _buildQuietHoursSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
