class VerifyResetTokenData {
  final String otp;
  final String email;

  VerifyResetTokenData({required this.otp, required this.email});

  Map<String, dynamic> toJson() => {'otp': otp, 'email': email};
}
