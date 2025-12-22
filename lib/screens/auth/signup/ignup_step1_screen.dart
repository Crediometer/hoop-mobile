import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/signup/signup_step2_otp_screen.dart';
import 'package:hoop/widgets/progress_bar.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  bool agreeToTerms = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void goToNextStep() {
    if (_formKey.currentState!.validate() && agreeToTerms) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SignupStep2OtpScreen(email: emailController.text.trim()),
        ),
      );
    } else if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms and Privacy Policy'),
        ),
      );
    }
  }

  bool get hasMinLength => passwordController.text.length >= 8;
  bool get hasUppercase => passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => passwordController.text.contains(RegExp(r'[a-z]'));
  bool get hasNumber => passwordController.text.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar =>
      passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  InputDecoration _inputDecoration(
    String hint,
    Color fillColor,
    Color hintColor,
    Color borderColor,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fillColor,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors that adapt to system mode
    final backgroundColor = isDark ? const Color(0xFF0C0E1A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1C1F2E) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey : Colors.black54;
    final borderColor = isDark ? Colors.white70 : Colors.black45;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Back Arrow Button
              const SignupProgressBar(currentStep: 1, totalSteps: 6),
              const SizedBox(height: 24),
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
                    _buildLabel("First Name", textColor),
                    TextFormField(
                      controller: firstNameController,
                      decoration: _inputDecoration(
                        "John",
                        cardColor,
                        hintColor,
                        borderColor,
                      ),
                      validator: (value) => value!.isEmpty
                          ? "Please enter your first name"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Last Name", textColor),
                    TextFormField(
                      controller: lastNameController,
                      decoration: _inputDecoration(
                        "Doe",
                        cardColor,
                        hintColor,
                        borderColor,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Please enter your last name" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Email Address", textColor),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        "john@example.com",
                        cardColor,
                        hintColor,
                        borderColor,
                      ),
                      validator: (value) => value!.isEmpty
                          ? "Please enter your email"
                          : (!value.contains("@")
                                ? "Enter a valid email"
                                : null),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Phone Number", textColor),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        "+234 800 000 0000",
                        cardColor,
                        hintColor,
                        borderColor,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter your phone number" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Password", textColor),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      onChanged: (value) => setState(() {}),
                      decoration:
                          _inputDecoration(
                            "Create a strong password",
                            cardColor,
                            hintColor,
                            borderColor,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: hintColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        }
                        if (!hasMinLength) {
                          return "Password must be at least 8 characters";
                        }
                        if (!hasUppercase) {
                          return "Password must contain uppercase letter";
                        }
                        if (!hasLowercase) {
                          return "Password must contain lowercase letter";
                        }
                        if (!hasNumber) {
                          return "Password must contain a number";
                        }
                        if (!hasSpecialChar) {
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

                    if (passwordController.text.isNotEmpty)
                      _buildPasswordStrength(isDark, cardColor, textColor),
                    const SizedBox(height: 16),

                    _buildLabel("Confirm Password", textColor),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration:
                          _inputDecoration(
                            "Confirm your password",
                            cardColor,
                            hintColor,
                            borderColor,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: hintColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible;
                                });
                              },
                            ),
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

                    Row(
                      children: [
                        Checkbox(
                          value: agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              agreeToTerms = value ?? false;
                            });
                          },
                          activeColor: Colors.blueAccent,
                        ),
                        Flexible(
                          child: Wrap(
                            children: [
                              Text(
                                "I agree to the ",
                                style: TextStyle(color: textColor),
                              ),
                              const Text(
                                "Terms of Service",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                              Text(" and ", style: TextStyle(color: textColor)),
                              const Text(
                                "Privacy Policy",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Gradient button
                    GestureDetector(
                      onTap: agreeToTerms ? goToNextStep : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: agreeToTerms
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF0a1866),
                                    Color(0xFF1347cd),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey[300]!,
                                    isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey[300]!,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: agreeToTerms
                              ? [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: -4,
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Send Verification Code →",
                          style: TextStyle(
                            color: agreeToTerms
                                ? Colors.white
                                : textColor.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildPasswordStrength(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
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
