import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/dtos/podos/tokens/shared_preferences.dart';
import 'package:hoop/dtos/podos/tokens/token_pref.dart';
import 'package:hoop/dtos/requests/FacialVerificationData.dart';
import 'package:hoop/dtos/requests/PersonalInfoData.dart';
import 'package:hoop/dtos/requests/PhoneVerificationData.dart';
import 'package:hoop/dtos/requests/RequestData.dart';
import 'package:hoop/dtos/requests/TwoFactorEnableData.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/AuthResponse.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/main.dart';
import 'package:hoop/services/auth_service.dart';
import 'package:hoop/services/device_manager.dart';

import 'package:hoop/states/OnboardingService.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _needsAccountOnboarding = true;
  bool _needsUserOnboarding = true;
  String? _bvnRequestId;
  List<dynamic>? _banks;

  // Device info
  final DeviceInfoManager _deviceInfoManager = DeviceInfoManager();
  // Session management
  String? _currentSessionId;
  String? _pendingDeviceChangeSessionId;
  final HiveStorageService _storage = HiveStorageService();
  final HiveTokenManager _tokenManager = HiveTokenManager();
  
  // Getter for device ID
  Future<String?> get deviceId async => await _deviceInfoManager.getDeviceId();

  // Initialize services
  Future<void> initializeServices() async {
    try {
      await OnboardingService.init();
      await _storage.init();
      initializeDeviceInfo();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  // Simplified initializeDeviceInfo method
  Future<void> initializeDeviceInfo() async {
    try {
      // DeviceInfoManager handles everything - just call it when needed
      // It will cache the values for performance
      await _deviceInfoManager.getDeviceId(); // Pre-load device ID
      await _deviceInfoManager.getDeviceName(); // Pre-load device name
      await _deviceInfoManager.getDeviceFingerprint(); // Pre-load fingerprint
    } catch (e) {
      print('Error initializing device info: $e');
    }
  }

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get needsAccountOnboarding => _needsAccountOnboarding;
  bool get needsUserOnboarding => _needsUserOnboarding;
  String? get bvnRequestId => _bvnRequestId;
  List<dynamic>? get banks => _banks;

  final AuthHttpService _apiService = AuthHttpService();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // Convenience getters
  String get email => emailController.text.trim();
  String get phoneNumber => phoneController.text.trim();
  String get firstName => firstNameController.text.trim();
  String get lastName => lastNameController.text.trim();
  String get password => passwordController.text;
  String get confirmPassword => confirmPasswordController.text;
  String get otp => otpControllers.map((c) => c.text).join();

  // State flags
  bool acceptTerms = false;
  String? requestId;

  void setAcceptTerms(bool value) {
    acceptTerms = value;
    notifyListeners();
  }

  void setRequestId(String id) {
    requestId = id;
    notifyListeners();
  }

  // Password validation getters
  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get passwordsMatch => password == confirmPassword;

  // Combined validation
  bool get isPasswordValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasNumber &&
      hasSpecialChar &&
      passwordsMatch;

  // Individual requirement checks for UI display
  Map<String, bool> get passwordRequirements => {
    '8+ characters': hasMinLength,
    'Uppercase letter': hasUppercase,
    'Lowercase letter': hasLowercase,
    'Number': hasNumber,
    'Special character': hasSpecialChar,
    'Passwords match': passwordsMatch,
  };

  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      final response = await _apiService.sendEmailVerification(email);

      if (response.success) {
        setRequestId(response.data?['requestId'] ?? '');
        return {
          'success': true,
          'requestId': response.data?['requestId'],
          'message': response.message,
        };
      }
      return {
        'success': false,
        'message': response.error ?? 'Failed to send verification code',
      };
    } catch (error) {
      return {'success': false, 'message': 'Failed to send verification code'};
    }
  }

  Future<bool> register() async {
    try {
      final response = await _apiService.register(
        RegisterData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          otp: otp,
          requestId: requestId ?? '',
          password: password,
        ),
      );

      if (response.success && response.data != null) {
        // Store tokens and user data
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  void clearRegistrationData() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    for (var controller in otpControllers) {
      controller.clear();
    }
    acceptTerms = false;
    requestId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  AuthProvider() {
    _initialize();
  }

  String _isDark = 'light';

  String get isDark => _isDark;

  /// Initialize the appearance from Hive
  Future<void> init() async {
    _isDark = await _storage.getUserAppearance();
    notifyListeners();
  }

  /// Change the theme and save to Hive
  Future<void> setDark(String value) async {
    _isDark = value;
    notifyListeners();
    await _storage.storeUserAppearance(value);
  }

  Future<void> _initialize() async {
    try {
      // Initialize Hive services
      await initializeServices();

      // Load stored onboarding preferences from Hive
      _needsAccountOnboarding = OnboardingService.needsAccountOnboarding;
      _needsUserOnboarding = OnboardingService.needsUserOnboarding;

      // Check if user is already logged in
      await getProfile();

      _isLoading = false; // Make sure to set loading to false
      notifyListeners(); // Notify listeners after initialization
    } catch (e) {
      print('Initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getProfile() async {
    try {
      final isValid = await _apiService.validateSession();
      if (isValid) {
        final response = await _apiService.getProfile();
        if (response.success && response.data != null) {
          _user = response.data;
          // Save user data to Hive
          if (_user != null) {
            await _storage.storeUserData(_user!.toJson());
          }
        }
      }
    } catch (error) {
      print('Auth check failed: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
    String? twoFactorCode,
    String? biometricToken,
    String? otp,
    String? requestId,
    String? sessionId,
  }) async {
    try {
      // Clear storage
      await _storage.clearAll();
      await OnboardingService.clearAll();
      await _deviceInfoManager.clearPersistentData();

      final deviceInfo = await _deviceInfoManager.getDeviceInfoForApi();

      final response = await _apiService.login(
        email: email,
        password: password,
        twoFactorCode: twoFactorCode,
        biometricToken: biometricToken,
        deviceId: deviceInfo['deviceId']!,
        deviceName: deviceInfo['deviceName']!,
        deviceFingerprint: deviceInfo['deviceFingerprint']!,
        otp: otp,
        requestId: requestId,
        sessionId: sessionId,
      );

      await handleLoginResponse(response);

      return response;
    } catch (error) {
      print('Login failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<void> handleLoginResponse(ApiResponse<AuthResponse?> response) async {
    if (response.success && response.data != null) {
      log("Login response: ${response.data?.toJson()}");
      final AuthResponse data = response.data!;

      // Store tokens using Hive Token Manager
      await _tokenManager.saveToken(data.token);
      await _tokenManager.saveUserId(data.data?.id ?? 0);
      
      if (data.expiresIn != null) {
        await _tokenManager.saveTokenExpiry(data.expiresIn!);
      }

      // Store session ID if present
      if (data.sessionId != null) {
        _currentSessionId = data.sessionId;
        await _storage.setString('current_session_id', data.sessionId!);
      }

      // Handle different response statuses
      if (data.operationStatus != OperationStatus.OK) {
        _needsAccountOnboarding = true;
        await OnboardingService.requireAccountOnboarding();
      } else {
        _needsAccountOnboarding = false;
        await OnboardingService.completeAccountOnboarding();
      }

      // Store last login email
      await _storage.setString('last_login_email', email);

      notifyListeners();
    }
  }

  Future<ApiResponse<AuthResponse>> biometricLogin({
    required String email,
    required String biometricToken,
  }) async {
    try {
      final deviceInfo = await _deviceInfoManager.getDeviceInfoForApi();

      final response = await _apiService.biometricLogin(
        email: email,
        biometricToken: biometricToken,
        deviceId: deviceInfo['deviceId']!,
        deviceName: deviceInfo['deviceName'],
        deviceFingerprint: deviceInfo['deviceFingerprint'],
      );

      if (response.success && response.data != null) {
        final AuthResponse data = response.data!;

        await _tokenManager.saveToken(data.token);
        await _tokenManager.saveUserId(data.data?.id ?? 0);
        
        if (data.expiresIn != null) {
          await _tokenManager.saveTokenExpiry(data.expiresIn!);
        }

        // Store session ID if present
        if (data.sessionId != null) {
          _currentSessionId = data.sessionId;
          await _storage.setString('current_session_id', data.sessionId!);
        }

        notifyListeners();
      }

      return response;
    } catch (error) {
      print('Biometric login failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse<AuthResponse>> verifyNewDevice({
    required String email,
    required String otp,
    required String requestId,
    required String sessionId,
  }) async {
    try {
      final deviceInfo = await _deviceInfoManager.getDeviceInfoForApi();
      final response = await _apiService.verifyNewDevice(
        email: email,
        otp: otp,
        requestId: requestId,
        sessionId: sessionId,
        deviceId: deviceInfo['deviceId']!,
        deviceName: deviceInfo['deviceName'],
        deviceFingerprint: deviceInfo['deviceFingerprint'],
      );

      await handleLoginResponse(response);

      return response;
    } catch (error) {
      print('Verify new device failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse<dynamic>> enableBiometric({
    bool enableLogin = false,
    bool enableTransactions = false,
  }) async {
    try {
      final biometricToken = await generateBiometricToken();
      return await _apiService.enableBiometric(
        biometricToken: biometricToken,
        enableLogin: enableLogin,
        enableTransactions: enableTransactions,
      );
    } catch (error) {
      print('Enable biometric failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse<dynamic>> changeDevice({
    required String email,
    required String newDeviceId,
    required String newDeviceName,
  }) async {
    try {
      final response = await _apiService.changeDevice(
        email: email,
        newDeviceId: newDeviceId,
        newDeviceName: newDeviceName,
      );

      if (response.success) {
        _pendingDeviceChangeSessionId = response.data?['sessionId'];
      }

      return response;
    } catch (error) {
      print('Change device failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse<dynamic>> verifyDeviceChange({
    required String email,
    required String requestId,
    required String otp,
    required String sessionId,
  }) async {
    try {
      return await _apiService.verifyDeviceChange(
        email: email,
        requestId: requestId,
        otp: otp,
        sessionId: sessionId,
      );
    } catch (error) {
      print('Verify device change failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  // Generate biometric token
  Future<String> generateBiometricToken() async {
    final deviceInfo = await _deviceInfoManager.getDeviceInfoForApi();

    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    return '${deviceInfo['deviceFingerprint']}:${deviceInfo['deviceId']!}:${deviceInfo['deviceName']}:$timestamp:${_generateSignature(deviceInfo['deviceId']!, timestamp)}';
  }

  String _generateSignature(String deviceId, int timestamp) {
    final data = '$deviceId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if biometric login should be offered
  Future<bool> shouldOfferBiometricLogin(String email) async {
    try {
      // Check if user has biometric login enabled from backend
      final user = _user;
      if (user?.biometricLoginEnabled == true) {
        return true;
      }

      // Check local preferences from Hive
      final biometricEnabled = await _storage.getBool('biometric_enabled_$email') ?? false;
      final lastLoginEmail = await _storage.getString('last_login_email');

      return biometricEnabled && lastLoginEmail == email;
    } catch (e) {
      print('Error checking biometric offer: $e');
      return false;
    }
  }

  // Save biometric credentials locally
  Future<void> saveBiometricCredentials(String email, bool enabled) async {
    try {
      await _storage.setBool('biometric_enabled_$email', enabled);
      await _storage.setString('biometric_email', email);
    } catch (e) {
      print('Error saving biometric credentials: $e');
    }
  }

  // Clear biometric credentials
  Future<void> clearBiometricCredentials(String email) async {
    try {
      await _storage.remove('biometric_enabled_$email');
      await _storage.remove('biometric_email');
      await _storage.remove('biometric_password');
    } catch (e) {
      print('Error clearing biometric credentials: $e');
    }
  }

  // Get saved biometric credentials
  Future<String?> getBiometricCredentials() async {
    try {
      return await _storage.getString('biometric_email');
    } catch (e) {
      print('Error getting biometric credentials: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      // Clear all Hive storage
      await _storage.clearAll();
      await _tokenManager.clearAllTokens();
      await OnboardingService.clearAll();
      await _deviceInfoManager.clearPersistentData();

      // Clear local state
      _user = null;
      _needsAccountOnboarding = true;
      _needsUserOnboarding = true;
      _bvnRequestId = null;
      _banks = null;
      _currentSessionId = null;
      _pendingDeviceChangeSessionId = null;

      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.updateProfile(updates);
      if (response.success) {
        getProfile();
      }
      return response;
    } catch (error) {
      print('Profile update failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> setPin(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.setTransactionPin(updates);
      if (response.success) {
        getProfile();
      }
      return response;
    } catch (error) {
      print('Profile update failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> updatePin(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.updateTransactionPin(updates);
      if (response.success) {
        getProfile();
      }
      return response;
    } catch (error) {
      print('Profile update failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> sendFacialVerification(
    String imageData,
    String fileName,
  ) async {
    try {
      final response = await _apiService.sendFacialVerification(
        imageData,
        fileName,
      );
      // Show success message
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Profile verified!')),
      );
      return response;
    } catch (error) {
      print('Send facial verification failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> loadBanks() async {
    try {
      final response = await _apiService.loadBanks();
      if (response.success && response.data != null) {
        _banks = response.data as List<dynamic>;
        notifyListeners();
      }
      return response;
    } catch (error) {
      print('Load banks failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> verifyAccount(
    String bankCode,
    String accountNumber,
  ) async {
    try {
      final response = await _apiService.verifyAccount(bankCode, accountNumber);
      return response;
    } catch (error) {
      print('Verify account failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> registerUserPrimaryAccount(
    String bankCode,
    String accountNumber,
    String accountName,
  ) async {
    try {
      final response = await _apiService.registerUserPrimaryAccount(
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountName: accountName,
      );
      return response;
    } catch (error) {
      print('Register primary account failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  // Login-specific methods
  Future<bool> sendPhoneVerification(String phone) async {
    try {
      final response = await _apiService.sendPhoneVerification(phone);
      return response.success;
    } catch (error) {
      print('Send phone verification failed: $error');
      return false;
    }
  }

  Future<bool> verifyPhone(String phone, String code) async {
    try {
      final response = await _apiService.verifyPhone(
        PhoneVerificationData(phone: phone, code: code),
      );
      return response.success && (response.data?['verified'] == true);
    } catch (error) {
      print('Phone verification failed: $error');
      return false;
    }
  }

  Future<bool> verifyFacial(String selfieImage, String idImage) async {
    try {
      final response = await _apiService.verifyFacial(
        FacialVerificationData(selfieImage: selfieImage, idImage: idImage),
      );
      return response.success && (response.data?['verified'] == true);
    } catch (error) {
      print('Facial verification failed: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>?> enableTwoFactor() async {
    try {
      final response = await _apiService.enableTwoFactor();
      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (error) {
      print('Enable 2FA failed: $error');
      return null;
    }
  }

  Future<bool> verifyTwoFactor(String code) async {
    try {
      final response = await _apiService.verifyTwoFactor(code);
      return response.success && (response.data?['valid'] == true);
    } catch (error) {
      print('2FA verification failed: $error');
      return false;
    }
  }

  Future<ApiResponse> changePassword(
    String currentPassword,
    String password,
    String confirmationPassword,
  ) async {
    try {
      final response = await _apiService.changePassword(
        ChangePasswordData(
          currentPassword: currentPassword,
          password: password,
          confirmationPassword: confirmationPassword,
        ),
      );
      return response;
    } catch (error) {
      print('Change password failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      return response;
    } catch (error) {
      print('Forgot password failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> verifyPasswordResetToken(
    String token,
    String email,
  ) async {
    try {
      final response = await _apiService.verifyPasswordResetToken(
        VerifyResetTokenData(otp: token, email: email),
      );
      return response;
    } catch (error) {
      print('Verify password reset token failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse> resetPassword(
    String verificationId,
    String requestId,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.resetPassword(
        ResetPasswordData(
          newPassword: newPassword,
          verificationId: verificationId,
          requestId: requestId,
        ),
      );
      return response;
    } catch (error) {
      print('Reset password failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<bool> completePersonalInfo(PersonalInfoData data) async {
    try {
      final response = await _apiService.completePersonalInfo(data);
      if (response.success) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(
              response.message ??
                  'Personal information completed successfully!',
            ),
          ),
        );
        return true;
      }
      return false;
    } catch (error) {
      print('Complete personal info failed: $error');
      return false;
    }
  }

  Future<bool> validateBvn(String bvn, String dateOfBirth) async {
    try {
      final response = await _apiService.validateBvn(
        ValidateBvnData(bvn: bvn, dateOfBirth: dateOfBirth),
      );
      if (response.success && response.data?['requestId'] != null) {
        _bvnRequestId = response.data!['requestId'];
        notifyListeners();
        return true;
      }

      // Show error message
      if (response.message != null) {
        ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        ).showSnackBar(SnackBar(content: Text(response.message!)));
      }
      return false;
    } catch (error) {
      print('Validate BVN failed: $error');
      ScaffoldMessenger.of(
        navigatorKey.currentContext!,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return false;
    }
  }

  Future<ApiResponse> createFacialSession() async {
    try {
      final response = await _apiService.createSession();
      return response;
    } catch (error) {
      print('Create facial session failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await _apiService.refreshToken();
      return response.success;
    } catch (error) {
      print('Token refresh failed: $error');
      return false;
    }
  }

  void setNeedsAccountOnboarding(bool needs) async {
    _needsAccountOnboarding = needs;
    if (needs) {
      await OnboardingService.requireAccountOnboarding();
    } else {
      await OnboardingService.completeAccountOnboarding();
    }
    notifyListeners();
  }

  void setNeedsUserOnboarding(bool needs) async {
    print('setNeedsUserOnboarding called with: $needs');
    _needsUserOnboarding = needs;
    if (needs) {
      await OnboardingService.requireUserOnboarding();
    } else {
      await OnboardingService.completeUserOnboarding();
    }
    print('Saved to Hive: needsUserOnboarding = $needs');
    notifyListeners();
  }
}