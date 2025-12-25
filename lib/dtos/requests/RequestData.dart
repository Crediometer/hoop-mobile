class RegisterData {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String otp;
  final String requestId;
  final String password;

  RegisterData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.otp,
    required this.requestId,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'otp': otp,
        'requestId': requestId,
        'password': password,
      };
}


