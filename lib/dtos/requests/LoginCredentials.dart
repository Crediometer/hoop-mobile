// lib/dtos/requests/auth_requests.dart
class LoginCredentials {
  final String email;
  final String password;
  final String? twoFactorCode;

  LoginCredentials({
    required this.email,
    required this.password,
    this.twoFactorCode,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
      };
}
