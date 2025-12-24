// token_manager.dart
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsTokenManager implements TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  @override
  Future<void> refreshToken() async {
    // Implement your token refresh logic here
    // This might involve calling your refresh token endpoint
    // and saving the new token
    throw UnimplementedError('refreshToken() has not been implemented');
  }
}