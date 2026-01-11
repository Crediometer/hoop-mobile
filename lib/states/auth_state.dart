import 'dart:convert';
import 'dart:developer';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/dtos/podos/tokens/shared_preferences.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _needsAccountOnboarding = true;
  bool _needsUserOnboarding = true;
  String? _bvnRequestId;
  List<dynamic>? _banks;

  // Device info
  String? _deviceId;
  String? _deviceName;
  String? _deviceFingerprint;

  // Session management
  String? _currentSessionId;
  String? _pendingDeviceChangeSessionId;

  // Getter for device ID
  String? get deviceId => _deviceId;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get needsAccountOnboarding => _needsAccountOnboarding;
  bool get needsUserOnboarding => _needsUserOnboarding;
  String? get bvnRequestId => _bvnRequestId;
  List<dynamic>? get banks => _banks;

  final AuthHttpService _apiService = AuthHttpService();

  AuthProvider() {
    _initialize();
  }

  String _isDark = 'light';

  String get isDark => _isDark;

  /// Initialize the appearance from SharedPreferences and fallback to system theme
  Future<void> init() async {
    _isDark = await StorageService().getUserAppearance();

    // if (appearance == 0) {
    //   // Use system brightness
    //   _isDark = Theme.of(context).brightness == Brightness.dark;
    // } else {
    //   // 1 = light, 2 = dark? adjust based on your logic
    //   _isDark = appearance != 1;
    // }

    notifyListeners();
  }

  /// Change the theme and optionally save to SharedPreferences
  Future<void> setDark(String value) async {
    _isDark = value;
    notifyListeners();
    await StorageService().storeUserAppearance(
      value.toString(),
    ); // 1=light, 2=dark
  }

  Future<void> _initialize() async {
    try {
      // Load stored onboarding preference
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('needsAccountOnboarding');

      if (stored != null) {
        _needsAccountOnboarding = stored == 'true';
      } else {
        _needsAccountOnboarding = true;
        await prefs.setString('needsAccountOnboarding', 'true');
      }
      final userOnbaording = prefs.getString('needsUserOnboarding');
      final delay = Duration(milliseconds: 500);
      Timer(delay, () async {
        if (userOnbaording != null) {
          _needsUserOnboarding = userOnbaording == 'true';
        } else {
          _needsUserOnboarding = true;
          await prefs.setString('needsUserOnboarding', 'true');
        }
      });

      // Check if user is already logged in
      await getProfile();
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

          // here get users details and save to shared_pref
        }
      }
    } catch (error) {
      print('Auth check failed: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize device info
  Future<void> initializeDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_id');

      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await prefs.setString('device_id', _deviceId!);
      }

      // Get device info
      final deviceInfo = await DeviceInfoPlugin().deviceInfo;
      _deviceName = _getDeviceName(deviceInfo);
      _deviceFingerprint = await _generateDeviceFingerprint(deviceInfo);
    } catch (e) {
      print('Error initializing device info: $e');
      _deviceId = const Uuid().v4();
    }
  }

  String _getDeviceName(BaseDeviceInfo deviceInfo) {
    if (deviceInfo is AndroidDeviceInfo) {
      return '${deviceInfo.manufacturer} ${deviceInfo.model}';
    } else if (deviceInfo is IosDeviceInfo) {
      return 'iPhone ${deviceInfo.model}';
    } else if (deviceInfo is WebBrowserInfo) {
      return '${deviceInfo.browserName.name} on ${deviceInfo.platform}';
    }
    return 'Unknown Device';
  }

  Future<String> _generateDeviceFingerprint(BaseDeviceInfo deviceInfo) async {
    final info = <String, dynamic>{};

    if (deviceInfo is AndroidDeviceInfo) {
      info['manufacturer'] = deviceInfo.manufacturer;
      info['model'] = deviceInfo.model;
      info['brand'] = deviceInfo.brand;
      info['device'] = deviceInfo.device;
      info['board'] = deviceInfo.board;
      info['hardware'] = deviceInfo.hardware;
    } else if (deviceInfo is IosDeviceInfo) {
      info['model'] = deviceInfo.model;
      info['name'] = deviceInfo.name;
      info['systemName'] = deviceInfo.systemName;
      info['systemVersion'] = deviceInfo.systemVersion;
    }

    // Add app version
    final packageInfo = await PackageInfo.fromPlatform();
    info['appVersion'] = packageInfo.version;
    info['buildNumber'] = packageInfo.buildNumber;

    // Hash the info
    final jsonString = jsonEncode(info);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
    String? twoFactorCode,
    String? biometricToken,
    String? deviceId,
    String? deviceName,
    String? deviceFingerprint,
    String? otp,
    String? requestId,
    String? sessionId,
  }) async {
    try {
      // Clear storage
      final prefs = await SharedPreferences.getInstance();
      final joinIntent = prefs.getString('joinIntent');

      await prefs.clear();
      if (joinIntent != null) {
        await prefs.setString('joinIntent', joinIntent);
      }

      // Use provided device info or default
      final loginDeviceId = deviceId ?? _deviceId ?? const Uuid().v4();
      final loginDeviceName = deviceName ?? _deviceName ?? 'Mobile Device';
      final loginDeviceFingerprint = deviceFingerprint ?? _deviceFingerprint;

      final response = await _apiService.login(
        email: email,
        password: password,
        twoFactorCode: twoFactorCode,
        biometricToken: biometricToken,
        deviceId: loginDeviceId,
        deviceName: loginDeviceName,
        deviceFingerprint: loginDeviceFingerprint,
        otp: otp,
        requestId: requestId,
        sessionId: sessionId,
      );

      if (response.success && response.data != null) {
        log("Login response: ${response.data?.toJson()}");
        final AuthResponse data = response.data!;

        // Store tokens
        await _apiService.storeTokens(
          token: data.token,
          refreshToken: "",
          expiresIn: data.expiresIn ?? 0,
          userId: data.data?.id ?? 0,
        );

        // Store session ID if present
        if (data.sessionId != null) {
          _currentSessionId = data.sessionId;
          await prefs.setString('current_session_id', data.sessionId!);
        }

        // Handle different response statuses
        if (data.operationStatus == OperationStatus.TEMPORARY_REDIRECT) {
          _needsAccountOnboarding = true;
          await prefs.setString('needsAccountOnboarding', 'true');
        } else {
          _needsAccountOnboarding = false;
          await prefs.setString('needsAccountOnboarding', 'false');
        }

        // Store last login email
        await prefs.setString('last_login_email', email);

        notifyListeners();
      }

      return response;
    } catch (error) {
      print('Login failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse<AuthResponse>> biometricLogin({
    required String email,
    required String biometricToken,
  }) async {
    try {
      // Ensure device info is initialized
      if (_deviceId == null) {
        await initializeDeviceInfo();
      }

      final response = await _apiService.biometricLogin(
        email: email,
        biometricToken: biometricToken,
        deviceId: _deviceId!,
        deviceName: _deviceName,
        deviceFingerprint: _deviceFingerprint,
      );

      if (response.success && response.data != null) {
        final AuthResponse data = response.data!;

        await _apiService.storeTokens(
          token: data.token,
          refreshToken: "",
          expiresIn: data.expiresIn ?? 0,
          userId: data.data?.id ?? 0,
        );

        // Store session ID if present
        if (data.sessionId != null) {
          _currentSessionId = data.sessionId;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_session_id', data.sessionId!);
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
      final response = await _apiService.verifyNewDevice(
        email: email,
        otp: otp,
        requestId: requestId,
        sessionId: sessionId,
        deviceId: _deviceId!,
        deviceName: _deviceName,
        deviceFingerprint: _deviceFingerprint,
      );

      if (response.success && response.data != null) {
        final AuthResponse data = response.data!;

        await _apiService.storeTokens(
          token: data.token,
          refreshToken: "",
          expiresIn: data.expiresIn ?? 0,
          userId: data.data?.id ?? 0,
        );

        // Update current session
        if (data.sessionId != null) {
          _currentSessionId = data.sessionId;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_session_id', data.sessionId!);
        }

        notifyListeners();
      }

      return response;
    } catch (error) {
      print('Verify new device failed: $error');
      return ApiResponse(success: false, error: error.toString());
    }
  }

  Future<ApiResponse<dynamic>> enableBiometricLogin({
    required String email,
    required String pin,
    bool enableLogin = false,
    bool enableTransactions = false,
    String? otp,
    String? requestId,
  }) async {
    try {
      return await _apiService.enableBiometric(
        email: email,
        deviceId: _deviceId!,
        pin: pin,
        enableLogin: enableLogin,
        enableTransactions: enableTransactions,
        otp: otp,
        requestId: requestId,
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

  // Generate biometric token (to be called from mobile app)
  Future<String> generateBiometricToken() async {
    if (_deviceId == null) {
      await initializeDeviceInfo();
    }

    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // In production, this should be signed with a private key
    // For now, we'll create a simple token format
    return '$_deviceId:$_deviceName:$timestamp:${_generateSignature(_deviceId!, timestamp)}';
  }

  String _generateSignature(String deviceId, int timestamp) {
    // In production, use proper cryptographic signing
    // For now, create a simple hash
    final data = '$deviceId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if biometric login should be offered
  Future<bool> shouldOfferBiometricLogin(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user has biometric login enabled from backend
      final user = _user;
      if (user?.biometricLoginEnabled == true) {
        return true;
      }

      // Check local preferences
      final biometricEnabled =
          prefs.getBool('biometric_enabled_$email') ?? false;
      final lastLoginEmail = prefs.getString('last_login_email');

      return biometricEnabled && lastLoginEmail == email;
    } catch (e) {
      print('Error checking biometric offer: $e');
      return false;
    }
  }

  // Save biometric credentials locally (for auto-fill)
  Future<void> saveBiometricCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled_$email', true);
      await prefs.setString('biometric_email', email);
      await prefs.setString('biometric_password', password);
    } catch (e) {
      print('Error saving biometric credentials: $e');
    }
  }

  // Clear biometric credentials
  Future<void> clearBiometricCredentials(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('biometric_enabled_$email');
      await prefs.remove('biometric_email');
      await prefs.remove('biometric_password');
    } catch (e) {
      print('Error clearing biometric credentials: $e');
    }
  }

  // Get saved biometric credentials
  Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('biometric_email');
      final password = prefs.getString('biometric_password');

      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      print('Error getting biometric credentials: $e');
      return null;
    }
  }

  Future<bool> register(RegisterData userData) async {
    try {
      final response = await _apiService.register(userData);

      if (response.success && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;

        await _apiService.storeTokens(
          token: data['token'],
          refreshToken: data['refreshToken'],
          expiresIn: data['expiresIn'],
          userId: data['userId'],
        );

        _user = User.fromJson(data['user']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      print('Registration failed: $error');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _user = null;
      _needsAccountOnboarding = false;
      _bvnRequestId = null;
      _banks = null;
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

  Future<Map<String, dynamic>> sendEmailVerification(String email) async {
    try {
      final response = await _apiService.sendEmailVerification(email);
      if (response.success) {
        // Show success message
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Verification code sent to your email!',
            ),
          ),
        );
        return {
          'success': true,
          'requestId': response.data?['requestId'],
          'message': response.message,
        };
      }
      return {
        'success': false,
        'message':
            response.error ??
            response.message ??
            'Failed to send verification code',
      };
    } catch (error) {
      print('Send email verification failed: $error');
      return {'success': false, 'message': 'Failed to send verification code'};
    }
  }

  Future<bool> completePersonalInfo(PersonalInfoData data) async {
    try {
      final response = await _apiService.completePersonalInfo(data);
      if (response.success) {
        // Show success message
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('needsAccountOnboarding', needs ? 'true' : 'false');
    notifyListeners();
  }

    void setNeedsUserOnboarding(bool needs) async {
    _needsAccountOnboarding = needs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('needsUserOnboarding', needs ? 'true' : 'false');
  }
}
