class TwoFactorEnableData {
  final String? qrCode;
  final List<String>? backupCodes;

  TwoFactorEnableData({
    this.qrCode,
    this.backupCodes,
  });

  factory TwoFactorEnableData.fromJson(Map<String, dynamic> json) =>
      TwoFactorEnableData(
        qrCode: json['qrCode'],
        backupCodes: json['backupCodes'] != null
            ? List<String>.from(json['backupCodes'])
            : null,
      );
}

class ChangePasswordData {
  final String currentPassword;
  final String password;
  final String confirmationPassword;

  ChangePasswordData({
    required this.currentPassword,
    required this.password,
    required this.confirmationPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'password': password,
        'confirmationPassword': confirmationPassword,
      };
}

class ForgotPasswordData {
  final String email;

  ForgotPasswordData({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyResetTokenData {
  final String otp;
  final String email;

  VerifyResetTokenData({required this.otp, required this.email});

  Map<String, dynamic> toJson() => {'otp': otp, 'email': email};
}

class ResetPasswordData {
  final String verificationId;
  final String requestId;
  final String newPassword;

  ResetPasswordData({
    required this.verificationId,
    required this.requestId,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'verificationId': verificationId,
        'requestId': requestId,
        'newPassword': newPassword,
      };
}

class ValidateBvnData {
  final String bvn;
  final String dateOfBirth;

  ValidateBvnData({
    required this.bvn,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
        'bvn': bvn,
        'dateOfBirth': dateOfBirth,
      };
}

class EmailVerificationData {
  final String email;

  EmailVerificationData({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}