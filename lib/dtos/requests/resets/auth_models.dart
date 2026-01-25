class FormData {
  String email;
  String code;
  String password;
  String confirmPassword;

  FormData({
    this.email = '',
    this.code = '',
    this.password = '',
    this.confirmPassword = '',
  });

  FormData copyWith({
    String? email,
    String? code,
    String? password,
    String? confirmPassword,
  }) {
    return FormData(
      email: email ?? this.email,
      code: code ?? this.code,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class ResetPasswordResponse {
  final bool success;
  final String? message;
  final String? error;
  final String? requestId;
  final String? verificationId;

  ResetPasswordResponse({
    required this.success,
    this.message,
    this.error,
    this.requestId,
    this.verificationId,
  });
}

enum ResetStep {
  request,
  verify,
  reset,
  success,
}