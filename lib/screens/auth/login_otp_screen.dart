import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/otp.dart';
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/AuthResponse.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/screens/auth/signup/signup_step3_personal_info_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/helpers/formatters/hoop_formatter.dart';
import 'package:hoop/utils/helpers/toasters/SnackBar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class LoginOtpScreen extends StatefulWidget {
  final String email;
  final String? password;
  final bool is2FARequired;
  final bool isDeviceVerificationRequired;
  final String? requestId;
  final String? sessionId;

  const LoginOtpScreen({
    super.key,
    required this.email,
    this.password,
    this.is2FARequired = false,
    this.isDeviceVerificationRequired = false,
    this.requestId,
    this.sessionId,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifying = false;
  int _resendCooldown = 0;
  String? _errorMessage;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);

      if (widget.isDeviceVerificationRequired) {
        final response = await authService.verifyNewDevice(
          email: widget.email,
          otp: _otpController.text,
          requestId: widget.requestId!,
          sessionId: widget.sessionId!,
        );

        if (!response.success) {
          _handleError(response);
          return;
        }

        if (response.data != null) {
          _handleSuccess(response.data!.data!);
        }
      } else {
        final response = await authService.login(
          email: widget.email,
          password: widget.password ?? '',
          otp: _otpController.text,
          requestId: widget.requestId,
        );

        if (!response.success) {
          _handleError(response);
          return;
        }

        if (response.data != null) {
          await _handleLoginResponse(response.data!);
        }
      }
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleLoginResponse(AuthResponse response) async {
    if (response.needs2FA || response.needsDeviceVerification) {
      setState(() {
        _errorMessage = 'Additional verification required';
        _isLoading = false;
      });
      return;
    }

    _handleNavigation(response.operationStatus);
  }

  void _handleSuccess(User user) {
    setState(() {
      _isLoading = false;
    });

    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  void _handleError(dynamic error) {
    String errorMessage = 'Verification failed';

    if (error is ApiResponse) {
      errorMessage = error.error ?? error.message ?? 'Verification failed';
    } else if (error is String) {
      errorMessage = error;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }

    setState(() {
      _errorMessage = errorMessage;
      _isLoading = false;
    });

    context.showErrorSnackBar(errorMessage);
  }

  void _handleNavigation(OperationStatus status) {
    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    switch (status) {
      case OperationStatus.OK:
      case OperationStatus.TEMPORARY_REDIRECT:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        break;
      case OperationStatus.MOVED_PERMANENTLY:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignupStep3PersonalInfoScreen(),
          ),
        );
        break;
      case OperationStatus.FOUND:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignupStep4FacialVerificationScreen(),
          ),
        );
        break;
      default:
        context.showErrorSnackBar('Unknown operation status: $status');
        break;
    }
  }

  Future<void> _handleResendOTP() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);
      final response = await authService.login(
        email: widget.email,
        password: widget.password ?? '',
        requestId: widget.requestId,
      );

      if (response.success) {
        _startCooldown();
        context.showSuccessSnackBar('New OTP sent to your email');
      } else {
        _handleError(response);
      }
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: isDark ? const Color(0xFF0C0E1A) : Colors.grey[100],
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1F2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phonelink_lock_outlined,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                widget.isDeviceVerificationRequired
                    ? "Verify New Device"
                    : "Two-Factor Authentication",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey[700],
                    fontSize: 14,
                  ),

                  children: [
                    TextSpan(
                      text: widget.isDeviceVerificationRequired
                          ? 'Enter OTP sent to verify this device\n'
                          : 'Enter 2FA OTP sent to\n',
                    ),
                    TextSpan(
                      text: HoopFormatters.maskEmail(widget.email),
                      
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
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

              // OTP Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Verification Code",
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HoopOtpInput(
                    length: 6,
                    controller: _otpController,
                    onChanged: (value) {
                      if (value.length == 6 && !_isVerifying) {
                        _handleVerifyOTP();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Resend code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          color: isDark ? Colors.grey : Colors.grey[700],
                        ),
                      ),
                      TextButton(
                        onPressed: _resendCooldown > 0 || _isLoading
                            ? null
                            : _handleResendOTP,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code expires in 10 minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verify Button
                  HoopButton(
                    buttonText: "Verify OTP",
                    isLoading: _isLoading,
                    onPressed: _otpController.text.length == 6
                        ? _handleVerifyOTP
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
