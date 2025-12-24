
import 'package:hoop/dtos/responses/User.dart';

class AuthResponse {
  final User user;
  final String token;
  final String firstName;
  final String lastName;
  final String email;
  final String refreshToken;
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }
}