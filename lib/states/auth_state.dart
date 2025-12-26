import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hoop/components/status/OperationStatus.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _needsAccountOnboarding = true;
  String? _bvnRequestId;
  List<dynamic>? _banks;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get needsAccountOnboarding => _needsAccountOnboarding;
  String? get bvnRequestId => _bvnRequestId;
  List<dynamic>? get banks => _banks;

  final AuthHttpService _apiService = AuthHttpService();

  AuthProvider() {
    _initialize();
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
          _user = response.data as User?;
        }
      }
    } catch (error) {
      print('Auth check failed: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> login(
    String email,
    String password, {
    String? twoFactorCode,
  }) async {
    try {
      // Clear storage
      final prefs = await SharedPreferences.getInstance();
      final joinIntent = prefs.getString('joinIntent');

      await prefs.clear();
      if (joinIntent != null) {
        await prefs.setString('joinIntent', joinIntent);
      }

      final response = await _apiService.login(
        email: email,
        password: password,
        twoFactorCode: twoFactorCode,
      );

      if (response.success && response.data != null) {
        log("?? ${response.data?.toJson()}");
        final AuthResponse data = response.data!;

        log("?? ${response.data?.toJson()}");
        // Store tokens
        await _apiService.storeTokens(
          token: data.token,
          refreshToken: "",
          expiresIn: data.expiresIn ?? 0,
          userId: data.userId,
        );

        if (data.operationStatus == OperationStatus.TEMPORARY_REDIRECT) {
          _needsAccountOnboarding = true;
          await prefs.setString('needsAccountOnboarding', 'true');
        } else {
          _needsAccountOnboarding = false;
          await prefs.setString('needsAccountOnboarding', 'false');
        }

        notifyListeners();
      }

      return response;
    } catch (error) {
      print('Login failed: $error');
      return ApiResponse(success: false, error: error.toString());
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
      if (response.success && response.data != null) {
        _user = User.fromJson(response.data as Map<String, dynamic>);
        notifyListeners();
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
}
