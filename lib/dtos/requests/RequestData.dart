
import 'package:flutter/foundation.dart';

// Register data model
class RegisterData {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;

  RegisterData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
    };
  }
}

// Bank model
class Bank {
  final String name;
  final String code;

  Bank({required this.name, required this.code});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

