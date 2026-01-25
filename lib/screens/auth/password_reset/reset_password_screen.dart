import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/screens/auth/password_reset/reset_success_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/progress_bar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String requestId;
  final String verificationId;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.requestId,
    required this.verificationId,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  String? _errorMessage;

  List<String> _passwordErrors = [];

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    final validation = Validators.password(password);
    setState(() {
      _passwordErrors = [validation!];
    });
  }

  bool _isFormValid() {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      return false;
    }

    final passwordValidation = Validators.password(_passwordController.text);
    if (passwordValidation!.isEmpty) {
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      return false;
    }

    return true;
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);
      final response = await authService.resetPassword(
        widget.verificationId,
        widget.requestId,
        _passwordController.text,
      );

      if (!response.success) {
        setState(() {
          _errorMessage = response.error ?? 'Failed to reset password';
        });
        return;
      }

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ResetSuccessScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reset password';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const SignupProgressBar(currentStep: 3, totalSteps: 4),
              const SizedBox(height: 32),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1F2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Create New Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your new password must be different from previous used passwords",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Password
                    Text(
                      "New Password",
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopPasswordInput(
                      controller: _passwordController,
                      hintText: 'Enter new password',
                      validator: (value) =>
                          Validators.password(value, minLength: 8),
                      onChanged: (value) => _validatePassword(value),
                    ),

                    // Password requirements
                    if (_passwordController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1F2E)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password requirements:",
                              style: TextStyle(
                                color: isDark ? Colors.grey : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._buildPasswordRequirements(),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    Text(
                      "Confirm New Password",
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopPasswordInput(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm new password',
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Reset Button
                    HoopButton(
                      buttonText: "Reset Password",
                      isLoading: _isLoading,
                      onPressed: _isFormValid() ? _handleResetPassword : null,
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

  List<Widget> _buildPasswordRequirements() {
    final password = _passwordController.text;
    final requirements = [
      {
        'check': password.length >= 8,
        'text': 'At least 8 characters',
      },
      {
        'check': RegExp(r'[A-Z]').hasMatch(password),
        'text': 'One uppercase letter',
      },
      {
        'check': RegExp(r'[a-z]').hasMatch(password),
        'text': 'One lowercase letter',
      },
      {
        'check': RegExp(r'\d').hasMatch(password),
        'text': 'One number',
      },
      {
        'check':
            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
        'text': 'One special character',
      },
    ];

    return requirements.map((req) {
      final isMet = req['check'] as bool;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: isMet ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              req['text'] as String,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}