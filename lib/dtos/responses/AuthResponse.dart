// lib/dtos/responses/auth_response.dart
import 'package:hoop/components/status/OperationStatus.dart';
import 'package:hoop/dtos/responses/User.dart';

class AuthResponse {
  final String token;
  final int? expiresIn;
  final OperationStatus operationStatus;
  final User? data;
  
  // New fields for biometric/2FA flows
  final String? sessionId;
  final String? requestId;
  final bool? requires2FA;
  final bool? requiresDeviceVerification;
  final String? message;
  final String? deviceId;
  final String? deviceName;
  final bool? biometricEnabled;
  final bool? biometricTransactionEnabled;

  AuthResponse({
    required this.token,
    this.expiresIn,
    required this.operationStatus,
    this.data,
    this.sessionId,
    this.requestId,
    this.requires2FA,
    this.requiresDeviceVerification,
    this.message,
    this.deviceId,
    this.deviceName,
    this.biometricEnabled,
    this.biometricTransactionEnabled,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      expiresIn: json['expiresIn'],
      operationStatus: OperationStatus.firstWhere(
        (e) => e.value == (json['status'] ?? 200),
        orElse: () => OperationStatus.OK,
      ),
      data: json['data'] != null ? User.fromJson(json['data']) : null,
      sessionId: json['sessionId'],
      requestId: json['requestId'],
      requires2FA: json['requires2FA'] ?? false,
      requiresDeviceVerification: json['requiresDeviceVerification'] ?? false,
      message: json['message'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      biometricEnabled: json['biometricEnabled'],
      biometricTransactionEnabled: json['biometricTransactionEnabled'],
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresIn': expiresIn,
        'status': operationStatus,
        'data': data?.toJson(),
        'sessionId': sessionId,
        'requestId': requestId,
        'requires2FA': requires2FA,
        'requiresDeviceVerification': requiresDeviceVerification,
        'message': message,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'biometricEnabled': biometricEnabled,
        'biometricTransactionEnabled': biometricTransactionEnabled,
      };

  // Helper methods
  bool get isSuccess => operationStatus == OperationStatus.OK;
  bool get needs2FA => requires2FA == true;
  bool get needsDeviceVerification => requiresDeviceVerification == true;
}