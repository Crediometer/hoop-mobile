// lib/services/storage_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'authToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _authStatusKey = 'isAuthenticated';
  static const String _userIdKey = 'userIdPlain';
  static const String _userDataKey = 'userData';
  static const String _userAppearence = 'userAppearence';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Token management
  Future<void> storeToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<void> storeRefreshToken(String refreshToken) async {
    final prefs = await _prefs;
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  // Auth status
  Future<void> setAuthStatus(bool isAuthenticated) async {
    final prefs = await _prefs;
    await prefs.setBool(_authStatusKey, isAuthenticated);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await _prefs;
    return prefs.getBool(_authStatusKey) ?? false;
  }

  // User ID
  Future<void> storeUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_userIdKey);
  }

  // User data
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final prefs = await _prefs;
    await prefs.setString(_userDataKey, json.encode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _prefs;
    final data = prefs.getString(_userDataKey);
    return data != null ? json.decode(data) as Map<String, dynamic> : null;
  }

  // User data
  Future<void> storeUserAppearance(String appearance) async {
    final prefs = await _prefs;
    await prefs.setString(_userAppearence, appearance);
  }

  Future<String> getUserAppearance() async {
    final prefs = await _prefs;
    final data = prefs.getString(_userAppearence);
    return data ?? 'system';
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_authStatusKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
  }
}
