import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoop/screens/auth/signup/signup_step3_personal_info_screen.dart';
import 'package:hoop/widgets/progress_bar.dart';

class SignupStep2OtpScreen extends StatefulWidget {
  const SignupStep2OtpScreen({super.key});

  @override
  State<SignupStep2OtpScreen> createState() => _SignupStep2OtpScreenState();
}

class _SignupStep2OtpScreenState extends State<SignupStep2OtpScreen> {
  final int totalSteps = 5;
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
        setState(() {
          _remainingSeconds--;
        });
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
    // replace with real verification call...
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupStep3PersonalInfoScreen()),
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress Bar
              SignupProgressBar(currentStep: currentStep, totalSteps: totalSteps),

              // Phone Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Verify Your Phone",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We sent a verification code to",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // OTP Input Fields
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Verification Code",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(otpLength, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: _otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
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
                        fillColor: const Color(0xFF1C1F2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend and Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive code? ",
                    style: TextStyle(color: Colors.grey),
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
                            ? Colors.grey
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
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                  onPressed: verifyOtp,
                  child: const Text(
                    "Verify",
                    style: TextStyle(fontSize: 16),
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
