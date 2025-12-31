import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/SegmentButton.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/components/state/empty_state.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/dtos/responses/notifications/notification.dart';
import 'package:hoop/states/ws/notification_socket.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeTab = 'all';
  String _filterType = 'all';
  bool _showSearch = false;
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final handler = context.read<NotificationWebSocketHandler>();
      if (handler.isConnected) {
        handler.refreshNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
   
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600]; 
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showSearch
                  ? _buildSearchHeader(isDark, textPrimary, textSecondary)
                  : _buildHeader(context),
            ),


            // Tabs
            _buildTabs(context),

            // Connection Status Banner
            _buildConnectionStatus(context),

            // Notifications List
            Expanded(child: _buildNotificationsList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Back button for mobile
                  if (MediaQuery.of(context).size.width < 1024)
                    HoopBackButton(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<NotificationWebSocketHandler>(
                        builder: (context, handler, child) {
                          return Row(
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: HoopTheme.primaryBlue,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (handler.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: HoopTheme.vibrantOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    handler.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay updated with your groups',
                        style: TextStyle(
                          color: HoopTheme.getTextSecondary(isDark),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
         

              Row(
                children: [
                  // Search icon
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => setState(() => _showSearch = true),
                      icon: Icon(Icons.search, color: textPrimary, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Checkmark icon
                  Consumer<NotificationWebSocketHandler>(
                    builder: (context, handler, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: handler.unreadCount > 0
                              ? () => _handleMarkAllAsRead(handler)
                              : null,
                          icon: Icon(Icons.check, color: textPrimary, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              child: Row(
                children: [
                  Expanded(
                    child: HoopInput(
                      controller: _searchController,
                      labelText: "Search notifications...",
                      prefixIcon: Icon(
                        Icons.search,
                        color: HoopTheme.getTextSecondary(isDark),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.clear,
                        color: HoopTheme.getTextSecondary(isDark),
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter dropdown
          Container(
            decoration: BoxDecoration(
              color: HoopTheme.getCommunityCardColor(1, isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterType,
                  icon: Icon(
                    Icons.filter_list,
                    color: HoopTheme.getTextSecondary(isDark),
                    size: 20,
                  ),
                  items:
                      [
                        'all',
                        'GROUP_STARTED',
                        'SLOT_ASSIGNED',
                        'CONTRIBUTION_RECEIVED,PAYMENT_MISSED',
                        'GROUP_GOAL_ACHIEVED',
                        'WEEKLY_POLL_UPDATE',
                        'MEETING_SCHEDULED',
                        'MENTION',
                        'SYSTEM_ALERT',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            _getFilterLabel(value),
                            style: TextStyle(
                              color: HoopTheme.getTextPrimary(isDark),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _filterType = newValue ?? 'all';
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String value) {
    switch (value) {
      case 'all':
        return 'All Types';
      case 'GROUP_STARTED':
        return 'Group Started';
      case 'SLOT_ASSIGNED':
        return 'Slot Assigned';
      case 'CONTRIBUTION_RECEIVED,PAYMENT_MISSED':
        return 'Payments';
      case 'GROUP_GOAL_ACHIEVED':
        return 'Goals';
      case 'WEEKLY_POLL_UPDATE':
        return 'Polls';
      case 'MEETING_SCHEDULED':
        return 'Meetings';
      case 'MENTION':
        return 'Mentions';
      case 'SYSTEM_ALERT':
        return 'System';
      default:
        return value;
    }
  }

  Widget _buildTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<NotificationWebSocketHandler>(
      builder: (context, handler, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoopSegmentButton(
                  isSelected: _activeTab == 'all',
                  label: 'All ${handler.totalCount}',
                  segment: 0,
                  handleSegmentChange: (s) =>
                      setState(() => _activeTab = 'all'),
                ),
                const SizedBox(width: 8),
                HoopSegmentButton(
                  isSelected: _activeTab == 'unread',
                  label: 'Unread ${handler.unreadCount}',
                  segment: 0,
                  handleSegmentChange: (s) =>
                      setState(() => _activeTab = 'unread'),
                ),
                const SizedBox(width: 8),
                HoopSegmentButton(
                  isSelected: _activeTab == 'read',
                  label: 'Read ${handler.readCount}',
                  segment: 0,
                  handleSegmentChange: (s) =>
                      setState(() => _activeTab = 'read'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return Consumer<NotificationWebSocketHandler>(
      builder: (context, handler, child) {
        if (handler.isConnected) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: handler.isConnecting
                ? Colors.orange.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: handler.isConnecting ? Colors.orange : Colors.red,
            ),
          ),
          child: Row(
            children: [
              Icon(
                handler.isConnecting ? Icons.sync : Icons.wifi_off,
                color: handler.isConnecting ? Colors.orange : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  handler.isConnecting
                      ? 'Connecting to notifications...'
                      : 'Disconnected from notifications',
                  style: TextStyle(
                    color: handler.isConnecting ? Colors.orange : Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!handler.isConnecting)
                TextButton(
                  onPressed: () => handler.reconnect(),
                  child: const Text(
                    'Reconnect',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    return Consumer<NotificationWebSocketHandler>(
      builder: (context, handler, child) {
        if (handler.loading) {
          return Center(
            child: CircularProgressIndicator(color: HoopTheme.primaryBlue),
          );
        }

        final notifications = _filterNotifications(handler.notifications);

        if (notifications.isEmpty) {
          return HoopEmptyState(
            title: _searchController.text.isNotEmpty
                ? 'No matching notifications'
                : 'No notifications yet',
            subtitle: _searchController.text.isNotEmpty
                ? 'Try adjusting your search or filter'
                : "We'll notify you when something happens",
            iconData: Icons.notifications_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            handler.refreshNotifications();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationItem(
                context,
                notifications[index],
                handler,
                index,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    NotificationWebSocketHandler handler,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = _getNotificationIcon(notification.type);
    final actionable =
        notification.actionUrl != null && notification.actionUrl!.isNotEmpty;
    final priority = _getNotificationPriority(notification.type);
    final color = HoopTheme.getNotificationTypeColor(
      notification.type.toString(),
      isDark,
    );

    return GestureDetector(
      onTap: () => _handleNotificationAction(notification, handler, context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: !notification.read
              ? HoopTheme.primaryBlue.withOpacity(0.05)
              : HoopTheme.getCommunityCardColor(index, isDark).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !notification.read
                ? HoopTheme.primaryBlue
                : HoopTheme.getBorderColor(isDark).withOpacity(0.1),
          ),
          boxShadow: [
            if (priority == 'urgent')
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              )
            else if (priority == 'high')
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: !notification.read
                      ? HoopTheme.primaryBlue.withOpacity(0.1)
                      : HoopTheme.getMutedColor(isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: !notification.read ? HoopTheme.primaryBlue : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: !notification.read
                                  ? HoopTheme.getTextPrimary(isDark)
                                  : HoopTheme.getTextSecondary(isDark),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (!notification.read)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: HoopTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            GestureDetector(
                              onTap: () => _handleDeleteNotification(
                                notification.id,
                                handler,
                                context,
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: HoopTheme.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message ?? '',
                      style: TextStyle(
                        color: HoopTheme.getTextSecondary(isDark),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Metadata and action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatTimestamp(notification.createdAt),
                              style: TextStyle(
                                color: HoopTheme.getTextSecondary(isDark),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Priority badge
                            if (priority == 'urgent')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Urgent',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else if (priority == 'high')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Important',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Action button
                        if (actionable)
                          Container(
                            decoration: BoxDecoration(
                              color: HoopTheme.getCategoryBackgroundColor(
                                'view_button',
                                isDark,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton(
                              onPressed: () => _handleNotificationAction(
                                notification,
                                handler,
                                context,
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                              ),
                              child: Text(
                                'View',
                                style: TextStyle(
                                  color: HoopTheme.getCategoryTextColor(
                                    'view_button',
                                    isDark,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    return notifications.where((notif) {
      final matchesSearch =
          _searchController.text.isEmpty ||
          notif.title.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          (notif.message ?? '').toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );

      final matchesFilter =
          _filterType == 'all' || notif.type.toString().contains(_filterType);

      final matchesTab =
          _activeTab == 'all' ||
          (_activeTab == 'unread' && !notif.read) ||
          (_activeTab == 'read' && notif.read);

      return matchesSearch && matchesFilter && matchesTab;
    }).toList();
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type.toString()) {
      // Hoop Group Events
      case 'GROUP_STARTED':
      case 'GROUP_CREATED':
        return Icons.group_work;
      case 'GROUP_UPDATE':
        return Icons.groups;
      case 'GROUP_DISBURSED':
        return Icons.celebration;
      case 'GROUP_GOAL_ACHIEVED':
        return Icons.emoji_events;

      // Slot Management
      case 'SLOT_ASSIGNED':
        return Icons.my_location; // Alternative to target icon
      case 'SLOTS_COMPLETED':
        return Icons.check_circle;

      // Contribution & Payments
      case 'CONTRIBUTION_REMINDER':
        return Icons.access_time;
      case 'CONTRIBUTION_RECEIVED':
      case 'CONTRIBUTION_CONFIRMED':
        return Icons.attach_money;
      case 'PAYMENT_MISSED':
        return Icons.error_outline;
      case 'PAYMENT_OVERDUE':
        return Icons.warning;
      case 'PAYOUT_ALERT':
        return Icons.bolt;

      // Goal Events
      case 'GOAL_ACHIEVED':
        return Icons.celebration;
      case 'GOAL_PROGRESS':
        return Icons.trending_up;

      // Member Events
      case 'MEMBER_APPROVED':
      case 'MEMBER_JOINED':
        return Icons.person_add;
      case 'MEMBER_LEFT':
        return Icons.person_remove;
      case 'MEMBER_REJECTED':
        return Icons.person_off;

      // Meeting Events
      case 'UPCOMING_MEETING':
      case 'MEETING_SCHEDULED':
      case 'MEETING_REMINDER':
        return Icons.calendar_today;

      // Polls & Social
      case 'WEEKLY_POLL_UPDATE':
        return Icons.poll;
      case 'MENTION':
        return Icons.alternate_email;

      // Announcements & System
      case 'ADMIN_ANNOUNCEMENT':
        return Icons.campaign;
      case 'SYSTEM_ALERT':
        return Icons.notifications;
      case 'WELCOME':
        return Icons.star;

      // Security
      case 'SECURITY':
        return Icons.security;

      // Legacy types
      case 'group_message':
        return Icons.message;
      case 'contribution':
        return Icons.attach_money;
      case 'group_update':
        return Icons.groups;

      default:
        return Icons.notifications;
    }
  }

  String _getNotificationPriority(NotificationType type) {
    switch (type.toString()) {
      case 'PAYMENT_OVERDUE':
      case 'SECURITY':
        return 'urgent';

      case 'ADMIN_ANNOUNCEMENT':
      case 'GROUP_GOAL_ACHIEVED':
      case 'PAYMENT_MISSED':
      case 'MENTION':
        return 'high';

      case 'CONTRIBUTION_REMINDER':
      case 'UPCOMING_MEETING':
      case 'MEETING_SCHEDULED':
      case 'MEETING_REMINDER':
      case 'WEEKLY_POLL_UPDATE':
        return 'medium';

      default:
        return 'low';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM d, yyyy').format(timestamp);
  }

  // Action handlers
  Future<void> _handleNotificationAction(
    NotificationModel notification,
    NotificationWebSocketHandler handler,
    BuildContext context,
  ) async {
    // Mark as read if not read
    if (!notification.read) {
      handler.markAsRead(notification.id);
    }

    // Use actionUrl if provided
    if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      // Navigate using your app's navigation system
      // Example: Navigator.of(context).pushNamed(notification.actionUrl!);
      return;
    }

    // Handle navigation based on type (replace with your actual navigation)
    _handleNavigation(notification, context);
  }

  void _handleNavigation(NotificationModel notification, BuildContext context) {
    // Add your navigation logic here based on notification type
    // Example:
    // switch (notification.type) {
    //   case 'GROUP_STARTED':
    //     if (notification.groupId != null) {
    //       Navigator.of(context).pushNamed('/group/${notification.groupId}');
    //     }
    //     break;
    //   // etc.
    // }
  }

  Future<void> _handleMarkAllAsRead(
    NotificationWebSocketHandler handler,
  ) async {
    handler.markAllAsRead();
  }

  Future<void> _handleDeleteNotification(
    String notificationId,
    NotificationWebSocketHandler handler,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      handler.deleteNotification(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSearchHeader(
    bool isDark,
    Color? textPrimary,
    Color? textSecondary,
  ) {
    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141617) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search groups by title, body...',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _showSearch = false;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.tune, color: textPrimary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
