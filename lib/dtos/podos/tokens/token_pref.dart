
import 'dart:convert';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this dependency

class SharedPrefsTokenManager implements TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Extract expiry from JWT token
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final int? exp = decodedToken['exp'];
      if (exp != null) {
        await prefs.setInt(_tokenExpiryKey, exp);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  @override
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  @override
  Future<void> deleteRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
  }

  @override
  Future<void> clearAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
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
    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_tokenExpiryKey);
    
    if (expiryTimestamp == null) return null;
    
    // Convert Unix timestamp to DateTime
    return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000);
  }

  @override
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  @override
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  @override
  Future<void> saveTokenExpiry(int expiresInSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await prefs.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch ~/ 1000);
  }

  // Additional utility methods

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = json.encode(userData);
    await prefs.setString(_userDataKey, encodedData);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = prefs.getString(_userDataKey);
    if (encodedData == null) return null;
    
    try {
      return Map<String, dynamic>.from(json.decode(encodedData));
    } catch (e) {
      print('Error decoding user data: $e');
      return null;
    }
  }

  Future<void> deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null) return false;
    
    return !(await isTokenExpired());
  }


  // Store additional tokens (if needed for different services)
  Future<void> saveServiceToken(String serviceKey, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${serviceKey}_token', token);
  }

  Future<String?> getServiceToken(String serviceKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${serviceKey}_token');
  }

  Future<void> deleteServiceToken(String serviceKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${serviceKey}_token');
  }
}

// Factory class for creating token managers
class TokenManagerFactory {
  static TokenManager createSharedPrefsManager() {
    return SharedPrefsTokenManager();
  }
  
  // You could add other implementations here:
  // static TokenManager createSecureStorageManager() { ... }
  // static TokenManager createFlutterSecureStorageManager() { ... }
}