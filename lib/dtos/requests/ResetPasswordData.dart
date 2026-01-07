
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