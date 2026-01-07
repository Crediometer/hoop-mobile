// lib/services/auth_http_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:hoop/constants/strings.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/dtos/requests/FacialVerificationData.dart';
import 'package:hoop/dtos/requests/PersonalInfoData.dart';
import 'package:hoop/dtos/requests/PhoneVerificationData.dart';
import 'package:hoop/dtos/requests/RequestData.dart';
import 'package:hoop/dtos/requests/TwoFactorEnableData.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/AuthResponse.dart';
import 'package:hoop/dtos/responses/User.dart';

import 'package:hoop/services/base_http.dart';

class AuthHttpService extends BaseHttpService {
  AuthHttpService() : super(baseUrl: BASE_URL);

  // ==================== AUTHENTICATION METHODS ====================

  // Login with email/password and optional 2FA
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
    String? twoFactorCode,
  }) async {
    try {
      final response = await postTyped<AuthResponse>(
        'auth/login',
        body: {
          'email': email,
          'password': password,
          if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        },
        fromJson: (json) => AuthResponse.fromJson(json),
        requiresAuth: false,
      );

      // Save token if login is successful
      if (response.success && response.data != null && tokenManager != null) {
        await tokenManager!.saveToken(response.data!.token);
      }

      return response;
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // Register new user
  Future<ApiResponse<AuthResponse>> register(RegisterData data) async {
    try {
      final response = await postTyped<AuthResponse>(
        'auth/register',
        body: data.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json),
        requiresAuth: false,
      );

      // Save token if registration is successful
      if (response.success && response.data != null && tokenManager != null) {
        await tokenManager!.saveToken(response.data!.token);
        // await tokenManager!.saveRefreshToken(response.data!.refreshToken);
      }

      return response;
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // Logout
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await postTyped<void>(
        'auth/logout',
        fromJson: (json) => null,
      );

      // Clear token regardless of API response
      if (tokenManager != null) {
        await tokenManager!.deleteToken();
        await tokenManager!.deleteRefreshToken();
      }

      return response;
    } catch (e) {
      // Still clear token even if API call fails
      if (tokenManager != null) {
        await tokenManager!.deleteToken();
        await tokenManager!.deleteRefreshToken();
      }
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // Refresh token
  Future<ApiResponse<AuthResponse>> refreshToken() async {
    if (tokenManager == null) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Token manager not configured',
        statusCode: 401,
      );
    }

    try {
      final refreshToken = await tokenManager!.getRefreshToken();
      if (refreshToken == null) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'No refresh token available',
          statusCode: 401,
        );
      }

      final response = await postTyped<AuthResponse>(
        'auth/refresh',
        body: {'refreshToken': refreshToken},
        fromJson: (json) => AuthResponse.fromJson(json),
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        await tokenManager!.saveToken(response.data!.token);
        // await tokenManager!.saveRefreshToken(response.data!.refreshToken);
      }

      return response;
    } catch (e) {
      // If refresh fails, clear token
      await tokenManager!.deleteToken();
      await tokenManager!.deleteRefreshToken();
      return ApiResponse<AuthResponse>(
        success: false,
        message: e.toString(),
        statusCode: 401,
      );
    }
  }

  // Validate session
  Future<bool> validateSession() async {
    if (tokenManager == null) return false;

    try {
      final token = await tokenManager!.getToken();
      if (token == null) return false;

      // Check if token is expired
      final isExpired = await tokenManager!.isTokenExpired();
      if (isExpired) {
        // Try to refresh token
        final refreshResponse = await refreshToken();
        return refreshResponse.success;
      }

      return true;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }

  // ==================== PROFILE METHODS ====================

  // Get user profile
  Future<ApiResponse<User>> getProfile() async {
    return getTyped<User>(
      'user/retrieve-profile',
      fromJson: (json) => User.fromJson(json),
    );
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> updates) async {
    return patchTyped<User>(
      'user/update-profile',
      body: updates,
      fromJson: (json) => User.fromJson(json),
    );
  }

  // Update appearance
  Future<ApiResponse<Map<String, dynamic>>> updateAppearance(
    String appearance,
  ) async {
    return putTyped<Map<String, dynamic>>(
      'user/update-appearance',
      body: {'appearance': appearance},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Upload user avatar
  Future<ApiResponse<Map<String, dynamic>>> uploadAvatar(
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final response = await uploadFile(
        'auth/profile/avatar',
        fileBytes,
        fileName,
      );

      final responseBody = json.decode(response.body);
      return ApiResponse<Map<String, dynamic>>(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: responseBody['data'] != null
            ? Map<String, dynamic>.from(responseBody['data'])
            : null,
        message: responseBody['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // ==================== PHONE VERIFICATION METHODS ====================

  // Send phone verification code
  Future<ApiResponse<Map<String, dynamic>>> sendPhoneVerification(
    String phone,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'auth/phone/send-code',
      body: {'phone': phone},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  // Verify phone number with code
  Future<ApiResponse<Map<String, dynamic>>> verifyPhone(
    PhoneVerificationData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'auth/phone/verify',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  // ==================== FACIAL VERIFICATION METHODS ====================

  // Verify facial identity
  Future<ApiResponse<Map<String, dynamic>>> verifyFacial(
    FacialVerificationData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'auth/facial/verify',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Send facial verification
  Future<ApiResponse<User>> sendFacialVerification(
    String imageData,
    String fileName,
  ) async {
    return postTyped<User>(
      'completeOnboarding/verify-facial',
      body: {'imageData': imageData, 'fileName': fileName},
      fromJson: (json) => User.fromJson(json),
    );
  }

  // Create facial verification session
  Future<ApiResponse<Map<String, dynamic>>> createSession() async {
    return postTyped<Map<String, dynamic>>(
      'completeOnboarding/create-session',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ==================== TWO-FACTOR AUTHENTICATION ====================

  // Enable two-factor authentication
  Future<ApiResponse<TwoFactorEnableData>> enableTwoFactor() async {
    return postTyped<TwoFactorEnableData>(
      'auth/2fa/enable',
      fromJson: (json) => TwoFactorEnableData.fromJson(json),
    );
  }

  // Disable two-factor authentication
  Future<ApiResponse<Map<String, dynamic>>> disableTwoFactor(
    String code,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'auth/2fa/disable',
      body: {'code': code},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Verify two-factor authentication code
  Future<ApiResponse<Map<String, dynamic>>> verifyTwoFactor(String code) async {
    return postTyped<Map<String, dynamic>>(
      'auth/2fa/verify',
      body: {'code': code},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ==================== PASSWORD MANAGEMENT ====================

  // Change password
  Future<ApiResponse<Map<String, dynamic>>> changePassword(
    ChangePasswordData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'user/change-password',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Request password reset
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(String email) async {
    return postTyped<Map<String, dynamic>>(
      'forgotPwd/initiate',
      body: {'email': email},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  // Verify password reset token
  Future<ApiResponse<Map<String, dynamic>>> verifyPasswordResetToken(
    VerifyResetTokenData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'forgotPwd/verify-otp',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  // Reset password with verified token
  Future<ApiResponse<Map<String, dynamic>>> resetPassword(
    ResetPasswordData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'forgotPwd/reset-password',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  // ==================== EMAIL VERIFICATION ====================

  // Send email verification code
  Future<ApiResponse<Map<String, dynamic>>> sendEmailVerification(
    String email,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'auth/verify-email',
      body: {'email': email},
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
  }

  // Verify email with token
  Future<ApiResponse<void>> verifyEmail(String token) async {
    return postTyped<void>(
      'auth/verify-email-confirm',
      body: {'token': token},
      requiresAuth: false,
    );
  }

  // ==================== ONBOARDING & PERSONAL INFO ====================

  // Complete personal information
  Future<ApiResponse<Map<String, dynamic>>> completePersonalInfo(
    PersonalInfoData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'completeOnboarding/personal-info',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Validate BVN
  Future<ApiResponse<Map<String, dynamic>>> validateBvn(
    ValidateBvnData data,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'completeOnboarding/validate-bvn',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ==================== BANKING METHODS ====================

  // Load banks
  Future<ApiResponse<List<Bank>>> loadBanks() async {
    return getTyped<List<Bank>>(
      'banks',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => Bank.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Verify account name
  Future<ApiResponse<Map<String, dynamic>>> verifyAccount(
    String bankCode,
    String accountNumber,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'accounts/verify',
      body: {'bankCode': bankCode, 'accountNumber': accountNumber},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Register user primary account
  Future<ApiResponse<Map<String, dynamic>>> registerUserPrimaryAccount({
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    return postTyped<Map<String, dynamic>>(
      'accounts/register-primary',
      body: {
        'bankCode': bankCode,
        'accountNumber': accountNumber,
        'accountName': accountName,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ==================== TOKEN MANAGEMENT ====================

  Future<void> storeTokens({
    required String token,
    required String refreshToken,
    required int expiresIn,
    required int userId,
  }) async {
    if (tokenManager != null) {
      await tokenManager!.saveToken(token);
      await tokenManager!.saveRefreshToken(refreshToken);
      // Optionally store expiresIn and userId if needed
    }
  }
}

// Bank model
class Bank {
  final String code;
  final String name;

  Bank({required this.code, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) =>
      Bank(code: json['code'] ?? '', name: json['name'] ?? '');

  Map<String, dynamic> toJson() => {'code': code, 'name': name};
}
