import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/screens/auth/login_otp_screen.dart';
import 'package:hoop/screens/auth/password_reset/password_reset_screen.dart';
import 'package:hoop/screens/auth/signup/ignup_step1_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/progress_bar.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/AuthResponse.dart';
import 'package:hoop/screens/auth/signup/signup_step3_personal_info_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:hoop/utils/helpers/toasters/SnackBar.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Biometric authentication
  final LocalAuthentication _localAuth = LocalAuthentication();

  // State variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnrolled = false;

  // Login flow state
  bool _is2FARequired = false;
  bool _isDeviceVerificationRequired = false;
  String? _currentRequestId;
  String? _currentSessionId;
  String? _errorMessage;

  // 2FA/OTP fields
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifyingOTP = false;

  @override
  void initState() {
    super.initState();
    _initializeDeviceInfo();
    _checkBiometrics();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initializeDeviceInfo() async {
    final authService = Provider.of<AuthProvider>(context, listen: false);
    await authService.initializeDeviceInfo();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        setState(() => _biometricAvailable = false);
        return;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _biometricAvailable =
            canCheckBiometrics && availableBiometrics.isNotEmpty;
      });
    } catch (error) {
      setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);
      final credentials = await authService.getBiometricCredentials();

      if (credentials != null) {
        _emailController.text = credentials;
      }

      _biometricEnrolled = await authService.shouldOfferBiometricLogin(
        credentials ?? '',
      );
      if (mounted) setState(() {});
    } catch (error) {
      print("Error loading saved credentials: $error");
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);

      final response = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        otp: _otpController.text.isNotEmpty ? _otpController.text : null,
        requestId: _currentRequestId,
        sessionId: _currentSessionId,
      );

      if (!response.success) {
        _handleLoginError(response);
        return;
      }

      if (response.data != null) {
        await _handleLoginResponse(response.data!);
      }
    } catch (error) {
      _handleLoginError(error);
    }
  }

  Future<void> _handleLoginResponse(AuthResponse response) async {
    // Check for special status codes
    if (response.needs2FA) {
      context.showInfoSnackBar('OTP sent to your email for 2FA verification');
      return;
    }

    if (response.needsDeviceVerification) {
      setState(() {
        _isDeviceVerificationRequired = true;
        _currentRequestId = response.requestId;
        _currentSessionId = response.sessionId;
        _isLoading = false;
      });

      context.showInfoSnackBar('OTP sent to verify this new device');
    }
    if (response.needsDeviceVerification || response.needs2FA) {
      Navigator.pushNamed(
        context,
        '/login/otp',
        arguments: {
          "email": _emailController.text,
          "is2FARequired": response.needs2FA,
          "password": _passwordController.text,
          "isDeviceVerificationRequired": response.needsDeviceVerification,
          "requestId": response.requestId,
          "sessionId": response.sessionId,
        },
      );
      return;
    }

    // Handle navigation based on operation status
    _handleNavigation(response.operationStatus);
  }

  void _handleLoginError(dynamic error) {
    String errorMessage = 'Login failed';

    if (error is ApiResponse) {
      errorMessage = error.error ?? error.message ?? 'Login failed';
    } else if (error is String) {
      errorMessage = error;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }

    setState(() {
      _errorMessage = errorMessage;
      _isLoading = false;
      _isVerifyingOTP = false;
    });

    context.showErrorSnackBar(errorMessage);
  }

  Future<void> _performBiometricLogin() async {
    if (!_biometricAvailable) {
      context.showErrorSnackBar('Biometric authentication not available');
      return;
    }

    setState(() => _isBiometricLoading = true);

    try {
      // Get saved credentials
      final authService = Provider.of<AuthProvider>(context, listen: false);
      final credentials = await authService.getBiometricCredentials();

      if (credentials == null) {
        setState(() => _isBiometricLoading = false);
        context.showErrorSnackBar('No saved credentials found');
        return;
      }

      // Authenticate with biometrics
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to login to Hoop',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );

      if (!didAuthenticate) {
        setState(() => _isBiometricLoading = false);
        return;
      }

      // Generate biometric token
      final biometricToken = await authService.generateBiometricToken();

      // Perform biometric login
      final response = await authService.biometricLogin(
        email: credentials,
        biometricToken: biometricToken,
      );

      if (!response.success) {
        _handleLoginError(response);
        return;
      }

      if (response.data != null) {
        _handleNavigation(response.data!.operationStatus);
      }
    } catch (error) {
      _handleLoginError(error);
      setState(() => _isBiometricLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      context.showErrorSnackBar('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isVerifyingOTP = true);

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);

      AuthResponse? response;

      if (_isDeviceVerificationRequired) {
        final apiResponse = await authService.verifyNewDevice(
          email: _emailController.text.trim(),
          otp: _otpController.text,
          requestId: _currentRequestId!,
          sessionId: _currentSessionId!,
        );

        if (apiResponse.success) {
          response = apiResponse.data;
        } else {
          _handleLoginError(apiResponse);
          return;
        }
      } else {
        // Regular login with OTP
        final apiResponse = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          otp: _otpController.text,
          requestId: _currentRequestId,
        );

        if (apiResponse.success) {
          response = apiResponse.data;
        } else {
          _handleLoginError(apiResponse);
          return;
        }
      }

      if (response != null) {
        await _handleLoginResponse(response);
      }
    } catch (error) {
      _handleLoginError(error);
    }
  }

  void _handleNavigation(OperationStatus status) {
    setState(() {
      _isLoading = false;
      _isBiometricLoading = false;
      _isVerifyingOTP = false;
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



  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isBiometricLoading ? null : _performBiometricLogin,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: _isBiometricLoading
              ? CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.fingerprint,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0E1A) : Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SignupProgressBar(currentStep: 1, totalSteps: 1),
                const SizedBox(height: 12),

                // 🔒 Lock Icon
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

                // Title
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to your Hoop account",
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
                if (_errorMessage != null) const SizedBox(height: 16),

              

                  Column(
                    children: [
                      // 📧 Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Email",
                          style: TextStyle(
                            color: isDark ? Colors.grey : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      HoopInput(
                        controller: _emailController,
                        hintText: 'Email',
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      // 🔑 Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Password",
                          style: TextStyle(
                            color: isDark ? Colors.grey : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      HoopPasswordInput(
                        controller: _passwordController,
                        hintText: 'Password',
                        validator: (value) =>
                            Validators.password(value, minLength: 6),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PasswordResetScreen(
                                  initialEmail: _emailController.text,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button and Biometric Button Row
                      Row(
                        children: [
                          Expanded(
                            child: HoopButton(
                              buttonText: "Sign In →",
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                          ),
                          if (_biometricAvailable && _biometricEnrolled)
                            const SizedBox(width: 16),

                          if (_biometricAvailable && _biometricEnrolled)
                            _buildBiometricButton(),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey[700],
                      ),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignupStep1Screen(),
                                ),
                              );
                            },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: _isLoading ? Colors.grey : Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
