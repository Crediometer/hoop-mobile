import 'package:flutter/material.dart';
import 'package:hoop/screens/features/primary_setup_required_screen.dart';
import 'package:hoop/screens/tabs/activity_tab.dart';
import 'package:hoop/screens/tabs/community_tab.dart';
import 'package:hoop/screens/tabs/groups_tab.dart';
import 'package:hoop/screens/tabs/profile_tab.dart';
import 'package:hoop/screens/tabs/shiners_tab.dart';
import 'package:hoop/states/OnboardingService.dart';
import 'package:hoop/states/onesignal_state.dart';
import 'package:hoop/states/ws/chat_sockets.dart';
import 'package:hoop/states/ws/notification_socket.dart';
import 'package:iconsax/iconsax.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final OnboardingService _onboardingService = OnboardingService();
  bool _oneSignalInitialized = false;

  // Cache static tabs
  late final List<Widget> _staticTabs = [
    const GroupsTab(),
    const ShinersTab(),
    const ActivityTab(),
    const ProfileTab(),
  ];

  // Icons for bottom nav
  final List<IconData> _navIcons = [
    Iconsax.people,
    Iconsax.message,
    Iconsax.video,
    Iconsax.card,
    Iconsax.user,
  ];

  // Tab labels
  final List<String> _tabLabels = [
    'Community',
    'Groups',
    'Spotlight',
    'Transactions',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOneSignal();
    });
  }

  Future<void> _initializeOneSignal() async {
    if (_oneSignalInitialized) return;

    final oneSignal = context.read<OneSignalService>();

    await oneSignal.initialize(
      context: context,
      appId: "474a1dcb-a9e3-4671-bce2-5d530387cba3",
      requireConsent: false,
      requestPermissionAutomatically: true,
      onNotificationClick: (event) {
        print('Notification clicked: ${event.notification.title}');
        _handleNotificationClick(event);
      },
      onForegroundNotification: (event) {
        print('Foreground notification: ${event.notification.title}');
        _handleForegroundNotification(event);
      },
    );

    _oneSignalInitialized = true;
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    final notification = event.notification;
    final data = notification.additionalData;

    if (data != null) {
      final type = data['type']?.toString();
      final actionUrl = data['actionUrl']?.toString();

      print('Notification type: $type, actionUrl: $actionUrl');

      // Navigate based on notification type
      _navigateFromNotification(type, actionUrl);
    }
  }

  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    // You can customize how foreground notifications are handled
    // For example, show a custom banner or dialog
    _showNotificationBanner(event.notification);
  }

  void _showNotificationBanner(OSNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title ?? 'New Notification',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (notification.body != null)
                    Text(
                      notification.body!,
                      style: TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFF97316),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _handleNotificationClick(
              OSNotificationClickEvent(notification.rawPayload ?? {}),
            );
          },
        ),
      ),
    );
  }

  void _navigateFromNotification(String? type, String? actionUrl) {
    // Implement your navigation logic based on notification type
    // This is just an example
    switch (type) {
      case 'GROUP_STARTED':
        // Navigate to groups tab
        setState(() => _currentIndex = 1);
        break;
      case 'CONTRIBUTION_RECEIVED':
      case 'PAYMENT_MISSED':
        // Navigate to activity tab
        setState(() => _currentIndex = 3);
        break;
      case 'MENTION':
        // Navigate to groups tab for chat
        setState(() => _currentIndex = 1);
        break;
      // Add more cases as needed
    }
  }

  Widget _buildBody(bool needsOnboarding) {
    if (_currentIndex == 0) {
      return needsOnboarding
          ? const PrimarySetupRequiredScreen()
          : const CommunityScreen();
    }

    // Return cached tabs for other indices (index 1-4)
    return _staticTabs[_currentIndex - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<bool>(
      stream: _onboardingService.needsOnboardingStream,
      initialData: true,
      builder: (context, snapshot) {
        final needsOnboarding = snapshot.data ?? true;

        return Scaffold(
          body: _buildBody(needsOnboarding),

          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F111A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_navIcons.length, (index) {
                final bool selected = _currentIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark
                                ? const Color(0xFF1C1F28)
                                : Colors.grey[200]!)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon rendering with proper conditions
                        if (index == 0)
                          // Community tab with notification badge
                          Consumer<NotificationWebSocketHandler>(
                            builder: (context, notification, child) {
                              return Stack(
                                children: [
                                  Icon(
                                    _navIcons[index],
                                    size: 26,
                                    color: selected
                                        ? const Color(0xFFF97316)
                                        : (isDark
                                              ? Colors.grey
                                              : Colors.black54),
                                  ),

                                  ValueListenableBuilder<int>(
                                    valueListenable: notification.unreadCount,
                                    builder: (context, value, child) {
                                      if (value > 0) {
                                        return Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF0F111A)
                                                    : Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                value > 9
                                                    ? '9+'
                                                    : value
                                                          .toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return SizedBox.shrink();
                                    },
                                  ),
                                ],
                              );
                            },
                          )
                        else if (index == 1)
                          // Spotlight tab with chat badge
                          Consumer<ChatWebSocketHandler>(
                            builder: (context, handler, child) {
                              return Stack(
                                children: [
                                  Icon(
                                    _navIcons[index],
                                    size: 26,
                                    color: selected
                                        ? const Color(0xFFF97316)
                                        : (isDark
                                              ? Colors.grey
                                              : Colors.black54),
                                  ),
                                  if (handler.totalUnreadMessages > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF0F111A)
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            handler.totalUnreadMessages > 99
                                                ? '99+'
                                                : handler.totalUnreadMessages
                                                      .toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          )
                        else
                          // Transactions and Profile tabs (indices 3 and 4)
                          Icon(
                            _navIcons[index],
                            size: 26,
                            color: selected
                                ? const Color(0xFFF97316)
                                : (isDark ? Colors.grey : Colors.black54),
                          ),

                        const SizedBox(height: 4),

                        // Tab label
                        // if (selected)
                        //   Text(
                        //     _tabLabels[index],
                        //     style: TextStyle(
                        //       fontSize: 10,
                        //       color: const Color(0xFFF97316),
                        //       fontWeight: FontWeight.w500,
                        //     ),
                        //   ),

                        // Orange indicator dot
                        if (selected && _tabLabels[index].isEmpty)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Floating Action Button for manual permission request
          floatingActionButton: Consumer<OneSignalService>(
            builder: (context, oneSignal, child) {
              if (oneSignal.hasPermission || oneSignal.isLoading) {
                return SizedBox.shrink();
              }

              return FloatingActionButton.extended(
                onPressed: () async {
                  await oneSignal.requestPermission();
                },
                icon: Icon(Icons.notifications_active),
                label: Text('Enable Notifications'),
                backgroundColor: Color(0xFFF97316),
                foregroundColor: Colors.white,
              );
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  @override
  void dispose() {
    _onboardingService.dispose();
    super.dispose();
  }
}
