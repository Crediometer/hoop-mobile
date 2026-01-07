import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:provider/provider.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  // Password visibility states
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isChangingPassword = false;
  bool _isUpdating2FA = false;
  bool _isUpdatingLoginNotifications = false;

  // Password form state
  final Map<String, String> _passwordForm = {
    'currentPassword': '',
    'newPassword': '',
    'confirmPassword': '',
  };

  final Map<String, String> _formErrors = {};

  // Security features state - using separate state variables
  bool? _twoFactorEnabled;
  bool? _loginNotifications;

  // Text controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserSecuritySettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserSecuritySettings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      setState(() {
        _twoFactorEnabled = user.is2faEnabled ?? false;
        _loginNotifications = user.loginNotification ?? false;
      });
    }
  }

  String _formatLastPasswordUpdate(String? lastPasswordUpdate) {
    if (lastPasswordUpdate == null || lastPasswordUpdate.isEmpty) {
      return "Never";
    }

    try {
      final lastUpdate = DateTime.parse(lastPasswordUpdate);
      final now = DateTime.now();
      final diffTime = now.difference(lastUpdate).inDays;

      if (diffTime == 1) return "1 day ago";
      if (diffTime < 7) return "$diffTime days ago";
      if (diffTime < 30) return "${(diffTime / 7).ceil()} weeks ago";
      return "${(diffTime / 30).ceil()} months ago";
    } catch (e) {
      return "Recently";
    }
  }

  List<String> _validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add("At least 8 characters");
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(password)) {
      errors.add("One lowercase letter");
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(password)) {
      errors.add("One uppercase letter");
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(password)) {
      errors.add("One number");
    }
    if (!RegExp(
      r'(?=.*[!@#$%^&*()_+\-=[\]{};:"\\|,.<>/?])',
    ).hasMatch(password)) {
      errors.add("One special character");
    }

    return errors;
  }

  bool _validateForm() {
    final errors = <String, String>{};

    // Validate current password
    if (_passwordForm['currentPassword']?.isEmpty ?? true) {
      errors['currentPassword'] = "Current password is required";
    }

    // Validate new password
    final newPassword = _passwordForm['newPassword'] ?? '';
    if (newPassword.isEmpty) {
      errors['newPassword'] = "New password is required";
    } else {
      final passwordErrors = _validatePassword(newPassword);
      if (passwordErrors.isNotEmpty) {
        errors['newPassword'] =
            "Password must contain: ${passwordErrors.join(", ")}";
      }
    }

    // Validate confirm password
    final confirmPassword = _passwordForm['confirmPassword'] ?? '';
    if (confirmPassword.isEmpty) {
      errors['confirmPassword'] = "Please confirm your new password";
    } else if (newPassword != confirmPassword) {
      errors['confirmPassword'] = "Passwords do not match";
    }

    setState(() => _formErrors.clear());
    if (errors.isNotEmpty) {
      setState(() => _formErrors.addAll(errors));
      return false;
    }

    return true;
  }

  Future<void> _handlePasswordChange() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the form errors before submitting"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.changePassword(
        _passwordForm['currentPassword']!,
        _passwordForm['newPassword']!,
        _passwordForm['confirmPassword']!,
      );

      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Password changed successfully. Please log in again.",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );

        // Close dialog and reset form
        Navigator.of(context).pop(); // Close the dialog
        _resetPasswordForm();

        // Logout user after successful password change
        await Future.delayed(const Duration(milliseconds: 1500));
        await authProvider.logout();
        // Navigator.pushReplacementNamed(context, "/login");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to change password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      log("Password change error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _handle2FAToggle(bool enabled) async {
    setState(() => _isUpdating2FA = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updateData = {'is2faEnabled': enabled};

      final result = await authProvider.updateProfile(updateData);

      if (result.success) {
        // Update local state
        setState(() => _twoFactorEnabled = enabled);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Two-factor authentication ${enabled ? 'enabled' : 'disabled'} successfully",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        // Show error message and revert state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to update 2FA"),
            backgroundColor: Colors.red,
          ),
        );

        // Revert the state
        setState(() => _twoFactorEnabled = !enabled);
      }
    } catch (error) {
      log("2FA toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );

      // Revert the state on error
      setState(() => _twoFactorEnabled = !enabled);
    } finally {
      setState(() => _isUpdating2FA = false);
    }
  }

  Future<void> _handleLoginNotificationsToggle(bool enabled) async {
    setState(() => _isUpdatingLoginNotifications = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updateData = {'loginNotification': enabled};

      final result = await authProvider.updateProfile(updateData);

      if (result.success) {
        // Update local state
        setState(() => _loginNotifications = enabled);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login notifications ${enabled ? 'enabled' : 'disabled'} successfully",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        // Show error message and revert state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? "Failed to update login notifications",
            ),
            backgroundColor: Colors.red,
          ),
        );

        // Revert the state
        setState(() => _loginNotifications = !enabled);
      }
    } catch (error) {
      log("Login notifications toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );

      // Revert the state on error
      setState(() => _loginNotifications = !enabled);
    } finally {
      setState(() => _isUpdatingLoginNotifications = false);
    }
  }

  void _resetPasswordForm() {
    setState(() {
      _passwordForm.clear();
      _formErrors.clear();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showCurrentPassword = false;
      _showNewPassword = false;
      _showConfirmPassword = false;
    });
  }

  void _handleInputChange(String field, String value) {
    setState(() {
      _passwordForm[field] = value;

      // Clear error when user starts typing
      if (_formErrors.containsKey(field)) {
        _formErrors.remove(field);
      }
    });
  }

  void _handleReportSecurityIssue() {
    // Navigate to security issue reporting
    Navigator.pushNamed(context, "/support/security-issue");
  }

  Map<String, dynamic> _getSecurityStatus() {
    final bool twoFA = _twoFactorEnabled ?? false;
    final bool loginNotif = _loginNotifications ?? false;

    if (twoFA && loginNotif) {
      return {
        'status': "Strong",
        'badge': "Secure",
        'color': HoopTheme.successGreen,
        'textColor': "success-green",
      };
    } else if (twoFA || loginNotif) {
      return {
        'status': "Moderate",
        'badge': "Good",
        'color': HoopTheme.vibrantOrange,
        'textColor': "vibrant-orange",
      };
    } else {
      return {
        'status': "Weak",
        'badge': "At Risk",
        'color': Colors.red,
        'textColor': "red-500",
      };
    }
  }

  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.65,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setState) {
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
                        // Key icon at top
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3B82F6).withOpacity(0.2)
                                : const Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B82F6),
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF3B82F6),
                            size: 50,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Update your account password securely',
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

                        // Current Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _currentPasswordController,
                              hintText: 'Enter current password',
                              obscureText: !_showCurrentPassword,
                              errorText: _formErrors['currentPassword'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showCurrentPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showCurrentPassword = !_showCurrentPassword;
                                }),
                              ),
                              onChanged: (value) =>
                                  _handleInputChange('currentPassword', value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // New Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _newPasswordController,
                              hintText: 'Enter new password',
                              obscureText: !_showNewPassword,
                              errorText: _formErrors['newPassword'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showNewPassword = !_showNewPassword;
                                }),
                              ),
                              onChanged: (value) =>
                                  _handleInputChange('newPassword', value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Confirm Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm New Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm new password',
                              obscureText: !_showConfirmPassword,
                              errorText: _formErrors['confirmPassword'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                }),
                              ),
                              onChanged: (value) =>
                                  _handleInputChange('confirmPassword', value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Password Requirements Note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withOpacity(0.5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFF1E40AF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildRequirement(
                                'At least 8 characters',
                                ((_passwordForm['newPassword']?.length ?? 0) >=
                                    8),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'One uppercase letter',
                                RegExp(
                                  r'(?=.*[A-Z])',
                                ).hasMatch(_passwordForm['newPassword'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'One lowercase letter',
                                RegExp(
                                  r'(?=.*[a-z])',
                                ).hasMatch(_passwordForm['newPassword'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'One number',
                                RegExp(
                                  r'(?=.*\d)',
                                ).hasMatch(_passwordForm['newPassword'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'One special character',
                                RegExp(
                                  r'(?=.*[!@#$%^&*()_+\-=[\]{};:"\\|,.<>/?])',
                                ).hasMatch(_passwordForm['newPassword'] ?? ''),
                                isDark: isDark,
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
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _resetPasswordForm();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: HoopButton(
                                onPressed: _isChangingPassword
                                    ? null
                                    : _handlePasswordChange,
                                buttonText: 'Change Password',
                                isLoading: _isChangingPassword,
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
      },
    );
  }

  Widget _buildRequirement(
    String text,
    bool satisfied, {
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle,
            size: 14,
            color: satisfied
                ? const Color(0xFF10B981)
                : isDark
                ? Colors.white30
                : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: satisfied
                  ? const Color(0xFF10B981)
                  : isDark
                  ? Colors.white60
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = HoopTheme.getTextPrimary(isDark);
    final textSecondary = HoopTheme.getTextSecondary(isDark);
    final backgroundColor = isDark ? HoopTheme.darkBackground : Colors.grey[50];

    final securityStatus = _getSecurityStatus();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const HoopBackButton(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security',
                        style: TextStyle(
                          color: HoopTheme.primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your account security',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Security Status
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            securityStatus['color']!.withOpacity(0.1),
                            HoopTheme.primaryBlue.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: securityStatus['color']!.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: securityStatus['color']!.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: securityStatus['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Account Security: ${securityStatus['status']}",
                                  style: TextStyle(
                                    color: securityStatus['color'],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _twoFactorEnabled == true
                                      ? "2FA enabled"
                                      : "Enable 2FA for better security",
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: securityStatus['color'],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              securityStatus['badge'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Password Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password & Authentication',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: HoopTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.key,
                                      size: 20,
                                      color: HoopTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Password',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Last changed ${_formatLastPasswordUpdate(user?.lastPasswordUpdate?.toIso8601String())}',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              OutlinedButton(
                                onPressed: _showChangePasswordDialog,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HoopTheme.primaryBlue,
                                  side: BorderSide(
                                    color: HoopTheme.primaryBlue,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Security Features
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Features',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            children: [
                              // Two-Factor Authentication
                              _buildSecurityFeature(
                                title: "Two-Factor Authentication",
                                description:
                                    "Add an extra layer of security to your account",
                                icon: Icons.phone_android,
                                enabled: _twoFactorEnabled ?? false,
                                isUpdating: _isUpdating2FA,
                                onToggle: _handle2FAToggle,
                                status: "recommended",
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),

                              // Login Notifications
                              _buildSecurityFeature(
                                title: "Login Notifications",
                                description:
                                    "Get notified when someone logs into your account",
                                icon: Icons.notifications_active,
                                enabled: _loginNotifications ?? false,
                                isUpdating: _isUpdatingLoginNotifications,
                                onToggle: _handleLoginNotificationsToggle,
                                status: "recommended",
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Emergency Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Actions',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleReportSecurityIssue,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Report Security Issue'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature({
    required String title,
    required String description,
    required IconData icon,
    required bool enabled,
    required bool isUpdating,
    required Function(bool) onToggle,
    required String status,
    required bool isDark,
    required Color textPrimary,
    required Color? textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
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
                  color: enabled
                      ? HoopTheme.successGreen.withOpacity(0.1)
                      : isDark
                      ? Colors.grey[700]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? HoopTheme.successGreen : textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (status == "recommended")
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: HoopTheme.vibrantOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              color: HoopTheme.vibrantOrange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          isUpdating
              ? SizedBox(
                  width: 48,
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: HoopTheme.primaryBlue,
                      ),
                    ),
                  ),
                )
              : Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: HoopTheme.successGreen,
                ),
        ],
      ),
    );
  }
}
