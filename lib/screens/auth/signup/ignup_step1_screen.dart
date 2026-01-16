import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/screens/auth/signup/signup_step2_otp_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  Future<void> goToNextStep() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      final authProvider = context.read<AuthProvider>();

      if (!authProvider.acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to Terms and Privacy Policy'),
          ),
        );
        return;
      }

      final result = await authProvider.sendEmailVerification();
      setState(() => isLoading = false);
      if (mounted) {
        Navigator.pop(context); // Hide loading

        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignupStep2OtpScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to send verification code',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors that adapt to system mode
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey : Colors.black54;

    // Get controllers from provider
    final firstNameController = authProvider.firstNameController;
    final lastNameController = authProvider.lastNameController;
    final emailController = authProvider.emailController;
    final phoneController = authProvider.phoneController;
    final passwordController = authProvider.passwordController;
    final confirmPasswordController = authProvider.confirmPasswordController;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0E1A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              const SignupProgressBar(currentStep: 1, totalSteps: 6),
              const SizedBox(height: 24),

              // Back button and title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                "Join the Hoop community",
                style: TextStyle(color: hintColor, fontSize: 14),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First Name
                    _buildLabel("First Name", textColor),
                    HoopInput(
                      controller: firstNameController,
                      hintText: "John",
                      validator: (value) => value!.isEmpty
                          ? "Please enter your first name"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Last Name
                    _buildLabel("Last Name", textColor),
                    HoopInput(
                      controller: lastNameController,
                      hintText: 'Doe',
                      validator: (value) =>
                          value!.isEmpty ? "Please enter your last name" : null,
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildLabel("Email Address", textColor),
                    HoopInput(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: "john@example.com",
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!value.contains("@") || !value.contains(".")) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    _buildLabel("Phone Number", textColor),
                    HoopInput(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      hintText: "+234 800 000 0000",
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Enter your phone number";
                        }
                        // Remove non-digits for validation
                        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length < 10 || digitsOnly.length > 15) {
                          return "Enter a valid phone number (10-15 digits)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    _buildLabel("Password", textColor),
                    HoopInput(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      onChanged: (value) => setState(() {}),
                      hintText: "Create a strong password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Iconsax.eye : Iconsax.eye_slash1,
                          color: hintColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        }
                        if (value.length < 8) {
                          return "Password must be at least 8 characters";
                        }
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          return "Password must contain uppercase letter";
                        }
                        if (!value.contains(RegExp(r'[a-z]'))) {
                          return "Password must contain lowercase letter";
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return "Password must contain a number";
                        }
                        if (!value.contains(
                          RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                        )) {
                          return "Password must contain a special character";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Must be at least 8 characters with numbers and symbols",
                        style: TextStyle(color: hintColor, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password strength indicator
                    if (passwordController.text.isNotEmpty)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return _buildPasswordStrength(
                            isDark,
                            textColor,
                            authProvider,
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    _buildLabel("Confirm Password", textColor),
                    HoopInput(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      onChanged: (value) => setState(() {}),
                      hintText: "Confirm your password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Iconsax.eye
                              : Iconsax.eye_slash1,
                          color: hintColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm your password";
                        }
                        if (value != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Terms and Conditions
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Row(
                          children: [
                            Checkbox(
                              value: authProvider.acceptTerms,
                              onChanged: (value) {
                                authProvider.setAcceptTerms(value ?? false);
                              },
                              activeColor: Colors.blueAccent,
                            ),
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  // Optionally toggle checkbox on text tap
                                  authProvider.setAcceptTerms(
                                    !authProvider.acceptTerms,
                                  );
                                },
                                child: Wrap(
                                  children: [
                                    Text(
                                      "I agree to the ",
                                      style: TextStyle(color: textColor),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to terms
                                      },
                                      child: const Text(
                                        "Terms of Service",
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      " and ",
                                      style: TextStyle(color: textColor),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to privacy policy
                                      },
                                      child: const Text(
                                        "Privacy Policy",
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return HoopButton(
                          buttonText: "Send Verification Code →",
                          onPressed: authProvider.acceptTerms
                              ? goToNextStep
                              : null,
                          isLoading: isLoading,
                          disabled: !authProvider.acceptTerms,
                        );
                      },
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

  Widget _buildLabel(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
      ),
    );
  }

  Widget _buildPasswordStrength(
    bool isDark,
    Color textColor,
    AuthProvider authProvider,
  ) {
    // Calculate validation using provider's password text
    final password = authProvider.passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final passwordsMatch =
        password == authProvider.confirmPasswordController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Password must contain:",
            style: TextStyle(color: textColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _PasswordRequirement(
                      text: "8+ characters",
                      isValid: hasMinLength,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _PasswordRequirement(
                      text: "Lowercase letter",
                      isValid: hasLowercase,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _PasswordRequirement(
                      text: "Special character",
                      isValid: hasSpecialChar,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _PasswordRequirement(
                      text: "Uppercase letter",
                      isValid: hasUppercase,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _PasswordRequirement(
                      text: "Number",
                      isValid: hasNumber,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _PasswordRequirement(
                      text: "Passwords match",
                      isValid: passwordsMatch,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isValid;
  final bool isDark;

  const _PasswordRequirement({
    required this.text,
    required this.isValid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isValid
                ? Colors.green
                : (isDark ? Colors.grey[600] : Colors.grey[400]),
            borderRadius: BorderRadius.circular(2),
          ),
          child: isValid
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : textColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
