import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HoopInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final bool isDarkMode;
  final Widget? suffixIcon;

  const HoopInput(
      {super.key,
      required this.controller,
      this.hintText,
      this.obscureText = false,
      this.isDarkMode = false,
      this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1C1F2E) : Colors.grey[200],
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  // 🔹 Reusable TextField (Dark/Light aware)
}
