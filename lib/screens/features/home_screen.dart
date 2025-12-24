import 'package:flutter/material.dart';
import 'package:hoop/screens/tabs/community_tab.dart';
import 'package:hoop/screens/tabs/groups_tab.dart';
import 'package:hoop/screens/tabs/shiners_tab.dart';
import 'package:hoop/screens/tabs/activity_tab.dart';
import 'package:hoop/screens/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CommunityScreen(),
    GroupsTab(),
    ShinersTab(),
    ActivityTab(),
    ProfileTab(),
  ];

  // Icons for bottom nav
  // Icons for bottom nav
  final List<IconData> _navIcons = [
    Icons.people_outline,        // Community
    Icons.chat_bubble_outline,   // Chat
    Icons.videocam_outlined,     // Video
    Icons.credit_card,           // Wallet
    Icons.person_outline,        // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F111A)
              : Colors.white,
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
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return GestureDetector(
              onTap: () => setState(() => _currentIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? const Color(0xFF1C1F28) : Colors.grey[200])
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _navIcons[index],
                      size: 26,
                      color: selected
                          ? const Color(0xFFF97316)
                          : (isDark ? Colors.grey : Colors.black54),
                    ),

                    const SizedBox(height: 4),

                    // Little orange dot
                    if (selected)
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
  }
}
