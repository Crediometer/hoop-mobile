import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/screens/auth/password_reset/verify_otp_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class PasswordResetScreen extends StatefulWidget {
  final String? initialEmail;

  const PasswordResetScreen({super.key, this.initialEmail});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);
      final response = await authService.forgotPassword(
        _emailController.text.trim(),
      );

      if (!response.success) {
        setState(() {
          _errorMessage = response.error ?? 'Failed to send verification code';
        });
        return;
      }

      // if (response.requestId != null) {
      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyOtpScreen(
            email: _emailController.text.trim(),
            requestId: "response.requestId!",
          ),
        ),
      );
      // }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification code';
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
      backgroundColor: isDark ? const Color(0xFF0C0E1A) : Colors.grey[100],
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
              const SignupProgressBar(currentStep: 1, totalSteps: 4),
              const SizedBox(height: 32),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1F2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_reset_outlined,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Reset Your Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email address and we'll send you a verification code",
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
                    Text(
                      "Email Address",
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    HoopInput(
                      controller: _emailController,
                      hintText: 'john@example.com',
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleRequestReset(),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    HoopButton(
                      buttonText: "Send Verification Code →",
                      isLoading: _isLoading,
                      onPressed: _handleRequestReset,
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
}
