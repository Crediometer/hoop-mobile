import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class HiveStorageService {
  static const String _authBox = 'auth_box';
  static const String _userBox = 'user_box';
  static const String _appBox = 'app_box';
  
  static final HiveStorageService _instance = HiveStorageService._internal();
  factory HiveStorageService() => _instance;
  HiveStorageService._internal();
  
  Future<void> init() async {
    await Hive.initFlutter();
    // No need to register adapters for simple types
  }
  
  // Helper method to open boxes lazily
  Future<Box> _openBox(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox(name);
    }
    return Hive.box(name);
  }
  
  // Token management
  Future<void> storeToken(String token) async {
    final box = await _openBox(_authBox);
    await box.put('authToken', token);
  }
  
  Future<String?> getToken() async {
    final box = await _openBox(_authBox);
    return box.get('authToken');
  }
  
  Future<void> storeRefreshToken(String refreshToken) async {
    final box = await _openBox(_authBox);
    await box.put('refreshToken', refreshToken);
  }
  
  Future<String?> getRefreshToken() async {
    final box = await _openBox(_authBox);
    return box.get('refreshToken');
  }
  
  // Auth status
  Future<void> setAuthStatus(bool isAuthenticated) async {
    final box = await _openBox(_authBox);
    await box.put('isAuthenticated', isAuthenticated);
  }
  
  Future<bool> isAuthenticated() async {
    final box = await _openBox(_authBox);
    return box.get('isAuthenticated', defaultValue: false);
  }
  
  // User ID
  Future<void> storeUserId(String userId) async {
    final box = await _openBox(_authBox);
    await box.put('userId', userId);
  }
  
  Future<String?> getUserId() async {
    final box = await _openBox(_authBox);
    return box.get('userId');
  }
  
  // User data
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final box = await _openBox(_userBox);
    await box.put('userData', json.encode(userData));
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final box = await _openBox(_userBox);
    final data = box.get('userData');
    return data != null ? json.decode(data) as Map<String, dynamic> : null;
  }
  
  // User appearance
  Future<void> storeUserAppearance(String appearance) async {
    final box = await _openBox(_authBox);
    await box.put('userAppearance', appearance);
  }
  
  Future<String> getUserAppearance() async {
    final box = await _openBox(_authBox);
    return box.get('userAppearance', defaultValue: 'system');
  }
  
  // Clear all auth data
  Future<void> clearAuthData() async {
    final authBox = await _openBox(_authBox);
    final userBox = await _openBox(_userBox);
    await authBox.clear();
    await userBox.clear();
  }
  
  // App-specific data storage
  Future<void> setString(String key, String value) async {
    final box = await _openBox(_appBox);
    await box.put(key, value);
  }
  
  Future<String?> getString(String key) async {
    final box = await _openBox(_appBox);
    return box.get(key);
  }
  
  Future<void> setBool(String key, bool value) async {
    final box = await _openBox(_appBox);
    await box.put(key, value);
  }
  
  Future<bool?> getBool(String key) async {
    final box = await _openBox(_appBox);
    return box.get(key);
  }
  
  Future<void> setInt(String key, int value) async {
    final box = await _openBox(_appBox);
    await box.put(key, value);
  }
  
  Future<int?> getInt(String key) async {
    final box = await _openBox(_appBox);
    return box.get(key);
  }
  
  Future<void> remove(String key) async {
    final box = await _openBox(_appBox);
    await box.delete(key);
  }
  
  Future<void> clearAll() async {
    final authBox = await _openBox(_authBox);
    final userBox = await _openBox(_userBox);
    final appBox = await _openBox(_appBox);
    
    await authBox.clear();
    await userBox.clear();
    await appBox.clear();
  }
  
  // Close boxes
  Future<void> close() async {
    if (Hive.isBoxOpen(_authBox)) await Hive.box(_authBox).close();
    if (Hive.isBoxOpen(_userBox)) await Hive.box(_userBox).close();
    if (Hive.isBoxOpen(_appBox)) await Hive.box(_appBox).close();
  }
}