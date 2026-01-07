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
