// lib/extensions/context_extensions.dart
import 'package:flutter/material.dart';

extension SnackbarExtension on BuildContext {
  // Show basic snackbar
  void showSnackBar({
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool floating = true,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        margin: floating ? const EdgeInsets.all(16) : null,
        shape: floating
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )
            : null,
      ),
    );
  }

  // Quick success snackbar
  void showSuccessSnackBar(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }

  // Quick error snackbar
  void showErrorSnackBar(String message,
      {Duration duration = const Duration(seconds: 4)}) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      duration: duration,
    );
  }

  // Quick warning snackbar
  void showWarningSnackBar(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
      duration: duration,
    );
  }

  // Quick info snackbar
  void showInfoSnackBar(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.blue,
      duration: duration,
    );
  }

  // Snackbar with action
  void showActionSnackBar({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor = Colors.blue,
    Duration duration = const Duration(seconds: 5),
  }) {
    showSnackBar(
      message: message,
      backgroundColor: backgroundColor,
      duration: duration,
      action: SnackBarAction(
        label: actionLabel,
        onPressed: onAction,
        textColor: Colors.white,
      ),
    );
  }

  // Snackbar with icon
  void showIconSnackBar({
    required String message,
    required IconData icon,
    Color? backgroundColor,
    Color? iconColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Hide current snackbar
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  // Clear all snackbars
  void clearSnackBars() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }
}