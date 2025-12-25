// lib/dtos/models/tokens/token_manager.dart (updated abstract class)
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
}
