// lib/dtos/models/tokens/token_manager.dart (updated abstract class)
import 'package:hoop/dtos/podos/tokens/token_pref.dart';

abstract class TokenManager {
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<void> saveToken(String token);
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> deleteToken();
  Future<void> deleteRefreshToken();
  Future<void> clearAllTokens();
  Future<bool> isTokenExpired();
  Future<DateTime?> getTokenExpiry();
  Future<int?> getUserId();
  Future<void> saveUserId(int userId);
  Future<void> saveTokenExpiry(int expiresInSeconds);

  static TokenManager? _instance;

  static TokenManager get instance {
    if (_instance == null) {
      _instance = SharedPrefsTokenManager();
    }
    return _instance!;
  }

  static void setInstance(TokenManager manager) {
    _instance = manager;
  }
}
