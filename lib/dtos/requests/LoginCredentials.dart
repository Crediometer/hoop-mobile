// lib/dtos/requests/auth_requests.dart
class LoginCredentials {
  final String email;
  final String password;
  final String? twoFactorCode;
  final String? biometricToken;
  final String? deviceId;
  final String? deviceName;
  final String? deviceFingerprint;
  final String? otp;
  final String? requestId;
  final String? sessionId;

  LoginCredentials({
    required this.email,
    required this.password,
    this.twoFactorCode,
    this.biometricToken,
    this.deviceId,
    this.deviceName,
    this.deviceFingerprint,
    this.otp,
    this.requestId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        if (biometricToken != null) 'biometricToken': biometricToken,
        if (deviceId != null) 'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
        if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
        if (otp != null) 'otp': otp,
        if (requestId != null) 'requestId': requestId,
        if (sessionId != null) 'sessionId': sessionId,
      };
}