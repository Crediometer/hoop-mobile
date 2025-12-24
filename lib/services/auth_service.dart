
// Auth HTTP Service that extends BaseHttpService
import 'dart:convert';

import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:hoop/dtos/requests/RequestData.dart';
import 'package:hoop/dtos/responses/ApiResponse.dart';
import 'package:hoop/dtos/responses/AuthResponse.dart';
import 'package:hoop/dtos/responses/User.dart';
import 'package:hoop/services/base_http.dart';

class AuthHttpService extends BaseHttpService {
  AuthHttpService({
    required String baseUrl,
    TokenManager? tokenManager,
  }) : super(
          baseUrl: baseUrl,
          tokenManager: tokenManager,
        );

  // Login with email/password
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await postTyped<AuthResponse>(
        'auth/login',
        body: {'email': email, 'password': password},
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
  Future<ApiResponse<Map<String, dynamic>>> register(
      RegisterData data) async {
    return postTyped<Map<String, dynamic>>(
      'auth/register',
      body: data.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
      requiresAuth: false,
    );
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
      }

      return response;
    } catch (e) {
      // Still clear token even if API call fails
      if (tokenManager != null) {
        await tokenManager!.deleteToken();
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
      final response = await postTyped<AuthResponse>(
        'auth/refresh',
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        await tokenManager!.saveToken(response.data!.token);
      }

      return response;
    } catch (e) {
      // If refresh fails, clear token
      await tokenManager!.deleteToken();
      return ApiResponse<AuthResponse>(
        success: false,
        message: e.toString(),
        statusCode: 401,
      );
    }
  }

  // Get user profile
  Future<ApiResponse<User>> getProfile() async {
    return getTyped<User>(
      'user/retrieve-profile',
      fromJson: (json) => User.fromJson(json),
    );
  }

  // Update appearance
  Future<ApiResponse<Map<String, dynamic>>> updateAppearance(
      String appearance) async {
    return putTyped<Map<String, dynamic>>(
      'user/update-appearance',
      body: {'appearance': appearance},
      fromJson: (json) => json as Map<String, dynamic>,
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

  // Verify account name
  Future<ApiResponse<Map<String, dynamic>>> verifyAccount(
    String bankCode,
    String accountNumber,
  ) async {
    return postTyped<Map<String, dynamic>>(
      'accounts/verify',
      body: {
        'bankCode': bankCode,
        'accountNumber': accountNumber,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // Forgot password
  Future<ApiResponse<void>> forgotPassword(String email) async {
    return postTyped<void>(
      'auth/forgot-password',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  // Reset password
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return postTyped<void>(
      'auth/reset-password',
      body: {
        'token': token,
        'password': newPassword,
      },
      requiresAuth: false,
    );
  }

  // Verify email
  Future<ApiResponse<void>> verifyEmail(String token) async {
    return postTyped<void>(
      'auth/verify-email',
      body: {'token': token},
      requiresAuth: false,
    );
  }

  // Enable/disable two-factor authentication
  Future<ApiResponse<void>> toggleTwoFactor(bool enabled) async {
    return postTyped<void>(
      'auth/two-factor',
      body: {'enabled': enabled},
    );
  }
}