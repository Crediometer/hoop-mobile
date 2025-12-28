import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/screens/groups/create_group.dart';
import 'package:hoop/screens/settings/community_preference.dart';
import 'package:hoop/screens/supports/SupportTicket.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:provider/provider.dart';
import 'package:hoop/constants/themes.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Refresh profile data when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.getProfile();
  }

  String _getInitials(String? firstName, String? lastName) {
    if (firstName == null && lastName == null) return '??';

    final firstInitial = (firstName?.isNotEmpty == true) ? firstName![0] : '';
    final lastInitial = (lastName?.isNotEmpty == true) ? lastName![0] : '';

    final initials = (firstInitial + lastInitial).toUpperCase();
    return initials.isNotEmpty ? initials : '??';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final month = _getMonthName(date.month);
    return '${month} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    // Get phone number from user or personalInfo
    final String? phoneNumber = user?.phoneNumber;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= PROFILE HEADER =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? null : Colors.white,
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF020617)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? null : Border.all(color: Colors.grey[200]!),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 2,
                        ),
                        color: isDark
                            ? Colors.blueGrey[800]
                            : Colors.blueGrey[100],
                      ),
                      child:
                          user?.imageUrl != null && user!.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                user.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _getInitials(
                                        user.firstName,
                                        user.lastName,
                                      ),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.blueGrey[700],
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(user?.firstName, user?.lastName),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.blueGrey[700],
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    // Name, Email, Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user != null
                                ? '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                      .trim()
                                : 'Loading...',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'email@example.com',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: user?.status == 'ACTIVE'
                                      ? const Color(0xFF22C55E)
                                      : user?.status == 'INACTIVE'
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user?.createdAt != null
                                    ? 'Member since ${_formatDate(user!.createdAt)}'
                                    : 'Active member',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        // Navigate to settings
                      },
                      icon: Icon(
                        Icons.settings,
                        color: textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              _buildMenuItem(
                icon: Icons.group_add,
                iconColor: const Color(0xFF3B82F6),
                title: 'Create Group',
                subtitle: 'Start a new thrift group',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (builder) => GroupCreationFlowScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.account_balance,
                iconColor: const Color(0xFF10B981),
                title: 'Primary Account',
                subtitle: 'Manage your withdraw accounts',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.person_outline,
                iconColor: const Color(0xFFF97316),
                title: 'Profile Details',
                subtitle: 'Edit your personal information',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.palette,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Appearance',
                subtitle: 'Theme and display preferences',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {
                  _showAppearanceDialog(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFEF4444),
                title: 'Notifications',
                subtitle: 'Notification preferences',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.map_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: 'Community Settings',
                subtitle: 'Location & group preferences',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommunitySettingsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.security,
                iconColor: const Color(0xFF06B6D4),
                title: 'Security',
                subtitle: 'Privacy & security settings',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {},
              ),

              _buildMenuItem(
                icon: Icons.logout,
                iconColor: const Color(0xFFDC2626),
                title: 'Logout',
                subtitle: 'Logout of your account',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () {
                  _showLogoutConfirmation(context, authProvider);
                },
              ),

              const SizedBox(height: 32),

              /// ================= SUPPORT SECTION =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? null : Colors.white,
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF0B1220), Color(0xFF020617)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: isDark ? null : Border.all(color: Colors.grey[200]!),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        color: HoopTheme.getTextPrimary(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get support from our team or browse frequently asked questions',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 180,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactSupportScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0a1866),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Contact Support',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ================= FOOTER =================
              Center(
                child: Text(
                  'Thrift App v1.0.0 • Made with ❤️ for the community',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.65,
          maxChildSize: 0.90,
          expand: false,
          builder: (context, controller) {
            String currentAppearance = user?.appearance ?? 'system';

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Appearance icon at top
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF8B5CF6).withOpacity(0.2)
                            : const Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5CF6),
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: const Color(0xFF8B5CF6),
                        size: 45,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your preferred theme',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Appearance Options
                    StatefulBuilder(
                      builder: (context, setModalState) {
                        return Column(
                          children: [
                            // System Default Option
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  currentAppearance = 'system';
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: currentAppearance == 'system'
                                      ? isDark
                                            ? const Color(
                                                0xFF8B5CF6,
                                              ).withOpacity(0.15)
                                            : const Color(0xFFEDE9FE)
                                      : isDark
                                      ? const Color(0xFF252836)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: currentAppearance == 'system'
                                        ? const Color(0xFF8B5CF6)
                                        : isDark
                                        ? Colors.white10
                                        : Colors.grey[200]!,
                                    width: currentAppearance == 'system'
                                        ? 2
                                        : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF3C3E4A)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.settings_display,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'System Default',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Follows your device theme settings',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentAppearance == 'system')
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF8B5CF6),
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Light Mode Option
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  currentAppearance = 'light';
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: currentAppearance == 'light'
                                      ? isDark
                                            ? const Color(
                                                0xFFF59E0B,
                                              ).withOpacity(0.15)
                                            : const Color(0xFFFEF3C7)
                                      : isDark
                                      ? const Color(0xFF252836)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: currentAppearance == 'light'
                                        ? const Color(0xFFF59E0B)
                                        : isDark
                                        ? Colors.white10
                                        : Colors.grey[200]!,
                                    width: currentAppearance == 'light' ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.amber[300]!,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.light_mode,
                                          color: Colors.amber[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Light Mode',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Always use light theme',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentAppearance == 'light')
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFFF59E0B),
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Dark Mode Option
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  currentAppearance = 'dark';
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: currentAppearance == 'dark'
                                      ? isDark
                                            ? const Color(
                                                0xFF3B82F6,
                                              ).withOpacity(0.15)
                                            : const Color(0xFFDBEAFE)
                                      : isDark
                                      ? const Color(0xFF252836)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: currentAppearance == 'dark'
                                        ? const Color(0xFF3B82F6)
                                        : isDark
                                        ? Colors.white10
                                        : Colors.grey[200]!,
                                    width: currentAppearance == 'dark' ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF475569),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.dark_mode,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dark Mode',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Always use dark theme',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentAppearance == 'dark')
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(0xFF3B82F6),
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // Note about appearance
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withOpacity(0.5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDark ? Colors.blue[300] : Colors.blue[600],
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your selection will apply across the app',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.blue[200]
                                    : Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    HoopButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _updateAppearance(currentAppearance);
                      },
                      buttonText: 'Apply Theme',
                    ),

                    // Apply Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 52,
                    //   child: ElevatedButton(
                    //     onPressed: () async {
                    //       Navigator.pop(context);
                    //       await _updateAppearance(currentAppearance);
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFF8B5CF6),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(14),
                    //       ),
                    //       elevation: 0,
                    //     ),
                    //     child: const Text(
                    //       'Apply Theme',
                    //       style: TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateAppearance(String appearance) async {
    final authProvider = context.read<AuthProvider>();
    try {
      final response = await authProvider.updateProfile({
        'appearance': appearance,
      });

      if (response.success) {
        // Refresh the profile to get updated appearance
        await authProvider.getProfile();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appearance updated to ${appearance == 'system'
                  ? 'System Default'
                  : appearance == 'light'
                  ? 'Light Mode'
                  : 'Dark Mode'}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update appearance: ${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appearance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationDetails(
    BuildContext context,
    PersonalInfo personalInfo,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Location Details', style: TextStyle(color: textPrimary)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (personalInfo.latitude != null &&
                  personalInfo.longitude != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordinates',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '${personalInfo.latitude}, ${personalInfo.longitude}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (personalInfo.lastLocationUpdate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      _formatDate(personalInfo.lastLocationUpdate),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required bool isDark,
    required Color textPrimary,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceOption(
    String title,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: const Color(0xFF0a1866))
          : null,
      onTap: onTap,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isDark ? 8 : 6,
              offset: isDark ? const Offset(0, 3) : const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E1620) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 24)),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: textSecondary, size: 24),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.45,
          maxChildSize: 0.65,
          expand: false,
          builder: (context, controller) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logout icon at top
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFDC2626).withOpacity(0.2)
                            : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDC2626),
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_outlined,
                        color: Color(0xFFDC2626),
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Warning note box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF7F1D1D).withOpacity(0.2)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFEF4444).withOpacity(0.3)
                              : const Color(0xFFFECACA),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Important:',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFB91C1C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your session data will be cleared and you\'ll need to log in again to access your account.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Saved login credentials will be removed\n• Session tokens will be cleared\n• You\'ll be redirected to the login screen',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Stay Logged In',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await authProvider.logout();

                              // Show confirmation message
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Successfully logged out',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: const Color(0xFF16A34A),
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              // Navigate to login screen (you might need to adjust this)
                              // Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
