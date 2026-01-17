import 'package:flutter/foundation.dart';

@immutable
class PersonalInfo {
  final int? id;
  final String? userId;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? gender;
  final String? occupation;
  final String? address;
  final String? state;
  final String? lga;
  final String? bvn;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PersonalInfo({
    this.id,
    this.userId,
    this.dateOfBirth,
    this.bio,
    this.gender,
    this.occupation,
    this.address,
    this.state,
    this.lga,
    this.bvn,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
    this.createdAt,
    this.updatedAt,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      id: json['id'] as int?,
      userId: json['userId'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      occupation: json['occupation'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      lga: json['lga'] as String?,
      bvn: json['bvn'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.tryParse(json['lastLocationUpdate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'gender': gender,
      'occupation': occupation,
      'address': address,
      'state': state,
      'lga': lga,
      'bvn': bvn,
      'latitude': latitude,
      'longitude': longitude,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

@immutable
class User {
  final int? id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? appearance;
  final bool? isPinSet;
  final String? phoneNumber;
  final String? imageUrl;
  final PersonalInfo? personalInfo;
  final DateTime? lastPINUpdate;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? biometricLoginEnabled;
  final DateTime? lastLogin;
  final bool? biometricTransactionEnabled;
  final DateTime? lastPasswordUpdate;
  final bool? is2faEnabled;

  final bool? loginNotification;

  const User({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.appearance,
    this.isPinSet,
    this.biometricTransactionEnabled,
    this.phoneNumber,
    this.biometricLoginEnabled,
    this.imageUrl,
    this.personalInfo,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.lastPasswordUpdate,
    this.lastPINUpdate,
    this.is2faEnabled,
    this.loginNotification,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      biometricTransactionEnabled: json['biometricTransactionEnabled'] as bool?,
      isPinSet: json['isPinSet'] as bool?,
      lastName: json['lastName'] as String?,
      appearance: json['appearance'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      imageUrl: json['imageUrl'] as String?,
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>)
          : null,
      biometricLoginEnabled: json['biometricLoginEnabled'] as bool?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
      lastPasswordUpdate: json['lastPasswordUpdate'] != null
          ? DateTime.tryParse(json['lastPasswordUpdate'].toString())
          : null,
      lastPINUpdate: json['lastPINUpdate'] != null
          ? DateTime.tryParse(json['lastPINUpdate'].toString())
          : null,
      is2faEnabled: json['is2faEnabled'] as bool?,
      loginNotification: json['loginNotification'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isPinSet': isPinSet,
      'appearance': appearance,
      'biometricLoginEnabled': biometricLoginEnabled,
      'biometricTransactionEnabled': biometricTransactionEnabled,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'personalInfo': personalInfo?.toJson(),
      'status': status,
      'lastPINUpdate': lastPINUpdate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'lastPasswordUpdate': lastPasswordUpdate?.toIso8601String(),
      'is2faEnabled': is2faEnabled,
      'loginNotification': loginNotification,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? appearance,
    String? phoneNumber,
    bool? isPinSet,
    String? imageUrl,
    PersonalInfo? personalInfo,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    DateTime? lastPasswordUpdate,
    DateTime? lastPINUpdate,
    bool? is2faEnabled,
    bool? loginNotification,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isPinSet: isPinSet ?? this.isPinSet,
      appearance: appearance ?? this.appearance,
      lastPINUpdate: lastPINUpdate ?? this.lastPINUpdate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      personalInfo: personalInfo ?? this.personalInfo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastPasswordUpdate: lastPasswordUpdate ?? this.lastPasswordUpdate,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
      loginNotification: loginNotification ?? this.loginNotification,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, firstName: $firstName, lastName: $lastName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
