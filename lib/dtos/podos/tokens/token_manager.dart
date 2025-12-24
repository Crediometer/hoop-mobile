
// Token management abstract class
abstract class TokenManager {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
  Future<void> refreshToken();
}