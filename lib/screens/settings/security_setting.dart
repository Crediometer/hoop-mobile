import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
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
  bool _isUpdatingPIN = false;
  bool _isUpdatingBiometricLogin = false;
  bool _isUpdatingBiometricTransaction = false;

  // Password form state
  final Map<String, String> _passwordForm = {
    'currentPassword': '',
    'newPassword': '',
    'confirmPassword': '',
  };

  // PIN form state
  final Map<String, String> _pinForm = {
    'currentPIN': '',
    'newPIN': '',
    'confirmPIN': '',
  };

  final Map<String, String> _formErrors = {};
  final Map<String, String> _pinErrors = {};

  // Security features state
  bool? _twoFactorEnabled;
  bool? _loginNotifications;
  bool? _pinEnabled;
  bool? _biometricLoginEnabled;
  bool? _biometricTransactionEnabled;

  // Text controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  
  final TextEditingController _currentPINController = TextEditingController();
  final TextEditingController _newPINController = TextEditingController();
  final TextEditingController _confirmPINController = TextEditingController();

  // PIN visibility
  bool _showCurrentPIN = false;
  bool _showNewPIN = false;
  bool _showConfirmPIN = false;

  // PIN operation state
  bool _isSettingUpPIN = false;
  bool _isChangingPIN = false;

  // Local auth instance
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadUserSecuritySettings();
    _checkBiometricsAvailable();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPINController.dispose();
    _newPINController.dispose();
    _confirmPINController.dispose();
    super.dispose();
  }

  void _loadUserSecuritySettings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      setState(() {
        _twoFactorEnabled = user.is2faEnabled ?? false;
        _loginNotifications = user.loginNotification ?? false;
        _pinEnabled = user.isPinSet ?? false;
        _biometricLoginEnabled = user.biometricLoginEnabled ?? false;
        _biometricTransactionEnabled =
            user.biometricTransactionEnabled ?? false;
      });
    }
  }

  Future<void> _checkBiometricsAvailable() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      print('Biometrics available: $available');
    } catch (e) {
      print('Error checking biometrics: $e');
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

  String _formatLastPINUpdate(String? lastPINUpdate) {
    if (lastPINUpdate == null || lastPINUpdate.isEmpty) {
      return "Never";
    }

    try {
      final lastUpdate = DateTime.parse(lastPINUpdate);
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

  bool _validatePIN(String pin) {
    return RegExp(r'^[0-9]{4,6}$').hasMatch(pin);
  }

  bool _validatePasswordForm() {
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

  bool _validatePINForm({bool requireCurrentPIN = true}) {
    final errors = <String, String>{};

    if (requireCurrentPIN) {
      final currentPIN = _pinForm['currentPIN'] ?? '';
      if (currentPIN.isEmpty) {
        errors['currentPIN'] = "Current PIN is required";
      } else if (!_validatePIN(currentPIN)) {
        errors['currentPIN'] = "Current PIN must be 4-6 digits";
      }
    }

    // Validate new PIN
    final newPIN = _pinForm['newPIN'] ?? '';
    if (newPIN.isEmpty) {
      errors['newPIN'] = "New PIN is required";
    } else if (!_validatePIN(newPIN)) {
      errors['newPIN'] = "PIN must be 4-6 digits";
    }

    // Validate confirm PIN
    final confirmPIN = _pinForm['confirmPIN'] ?? '';
    if (confirmPIN.isEmpty) {
      errors['confirmPIN'] = "Please confirm your new PIN";
    } else if (newPIN != confirmPIN) {
      errors['confirmPIN'] = "PINs do not match";
    }

    setState(() => _pinErrors.clear());
    if (errors.isNotEmpty) {
      setState(() => _pinErrors.addAll(errors));
      return false;
    }

    return true;
  }

  Future<void> _handlePasswordChange() async {
    if (!_validatePasswordForm()) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Password changed successfully. Please log in again.",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );

        Navigator.of(context).pop(); // Close the dialog
        _resetPasswordForm();

        await Future.delayed(const Duration(milliseconds: 1500));
        await authProvider.logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to change password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("Password change error: $error");
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

  Future<void> _handlePINSetup() async {
    if (!_validatePINForm(requireCurrentPIN: false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the form errors before submitting"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSettingUpPIN = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.setPin({
        'transactionPin': _pinForm['newPIN']!,
        'transactionPINConfirmation': _pinForm['confirmPIN']!,
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("PIN setup successfully"),
            backgroundColor: HoopTheme.successGreen,
          ),
        );

        Navigator.of(context).pop(); // Close the dialog
        _resetPINForm();
        
        setState(() {
          _pinEnabled = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to setup PIN"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("PIN setup error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSettingUpPIN = false);
    }
  }

  Future<void> _handlePINChange() async {
    if (!_validatePINForm(requireCurrentPIN: true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the form errors before submitting"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isChangingPIN = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.updatePin({
        'currentPin': _pinForm['currentPIN']!,
        'newPin': _pinForm['newPIN']!,
        'newPinConfirmation': _pinForm['confirmPIN']!,
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("PIN changed successfully"),
            backgroundColor: HoopTheme.successGreen,
          ),
        );

        Navigator.of(context).pop(); // Close the dialog
        _resetPINForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to change PIN"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("PIN change error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isChangingPIN = false);
    }
  }

  Future<void> _handlePINToggle(bool enabled) async {
    setState(() => _isUpdatingPIN = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (enabled) {
        _showSetupPINBottomSheet();
      }
    } catch (error) {
      print("PIN toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _pinEnabled = !enabled);
    } finally {
      setState(() => _isUpdatingPIN = false);
    }
  }

  Future<void> _handleBiometricLoginToggle(bool enabled) async {
    setState(() => _isUpdatingBiometricLogin = true);

    try {
      if (enabled) {
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        
        if (!canCheckBiometrics) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometrics not available on this device"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _biometricLoginEnabled = false);
          return;
        }

        // Authenticate with biometrics before enabling
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
          biometricOnly: true,
          sensitiveTransaction: true,
        );

        if (!authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Authentication failed"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _biometricLoginEnabled = false);
          return;
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updateData = {'biometricLoginEnabled': enabled};
      final result = await authProvider.updateProfile(updateData);

      if (result.success) {
        setState(() => _biometricLoginEnabled = enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Biometric login ${enabled ? 'enabled' : 'disabled'} successfully",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? "Failed to update biometric login",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _biometricLoginEnabled = !enabled);
      }
    } catch (error) {
      print("Biometric login toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _biometricLoginEnabled = !enabled);
    } finally {
      setState(() => _isUpdatingBiometricLogin = false);
    }
  }

  Future<void> _handleBiometricTransactionToggle(bool enabled) async {
    setState(() => _isUpdatingBiometricTransaction = true);

    try {
      if (enabled) {
        // Check if PIN is enabled (prerequisite)
        if (_pinEnabled != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enable PIN first to use biometric transactions"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _biometricTransactionEnabled = false);
          return;
        }

        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        
        if (!canCheckBiometrics) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometrics not available on this device"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _biometricTransactionEnabled = false);
          return;
        }

        // Authenticate with biometrics before enabling
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric transactions',
          biometricOnly: true,
          sensitiveTransaction: true,
        );

        if (!authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Authentication failed"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _biometricTransactionEnabled = false);
          return;
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updateData = {'biometricTransactionEnabled': enabled};
      final result = await authProvider.updateProfile(updateData);

      if (result.success) {
        setState(() => _biometricTransactionEnabled = enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Biometric transactions ${enabled ? 'enabled' : 'disabled'} successfully",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? "Failed to update biometric transactions",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _biometricTransactionEnabled = !enabled);
      }
    } catch (error) {
      print("Biometric transaction toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _biometricTransactionEnabled = !enabled);
    } finally {
      setState(() => _isUpdatingBiometricTransaction = false);
    }
  }

  Future<void> _handle2FAToggle(bool enabled) async {
    setState(() => _isUpdating2FA = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updateData = {'is2faEnabled': enabled};

      final result = await authProvider.updateProfile(updateData);

      if (result.success) {
        setState(() => _twoFactorEnabled = enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Two-factor authentication ${enabled ? 'enabled' : 'disabled'} successfully",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to update 2FA"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _twoFactorEnabled = !enabled);
      }
    } catch (error) {
      print("2FA toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
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
        setState(() => _loginNotifications = enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login notifications ${enabled ? 'enabled' : 'disabled'} successfully",
            ),
            backgroundColor: HoopTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? "Failed to update login notifications",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loginNotifications = !enabled);
      }
    } catch (error) {
      print("Login notifications toggle error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loginNotifications = !enabled);
    } finally {
      setState(() => _isUpdatingLoginNotifications = false);
    }
  }

  void _showSetupPINBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
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
                        // PIN icon at top
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
                            Icons.pin_outlined,
                            color: Color(0xFF3B82F6),
                            size: 50,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Setup PIN',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a 4-6 digit PIN for secure access',
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

                        // New PIN
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _newPINController,
                              hintText: 'Enter 4-6 digit PIN',
                              obscureText: !_showNewPIN,
                              keyboardType: TextInputType.number,
                              errorText: _pinErrors['newPIN'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showNewPIN
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showNewPIN = !_showNewPIN;
                                }),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _pinForm['newPIN'] = value;
                                  if (_pinErrors.containsKey('newPIN')) {
                                    _pinErrors.remove('newPIN');
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Confirm PIN
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _confirmPINController,
                              hintText: 'Confirm 4-6 digit PIN',
                              obscureText: !_showConfirmPIN,
                              keyboardType: TextInputType.number,
                              errorText: _pinErrors['confirmPIN'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPIN
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showConfirmPIN = !_showConfirmPIN;
                                }),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _pinForm['confirmPIN'] = value;
                                  if (_pinErrors.containsKey('confirmPIN')) {
                                    _pinErrors.remove('confirmPIN');
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // PIN Requirements Note
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
                                    'PIN Requirements:',
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
                                '4-6 digits only',
                                RegExp(r'^[0-9]{4,6}$').hasMatch(_pinForm['newPIN'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'No repeating patterns',
                                !RegExp(r'(\d)\1{2,}').hasMatch(_pinForm['newPIN'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'Not sequential (e.g., 1234)',
                                !RegExp(r'0123|1234|2345|3456|4567|5678|6789|7890').hasMatch(_pinForm['newPIN'] ?? ''),
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
                                  _resetPINForm();
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
                                onPressed: _isSettingUpPIN
                                    ? null
                                    : _handlePINSetup,
                                buttonText: 'Setup PIN',
                                isLoading: _isSettingUpPIN,
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

  void _showChangePINBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.6,
          maxChildSize: 0.9,
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
                        // PIN icon at top
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
                            Icons.pin_outlined,
                            color: Color(0xFF3B82F6),
                            size: 50,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Change PIN',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your current PIN and set a new one',
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

                        // Current PIN
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _currentPINController,
                              hintText: 'Enter current PIN',
                              obscureText: !_showCurrentPIN,
                              keyboardType: TextInputType.number,
                              errorText: _pinErrors['currentPIN'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showCurrentPIN
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showCurrentPIN = !_showCurrentPIN;
                                }),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _pinForm['currentPIN'] = value;
                                  if (_pinErrors.containsKey('currentPIN')) {
                                    _pinErrors.remove('currentPIN');
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // New PIN
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _newPINController,
                              hintText: 'Enter new 4-6 digit PIN',
                              obscureText: !_showNewPIN,
                              keyboardType: TextInputType.number,
                              errorText: _pinErrors['newPIN'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showNewPIN
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showNewPIN = !_showNewPIN;
                                }),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _pinForm['newPIN'] = value;
                                  if (_pinErrors.containsKey('newPIN')) {
                                    _pinErrors.remove('newPIN');
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Confirm PIN
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm PIN',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            HoopInput(
                              controller: _confirmPINController,
                              hintText: 'Confirm new PIN',
                              obscureText: !_showConfirmPIN,
                              keyboardType: TextInputType.number,
                              errorText: _pinErrors['confirmPIN'],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPIN
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () => setState(() {
                                  _showConfirmPIN = !_showConfirmPIN;
                                }),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _pinForm['confirmPIN'] = value;
                                  if (_pinErrors.containsKey('confirmPIN')) {
                                    _pinErrors.remove('confirmPIN');
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // PIN Requirements Note
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
                                    'PIN Requirements:',
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
                                '4-6 digits only',
                                RegExp(r'^[0-9]{4,6}$').hasMatch(_pinForm['newPIN'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'Not the same as old PIN',
                                _pinForm['newPIN'] != _pinForm['currentPIN'],
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'No repeating patterns',
                                !RegExp(r'(\d)\1{2,}').hasMatch(_pinForm['newPIN'] ?? ''),
                                isDark: isDark,
                              ),
                              _buildRequirement(
                                'Not sequential',
                                !RegExp(r'0123|1234|2345|3456|4567|5678|6789|7890').hasMatch(_pinForm['newPIN'] ?? ''),
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
                                  _resetPINForm();
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
                                onPressed: _isChangingPIN
                                    ? null
                                    : _handlePINChange,
                                buttonText: 'Change PIN',
                                isLoading: _isChangingPIN,
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

  void _resetPINForm() {
    setState(() {
      _pinForm.clear();
      _pinErrors.clear();
      _currentPINController.clear();
      _newPINController.clear();
      _confirmPINController.clear();
      _showCurrentPIN = false;
      _showNewPIN = false;
      _showConfirmPIN = false;
    });
  }

  void _handleInputChange(String field, String value) {
    setState(() {
      _passwordForm[field] = value;

      if (_formErrors.containsKey(field)) {
        _formErrors.remove(field);
      }
    });
  }

  void _handleReportSecurityIssue() {
    Navigator.pushNamed(context, "/support/security-issue");
  }

  Map<String, dynamic> _getSecurityStatus() {
    final bool twoFA = _twoFactorEnabled ?? false;
    final bool loginNotif = _loginNotifications ?? false;
    final bool pinEnabled = _pinEnabled ?? false;
    final bool biometricLogin = _biometricLoginEnabled ?? false;

    int securityScore = 0;
    if (twoFA) securityScore += 2;
    if (loginNotif) securityScore += 1;
    if (pinEnabled) securityScore += 1;
    if (biometricLogin) securityScore += 1;

    if (securityScore >= 4) {
      return {
        'status': "Strong",
        'badge': "Secure",
        'color': HoopTheme.successGreen,
        'textColor': "success-green",
      };
    } else if (securityScore >= 2) {
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
      )
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
          Expanded(
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                          if (status == "requires-pin")
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Requires PIN',
                                style: TextStyle(
                                  color: Colors.blue,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                  onChanged: status == "requires-pin" && !enabled
                      ? null // Disable toggle if PIN is required but not enabled
                      : onToggle,
                  activeColor: HoopTheme.successGreen,
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
                                      Icons.pin_outlined,
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
                                        'PIN',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _pinEnabled == true
                                            ? 'Last changed ${_formatLastPINUpdate(user?.lastPINUpdate?.toIso8601String())}'
                                            : 'Not set up',
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
                                onPressed: _pinEnabled == true
                                    ? _showChangePINBottomSheet
                                    : () => _handlePINToggle(true),
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
                                child: Text(_pinEnabled == true ? 'Change' : 'Setup'),
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

                    // Biometrics Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometrics',
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
                              // Biometric Login
                              _buildSecurityFeature(
                                title: "Biometric Login",
                                description: "Login without password",
                                icon: Icons.fingerprint,
                                enabled: _biometricLoginEnabled ?? false,
                                isUpdating: _isUpdatingBiometricLogin,
                                onToggle: _handleBiometricLoginToggle,
                                status: "recommended",
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),

                              // Biometric Transactions
                              _buildSecurityFeature(
                                title: "Biometric Transactions",
                                description:
                                    "Authorize transactions with biometrics",
                                icon: Icons.monetization_on_outlined,
                                enabled: _biometricTransactionEnabled ?? false,
                                isUpdating: _isUpdatingBiometricTransaction,
                                onToggle: _handleBiometricTransactionToggle,
                                status: _pinEnabled == true
                                    ? "recommended"
                                    : "requires-pin",
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
}