import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'token_manager.dart';

class HiveTokenManager implements TokenManager {
  static const String _tokenBox = 'token_box';
  
  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_tokenBox)) {
      return await Hive.openBox(_tokenBox);
    }
    return Hive.box(_tokenBox);
  }
  
  @override
  Future<String?> getToken() async {
    final box = await _openBox();
    return box.get('auth_token');
  }
  
  @override
  Future<String?> getRefreshToken() async {
    final box = await _openBox();
    return box.get('refresh_token');
  }
  
  @override
  Future<void> saveToken(String token) async {
    final box = await _openBox();
    await box.put('auth_token', token);
    
    // Extract expiry from JWT token
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final int? exp = decodedToken['exp'];
      if (exp != null) {
        await box.put('token_expiry', exp);
      }
      
      // Extract and save user ID if present
      final dynamic userId = decodedToken['userId'] ?? decodedToken['sub'];
      if (userId != null) {
        await saveUserId(userId is int ? userId : int.tryParse(userId.toString()) ?? 0);
      }
    } catch (e) {
      print('Error decoding token: $e');
    }
  }
  
  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    final box = await _openBox();
    await box.put('refresh_token', refreshToken);
  }
  
  @override
  Future<void> deleteToken() async {
    final box = await _openBox();
    await box.delete('auth_token');
    await box.delete('token_expiry');
  }
  
  @override
  Future<void> deleteRefreshToken() async {
    final box = await _openBox();
    await box.delete('refresh_token');
  }
  
  @override
  Future<void> clearAllTokens() async {
    final box = await _openBox();
    await box.clear();
  }
  
  @override
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    
    final now = DateTime.now();
    // Add a 60-second buffer to account for network latency
    return now.isAfter(expiry.subtract(const Duration(seconds: 60)));
  }
  
  @override
  Future<DateTime?> getTokenExpiry() async {
    final box = await _openBox();
    final expiryTimestamp = box.get('token_expiry');
    
    if (expiryTimestamp == null) return null;
    
    // Convert Unix timestamp to DateTime
    return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
  }
  
  @override
  Future<int?> getUserId() async {
    final box = await _openBox();
    return box.get('user_id');
  }
  
  @override
  Future<void> saveUserId(int userId) async {
    final box = await _openBox();
    await box.put('user_id', userId);
  }
  
  @override
  Future<void> saveTokenExpiry(int expiresInSeconds) async {
    final box = await _openBox();
    final expiryTime = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await box.put('token_expiry', expiryTime.millisecondsSinceEpoch ~/ 1000);
  }
  
  // Additional utility methods
  
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final box = await _openBox();
    final encodedData = json.encode(userData);
    await box.put('user_data', encodedData);
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final box = await _openBox();
    final encodedData = box.get('user_data');
    if (encodedData == null) return null;
    
    try {
      return Map<String, dynamic>.from(json.decode(encodedData));
    } catch (e) {
      print('Error decoding user data: $e');
      return null;
    }
  }
  
  Future<void> deleteUserData() async {
    final box = await _openBox();
    await box.delete('user_data');
  }
  
  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null) return false;
    
    return !(await isTokenExpired());
  }
  
  // Store additional tokens
  Future<void> saveServiceToken(String serviceKey, String token) async {
    final box = await _openBox();
    await box.put('${serviceKey}_token', token);
  }
  
  Future<String?> getServiceToken(String serviceKey) async {
    final box = await _openBox();
    return box.get('${serviceKey}_token');
  }
  
  Future<void> deleteServiceToken(String serviceKey) async {
    final box = await _openBox();
    await box.delete('${serviceKey}_token');
  }
  
  // Close box
  Future<void> close() async {
    if (Hive.isBoxOpen(_tokenBox)) {
      await Hive.box(_tokenBox).close();
    }
  }
}