// // screens/notifications_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// class NotificationsScreen extends StatefulWidget {
//   const NotificationsScreen({Key? key}) : super(key: key);

//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _activeTab = 'all';
//   String _filterType = 'all';
  
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final service = context.read<NotificationService>();
//       service.getCount();
//       if (service.isConnected) {
//         service.refreshNotifications();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.background,
//       body: Column(
//         children: [
//           // Header
//           _buildHeader(context),
          
//           // Search and Filter
//           _buildSearchFilter(context),
          
//           // Tabs
//           _buildTabs(context),
          
//           // Notifications List
//           Expanded(
//             child: _buildNotificationsList(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.background,
//         border: Border(
//           bottom: BorderSide(
//             color: Theme.of(context).dividerColor.withOpacity(0.2),
//           ),
//         ),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   // Back button for mobile
//                   if (MediaQuery.of(context).size.width < 1024)
//                     IconButton(
//                       onPressed: () => context.pop(),
//                       icon: Icon(
//                         Icons.arrow_back,
//                         color: Theme.of(context).colorScheme.onBackground,
//                       ),
//                       style: IconButton.styleFrom(
//                         backgroundColor: Theme.of(context).colorScheme.secondary,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   const SizedBox(width: 12),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Consumer<NotificationService>(
//                         builder: (context, service, child) {
//                           return Row(
//                             children: [
//                               Text(
//                                 'Notifications',
//                                 style: TextStyle(
//                                   color: Theme.of(context).colorScheme.primary,
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               if (service.counts?.unreadCount > 0)
//                                 Container(
//                                   margin: const EdgeInsets.only(left: 8),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 2,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.orange,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     service.counts!.unreadCount.toString(),
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Stay updated with your groups',
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.onSurfaceVariant,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               Consumer<NotificationService>(
//                 builder: (context, service, child) {
//                   return IconButton(
//                     onPressed: service.counts?.unreadCount == 0
//                         ? null
//                         : () => _handleMarkAllAsRead(service),
//                     icon: const Icon(Icons.mark_email_read),
//                     color: Theme.of(context).colorScheme.primary,
//                     style: IconButton.styleFrom(
//                       backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchFilter(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.surface,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: Theme.of(context).dividerColor,
//                 ),
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (value) => setState(() {}),
//                 decoration: InputDecoration(
//                   hintText: 'Search notifications...',
//                   prefixIcon: Icon(
//                     Icons.search,
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                   ),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             width: 160,
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surface,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: Theme.of(context).dividerColor,
//               ),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _filterType,
//                 onChanged: (value) {
//                   setState(() {
//                     _filterType = value!;
//                   });
//                 },
//                 items: const [
//                   DropdownMenuItem(
//                     value: 'all',
//                     child: Text('All Types'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'GROUP_STARTED',
//                     child: Text('Group Started'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'SLOT_ASSIGNED',
//                     child: Text('Slot Assigned'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'CONTRIBUTION_RECEIVED,PAYMENT_MISSED',
//                     child: Text('Payments'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'GROUP_GOAL_ACHIEVED',
//                     child: Text('Goals'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'WEEKLY_POLL_UPDATE',
//                     child: Text('Polls'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'MEETING_SCHEDULED',
//                     child: Text('Meetings'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'MENTION',
//                     child: Text('Mentions'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'SYSTEM_ALERT',
//                     child: Text('System'),
//                   ),
//                 ],
//                 isExpanded: true,
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 icon: Icon(
//                   Icons.filter_list,
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabs(BuildContext context) {
//     return Consumer<NotificationService>(
//       builder: (context, service, child) {
//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: SegmentedButton<String>(
//             segments: [
//               ButtonSegment<String>(
//                 value: 'all',
//                 label: Text('All ${service.counts?.totalCount ?? 0}'),
//               ),
//               ButtonSegment<String>(
//                 value: 'unread',
//                 label: Text('Unread ${service.counts?.unreadCount ?? 0}'),
//               ),
//               ButtonSegment<String>(
//                 value: 'read',
//                 label: Text('Read ${service.counts?.readCount ?? 0}'),
//               ),
//             ],
//             selected: {_activeTab},
//             onSelectionChanged: (Set<String> newSelection) {
//               setState(() {
//                 _activeTab = newSelection.first;
//               });
//             },
//             style: SegmentedButton.styleFrom(
//               backgroundColor: Theme.of(context).colorScheme.surface,
//               selectedBackgroundColor: Theme.of(context).colorScheme.primary,
//               selectedForegroundColor: Colors.white,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildNotificationsList(BuildContext context) {
//     return Consumer<NotificationService>(
//       builder: (context, service, child) {
//         final notifications = _filterNotifications(service.notifications);
        
//         if (notifications.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 64,
//                   height: 64,
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.notifications,
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     size: 32,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   _searchController.text.isNotEmpty
//                       ? 'No matching notifications'
//                       : 'No notifications yet',
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _searchController.text.isNotEmpty
//                       ? 'Try adjusting your search or filter'
//                       : "We'll notify you when something happens",
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: notifications.length,
//           itemBuilder: (context, index) {
//             return _buildNotificationItem(context, notifications[index]);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
//     final iconData = _getNotificationIcon(notification.type);
//     final color = _getNotificationColor(context, notification.type);
//     final priority = _getNotificationPriority(notification.type);
//     final actionable = _isActionable(notification);

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: notification.read
//               ? Theme.of(context).dividerColor
//               : Theme.of(context).colorScheme.primary.withOpacity(0.2),
//         ),
//       ),
//       color: _getNotificationBackgroundColor(context, notification, priority),
//       child: InkWell(
//         onTap: () => _handleNotificationAction(notification),
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Icon
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: _getIconBackgroundColor(context, notification, priority),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   iconData,
//                   color: _getIconColor(context, notification, priority, color),
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
              
//               // Content
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             notification.title,
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: notification.read
//                                   ? Theme.of(context).colorScheme.onSurfaceVariant
//                                   : Theme.of(context).colorScheme.onBackground,
//                             ),
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             if (!notification.read)
//                               Container(
//                                 width: 8,
//                                 height: 8,
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context).colorScheme.primary,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                             const SizedBox(width: 8),
//                             IconButton(
//                               onPressed: () => _handleDeleteNotification(notification.id),
//                               icon: Icon(
//                                 Icons.delete_outline,
//                                 size: 18,
//                                 color: Theme.of(context).colorScheme.onSurfaceVariant,
//                               ),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       notification.message,
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.onSurfaceVariant,
//                         fontSize: 14,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
                    
//                     // Metadata and action button
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 4,
//                           children: [
//                             // Timestamp
//                             Text(
//                               _formatTimestamp(notification.createdAt),
//                               style: TextStyle(
//                                 color: Theme.of(context).colorScheme.onSurfaceVariant,
//                                 fontSize: 12,
//                               ),
//                             ),
                            
//                             // Group badge
//                             if (notification.metadata?.groupName != null)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Theme.of(context).colorScheme.secondary,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   notification.metadata!.groupName!,
//                                   style: TextStyle(
//                                     color: Theme.of(context).colorScheme.onSecondary,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
                            
//                             // Amount badge
//                             if (notification.metadata?.amount != null)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   '\$${notification.metadata!.amount!.toStringAsFixed(2)}',
//                                   style: const TextStyle(
//                                     color: Colors.green,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
                            
//                             // Priority badges
//                             if (priority == 'urgent')
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Text(
//                                   'Urgent',
//                                   style: TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
                            
//                             if (priority == 'high')
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.orange.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Text(
//                                   'Important',
//                                   style: TextStyle(
//                                     color: Colors.orange,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
                        
//                         // Action button
//                         if (actionable)
//                           TextButton(
//                             onPressed: () => _handleNotificationAction(notification),
//                             style: TextButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 4,
//                               ),
//                             ),
//                             child: Text(
//                               'View',
//                               style: TextStyle(
//                                 color: Theme.of(context).colorScheme.primary,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper methods
//   List<NotificationModel> _filterNotifications(List<NotificationModel> notifications) {
//     return notifications.where((notif) {
//       final matchesSearch = notif.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
//           notif.message.toLowerCase().contains(_searchController.text.toLowerCase());
//       final matchesFilter = _filterType == 'all' || notif.type == _filterType;
//       final matchesTab = _activeTab == 'all' ||
//           (_activeTab == 'unread' && !notif.read) ||
//           (_activeTab == 'read' && notif.read);
      
//       return matchesSearch && matchesFilter && matchesTab;
//     }).toList();
//   }

//   IconData _getNotificationIcon(String type) {
//     switch (type) {
//       case 'GROUP_STARTED':
//       case 'GROUP_CREATED':
//         return Icons.handshake;
//       case 'GROUP_UPDATE':
//         return Icons.group;
//       case 'GROUP_DISBURSED':
//         return Icons.emoji_events;
//       case 'GROUP_GOAL_ACHIEVED':
//         return Icons.workspace_premium;
//       case 'SLOT_ASSIGNED':
//         return Icons.target;
//       case 'SLOTS_COMPLETED':
//         return Icons.check_circle;
//       case 'CONTRIBUTION_REMINDER':
//         return Icons.access_time;
//       case 'CONTRIBUTION_RECEIVED':
//       case 'CONTRIBUTION_CONFIRMED':
//         return Icons.attach_money;
//       case 'PAYMENT_MISSED':
//         return Icons.warning;
//       case 'PAYMENT_OVERDUE':
//         return Icons.error;
//       case 'PAYOUT_ALERT':
//         return Icons.flash_on;
//       case 'GOAL_ACHIEVED':
//         return Icons.celebration;
//       case 'GOAL_PROGRESS':
//         return Icons.trending_up;
//       case 'MEMBER_APPROVED':
//       case 'MEMBER_JOINED':
//         return Icons.person_add;
//       case 'MEMBER_LEFT':
//         return Icons.person_remove;
//       case 'MEMBER_REJECTED':
//         return Icons.person_off;
//       case 'UPCOMING_MEETING':
//       case 'MEETING_SCHEDULED':
//       case 'MEETING_REMINDER':
//         return Icons.calendar_today;
//       case 'WEEKLY_POLL_UPDATE':
//         return Icons.poll;
//       case 'MENTION':
//         return Icons.alternate_email;
//       case 'ADMIN_ANNOUNCEMENT':
//         return Icons.campaign;
//       case 'SYSTEM_ALERT':
//         return Icons.notifications;
//       case 'WELCOME':
//         return Icons.star;
//       case 'SECURITY':
//         return Icons.security;
//       case 'group_message':
//         return Icons.message;
//       case 'contribution':
//         return Icons.attach_money;
//       case 'group_update':
//         return Icons.group;
//       default:
//         return Icons.notifications;
//     }
//   }

//   Color _getNotificationColor(BuildContext context, String type) {
//     switch (type) {
//       case 'CONTRIBUTION_RECEIVED':
//       case 'CONTRIBUTION_CONFIRMED':
//       case 'GOAL_ACHIEVED':
//       case 'GROUP_GOAL_ACHIEVED':
//       case 'MEMBER_APPROVED':
//       case 'MEMBER_JOINED':
//       case 'GROUP_STARTED':
//       case 'SLOTS_COMPLETED':
//       case 'PAYOUT_ALERT':
//         return Colors.green;
//       case 'CONTRIBUTION_REMINDER':
//       case 'PAYMENT_MISSED':
//       case 'UPCOMING_MEETING':
//       case 'MEETING_SCHEDULED':
//       case 'MEETING_REMINDER':
//       case 'GOAL_PROGRESS':
//       case 'WEEKLY_POLL_UPDATE':
//         return Colors.orange;
//       case 'PAYMENT_OVERDUE':
//       case 'SECURITY':
//       case 'ADMIN_ANNOUNCEMENT':
//       case 'MEMBER_REJECTED':
//         return Colors.red;
//       case 'GROUP_UPDATE':
//       case 'GROUP_DISBURSED':
//       case 'MENTION':
//       case 'SLOT_ASSIGNED':
//       case 'group_message':
//         return Theme.of(context).colorScheme.primary;
//       case 'MEMBER_LEFT':
//       case 'SYSTEM_ALERT':
//       case 'WELCOME':
//         return Colors.purple;
//       default:
//         return Theme.of(context).colorScheme.onSurfaceVariant;
//     }
//   }

//   String _getNotificationPriority(String type) {
//     switch (type) {
//       case 'PAYMENT_OVERDUE':
//       case 'SECURITY':
//         return 'urgent';
//       case 'ADMIN_ANNOUNCEMENT':
//       case 'GROUP_GOAL_ACHIEVED':
//       case 'PAYMENT_MISSED':
//       case 'MENTION':
//         return 'high';
//       case 'CONTRIBUTION_REMINDER':
//       case 'UPCOMING_MEETING':
//       case 'MEETING_SCHEDULED':
//       case 'MEETING_REMINDER':
//       case 'WEEKLY_POLL_UPDATE':
//         return 'medium';
//       default:
//         return 'low';
//     }
//   }

//   bool _isActionable(NotificationModel notification) {
//     return notification.actionable == true ||
//         ['GROUP_STARTED', 'SLOT_ASSIGNED', 'PAYMENT_MISSED', 'WEEKLY_POLL_UPDATE']
//             .contains(notification.type);
//   }

//   Color _getNotificationBackgroundColor(
//       BuildContext context, 
//       NotificationModel notification, 
//       String priority) {
//     if (!notification.read) {
//       return Theme.of(context).colorScheme.primary.withOpacity(0.05);
//     } else if (priority == 'urgent') {
//       return Colors.red.withOpacity(0.05);
//     } else if (priority == 'high') {
//       return Colors.orange.withOpacity(0.05);
//     }
//     return Theme.of(context).colorScheme.surface;
//   }

//   Color _getIconBackgroundColor(
//       BuildContext context, 
//       NotificationModel notification, 
//       String priority) {
//     if (!notification.read) {
//       return Theme.of(context).colorScheme.primary.withOpacity(0.1);
//     } else if (priority == 'urgent') {
//       return Colors.red.withOpacity(0.1);
//     } else if (priority == 'high') {
//       return Colors.orange.withOpacity(0.1);
//     }
//     return Theme.of(context).colorScheme.surfaceVariant;
//   }

//   Color _getIconColor(
//       BuildContext context, 
//       NotificationModel notification, 
//       String priority, 
//       Color color) {
//     if (!notification.read) {
//       return Theme.of(context).colorScheme.primary;
//     } else if (priority == 'urgent') {
//       return Colors.red;
//     } else if (priority == 'high') {
//       return Colors.orange;
//     }
//     return color;
//   }

//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);
    
//     if (difference.inMinutes < 1) return 'Just now';
//     if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
//     if (difference.inHours < 24) return '${difference.inHours}h ago';
//     if (difference.inDays < 7) return '${difference.inDays}d ago';
    
//     return DateFormat('MMM d, yyyy').format(timestamp);
//   }

//   // Action handlers
//   Future<void> _handleNotificationAction(NotificationModel notification) async {
//     final service = context.read<NotificationService>();
    
//     // Mark as read if not read
//     if (!notification.read) {
//       await service.markAsRead(notification.id);
//     }
    
//     // Use actionUrl if provided
//     if (notification.actionable && notification.actionUrl != null) {
//       context.go(notification.actionUrl!);
//       return;
//     }
    
//     // Handle navigation based on type
//     _handleNavigation(notification);
//   }

//   void _handleNavigation(NotificationModel notification) {
//     final groupId = notification.metadata?.groupId;
//     final pollId = notification.metadata?.pollId;

//     switch (notification.type) {
//       case 'group_message':
//       case 'MENTION':
//         if (groupId != null) {
//           context.go('/groups/$groupId/chat');
//         }
//         break;
//       case 'CONTRIBUTION_RECEIVED':
//       case 'CONTRIBUTION_CONFIRMED':
//       case 'CONTRIBUTION_REMINDER':
//       case 'PAYMENT_MISSED':
//       case 'PAYMENT_OVERDUE':
//       case 'PAYOUT_ALERT':
//         if (groupId != null) {
//           context.go('/groups/$groupId/payments');
//         } else {
//           context.go('/transactions');
//         }
//         break;
//       case 'GROUP_STARTED':
//       case 'GROUP_CREATED':
//       case 'GROUP_UPDATE':
//       case 'GROUP_GOAL_ACHIEVED':
//       case 'GOAL_ACHIEVED':
//       case 'GOAL_PROGRESS':
//       case 'MEMBER_APPROVED':
//       case 'MEMBER_REJECTED':
//       case 'MEMBER_JOINED':
//       case 'MEMBER_LEFT':
//       case 'GROUP_DISBURSED':
//       case 'ADMIN_ANNOUNCEMENT':
//         if (groupId != null) {
//           context.go('/groups/$groupId');
//         }
//         break;
//       case 'SLOT_ASSIGNED':
//       case 'SLOTS_COMPLETED':
//         if (groupId != null) {
//           context.go('/groups/$groupId/slots');
//         }
//         break;
//       case 'UPCOMING_MEETING':
//       case 'MEETING_SCHEDULED':
//       case 'MEETING_REMINDER':
//         if (groupId != null) {
//           context.go('/groups/$groupId/schedule');
//         } else {
//           context.go('/schedule');
//         }
//         break;
//       case 'WEEKLY_POLL_UPDATE':
//         if (groupId != null && pollId != null) {
//           context.go('/groups/$groupId/polls/$pollId');
//         } else if (groupId != null) {
//           context.go('/groups/$groupId/polls');
//         }
//         break;
//       case 'SECURITY':
//         context.go('/profile/security');
//         break;
//       case 'WELCOME':
//         context.go('/profile');
//         break;
//       default:
//         if (groupId != null) {
//           context.go('/groups/$groupId');
//         }
//         break;
//     }
//   }

//   Future<void> _handleMarkAllAsRead(NotificationService service) async {
//     await service.markAllAsRead();
//   }

//   Future<void> _handleDeleteNotification(String notificationId) async {
//     final service = context.read<NotificationService>();
//     await service.deleteNotification(notificationId);
//   }
// }