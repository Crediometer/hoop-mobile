// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? occupation;
  final bool isVerified;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.occupation,
    required this.isVerified,
    required this.twoFactorEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      imageUrl: json['imageUrl'],
      occupation: json['occupation'],
      isVerified: json['isVerified'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl': imageUrl,
      'occupation': occupation,
      'isVerified': isVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
