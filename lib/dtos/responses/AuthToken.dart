
// lib/models/auth.dart
class AuthTokens {
  final String token;
  final int userId;
  final String refreshToken;
  final int expiresIn;

  AuthTokens({
    required this.token,
    required this.userId,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      token: json['token'] ?? '',
      userId: json['userId'] ?? 0,
      refreshToken: json['refreshToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }
}