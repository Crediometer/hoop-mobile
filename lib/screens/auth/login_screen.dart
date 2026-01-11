import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/components/inputs/input.dart';
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/AuthResponse.dart';
import 'package:hoop/screens/auth/signup/ignup_step1_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step3_personal_info_screen.dart';
import 'package:hoop/screens/auth/signup/signup_step4_facial_verification_screen.dart';
import 'package:hoop/screens/features/home_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:hoop/utils/forms/validators.dart';
import 'package:hoop/utils/helpers/toasters/snackbar.dart';
import 'package:hoop/widgets/progress_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isPasswordVisible = false;
  bool isLoading = false;
  bool isBiometricLoading = false;
  bool biometricAvailable = false;
  bool biometricEnrolled = false;
  
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initializeDeviceInfo();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        setState(() => biometricAvailable = false);
        return;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        biometricAvailable = canCheckBiometrics && availableBiometrics.isNotEmpty;
        biometricEnrolled = availableBiometrics.isNotEmpty;
      });
    } catch (error) {
      print("Biometric check error: $error");
      setState(() => biometricAvailable = false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final credentials = await authProvider.getBiometricCredentials();
      
      if (credentials != null) {
        _emailController.text = credentials['email'] ?? '';
        // Don't auto-fill password for security
      }
    } catch (error) {
      print("Error loading saved credentials: $error");
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.login(
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
      setState(() {
        _is2FARequired = true;
        _currentRequestId = response.requestId;
        isLoading = false;
      });
      
      context.showInfoSnackBar('OTP sent to your email for 2FA verification');
      return;
    }
    
    if (response.needsDeviceVerification) {
      setState(() {
        _isDeviceVerificationRequired = true;
        _currentRequestId = response.requestId;
        _currentSessionId = response.sessionId;
        isLoading = false;
      });
      
      context.showInfoSnackBar('OTP sent to verify this new device');
      return;
    }
    
    // Save credentials for biometric if user wants
    if (response.data?.biometricLoginEnabled == true && biometricAvailable) {
      await _promptBiometricSave();
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
      isLoading = false;
      _isVerifyingOTP = false;
    });
    
    context.showErrorSnackBar(errorMessage);
  }

  Future<void> _performBiometricLogin() async {
    if (!biometricAvailable) {
      context.showErrorSnackBar('Biometric authentication not available');
      return;
    }

    setState(() => isBiometricLoading = true);

    try {
      // Get saved credentials
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final credentials = await authProvider.getBiometricCredentials();
      
      if (credentials == null) {
        setState(() => isBiometricLoading = false);
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
        setState(() => isBiometricLoading = false);
        return;
      }

      // Generate biometric token
      final biometricToken = await authProvider.generateBiometricToken();
      
      // Perform biometric login
      final response = await authProvider.biometricLogin(
        email: credentials['email']!,
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
      setState(() => isBiometricLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      context.showErrorSnackBar('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isVerifyingOTP = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      AuthResponse? response;
      
      if (_isDeviceVerificationRequired) {
        response = (await authProvider.verifyNewDevice(
          email: _emailController.text.trim(),
          otp: _otpController.text,
          requestId: _currentRequestId!,
          sessionId: _currentSessionId!,
        )).data;
      } else {
        // Regular login with OTP
        response = (await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          otp: _otpController.text,
          requestId: _currentRequestId,
        )).data;
      }

      if (response != null) {
        await _handleLoginResponse(response);
      }
    } catch (error) {
      _handleLoginError(error);
    }
  }

  Future<void> _promptBiometricSave() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Login?'),
        content: const Text(
          'Would you like to enable biometric login for faster access on this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.saveBiometricCredentials(
        _emailController.text.trim(),
        _passwordController.text,
      );
      context.showSuccessSnackBar('Biometric login enabled');
    }
  }

  void _handleNavigation(OperationStatus status) {
    setState(() {
      isLoading = false;
      isBiometricLoading = false;
      _isVerifyingOTP = false;
    });

    if (!mounted) return;

    switch (status) {
      case OperationStatus.OK:
      case OperationStatus.TEMPORARY_REDIRECT:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (_) => false,
        );
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

  void _resetLoginFlow() {
    setState(() {
      _is2FARequired = false;
      _isDeviceVerificationRequired = false;
      _otpController.clear();
      _currentRequestId = null;
      _currentSessionId = null;
    });
  }

  Widget _buildOTPInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isDeviceVerificationRequired 
            ? 'Enter OTP sent to verify this device'
            : 'Enter 2FA OTP',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        HoopInput(
          controller: _otpController,
          hintText: 'Enter 6-digit OTP',
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (value) {
            if (value.length == 6) {
              _verifyOTP();
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetLoginFlow,
                child: const Text('Back to Login'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HoopButton(
                buttonText: 'Verify OTP',
                isLoading: _isVerifyingOTP,
                onPressed: _verifyOTP,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: isBiometricLoading ? null : _performBiometricLogin,
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
          child: isBiometricLoading
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0C0E1A) : Colors.grey[100],
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
                    color: isDarkMode ? const Color(0xFF1C1F2E) : Colors.white,
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
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to your Hoop account",
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey : Colors.grey[700],
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
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // Show OTP input if required
                if (_is2FARequired || _isDeviceVerificationRequired)
                  _buildOTPInput()
                else
                  Column(
                    children: [
                      // 📧 Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Email",
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey : Colors.grey[700],
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
                            color: isDarkMode ? Colors.grey : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      HoopInput(
                        controller: _passwordController,
                        hintText: 'Password',
                        obscureText: !isPasswordVisible,
                        validator: (value) =>
                            Validators.password(value, minLength: 6),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: isDarkMode ? Colors.grey : Colors.grey[700],
                          ),
                          onPressed: () => setState(
                              () => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to forgot password screen
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
                              isLoading: isLoading,
                              onPressed: _login,
                            ),
                          ),
                          const SizedBox(width: 16),

                          if (biometricAvailable) _buildBiometricButton(),
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
                        color: isDarkMode ? Colors.grey : Colors.grey[700],
                      ),
                    ),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupStep1Screen(),
                                ),
                              );
                            },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: isLoading
                              ? Colors.grey
                              : Colors.blueAccent,
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