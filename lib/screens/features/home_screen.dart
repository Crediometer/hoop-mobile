import 'package:flutter/material.dart';
import 'package:hoop/screens/features/primary_setup_required_screen.dart';
import 'package:hoop/screens/tabs/community_tab.dart';
import 'package:hoop/screens/tabs/groups_tab.dart';
import 'package:hoop/screens/tabs/shiners_tab.dart';
import 'package:hoop/screens/tabs/activity_tab.dart';
import 'package:hoop/screens/tabs/profile_tab.dart';
import 'package:hoop/states/OnboardingService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final OnboardingService _onboardingService = OnboardingService();

  // Cache static tabs
  late final List<Widget> _staticTabs = const [
    GroupsTab(),
    ShinersTab(),
    ActivityTab(),
    ProfileTab(),
  ];

  // Icons for bottom nav
  final List<IconData> _navIcons = [
    Icons.people_outline,        // Community
    Icons.chat_bubble_outline,   // Chat
    Icons.videocam_outlined,     // Video
    Icons.credit_card,           // Wallet
    Icons.person_outline,        // Profile
  ];

  // Tab labels
  final List<String> _tabLabels = [
    'Community',
    'Groups',
    'Shiners',
    'Activity',
    'Profile',
  ];

  @override
  void dispose() {
    _onboardingService.dispose();
    super.dispose();
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? const Color(0xFF1C1F28) : Colors.grey[200]!)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Icon(
                              _navIcons[index],
                              size: 26,
                              color: selected
                                  ? const Color(0xFFF97316)
                                  : (isDark ? Colors.grey : Colors.black54),
                            ),
                            // Show notification dot for specific tabs if needed
                            if (_hasNotifications(index))
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isDark 
                                          ? const Color(0xFF0F111A) 
                                          : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Tab label (optional)
                        if (selected)
                          Text(
                            _tabLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFFF97316),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

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
        );
      },
    );
  }

  // Helper method to check if a tab has notifications
  bool _hasNotifications(int index) {
    // Example: Show notifications for Groups tab (index 1)
    // You can implement your own logic here
    return index == 1 && false; // Replace with actual notification logic
  }
}