class EmailVerificationData {
  final String email;

  EmailVerificationData({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}