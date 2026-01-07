class PhoneVerificationData {
  final String phone;
  final String code;

  PhoneVerificationData({
    required this.phone,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'code': code,
      };
}
