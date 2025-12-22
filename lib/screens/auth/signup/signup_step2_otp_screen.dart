import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/signup/signup_step3_personal_info_screen.dart';
import 'package:hoop/widgets/progress_bar.dart';

class SignupStep2OtpScreen extends StatefulWidget {
  final String email;
  const SignupStep2OtpScreen({super.key, required this.email});

  @override
  State<SignupStep2OtpScreen> createState() => _SignupStep2OtpScreenState();
}

class _SignupStep2OtpScreenState extends State<SignupStep2OtpScreen> {
  final int totalSteps = 4;
  final int currentStep = 2;
  final int otpLength = 6;
  final List<TextEditingController> _otpControllers = [];
  Timer? _timer;
  int _remainingSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < otpLength; i++) {
      _otpControllers.add(TextEditingController());
    }
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void verifyOtp() {
    String code = _otpControllers.map((c) => c.text).join();
    if (code.length == otpLength) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SignupStep3PersonalInfoScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit code")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors based on theme
    final backgroundColor = isDark ? const Color(0xFF0C0E1A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1C1F2E) : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey : Colors.black54;
    final borderColor = isDark ? Colors.white70 : Colors.black45;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SignupProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Verify Your Email Address",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We sent a verification code to",
                style: TextStyle(color: hintColor, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Verification Code",
                  style: TextStyle(color: hintColor),
                ),
              ),
              const SizedBox(height: 12),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(otpLength, (index) {
                  return SizedBox(
                    width: 48,
                    height: 58,
                    child: TextField(
                      controller: _otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(color: textColor, fontSize: 18),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < otpLength - 1) {
                          FocusScope.of(context).nextFocus();
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: cardColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(color: hintColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_remainingSeconds <= 0) {
                        setState(() {
                          _remainingSeconds = 300;
                          startTimer();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Code resent!")),
                        );
                      }
                    },
                    child: Text(
                      "Resend",
                      style: TextStyle(
                        color: _remainingSeconds > 0
                            ? hintColor
                            : Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Code expires in $formattedTime",
                style: TextStyle(color: hintColor, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Gradient Verify Button
              GestureDetector(
                onTap: verifyOtp,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0a1866), // Darker blue
                        Color(0xFF1347cd), // to-blue-600
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
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
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Verify →",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
