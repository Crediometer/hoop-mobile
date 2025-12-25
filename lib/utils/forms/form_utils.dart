// lib/utils/form_utils.dart
import 'package:flutter/material.dart';

class FormUtils {
  static bool validateAndSave(GlobalKey<FormState> formKey) {
    final form = formKey.currentState;
    if (form == null) return false;
    
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  static void unfocusAll(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static void showValidationErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}