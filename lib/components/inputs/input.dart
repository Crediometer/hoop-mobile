import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HoopInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final bool isDarkMode;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final bool autoValidate;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final bool? filled;
  final Color? fillColor;

  const HoopInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.isDarkMode = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.validator,
    this.autoValidate = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.contentPadding,
    this.errorText,
    this.filled,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFillColor = fillColor ??
        (isDarkMode ? const Color(0xFF1C1F2E) : Colors.grey[200]);
    final effectiveFilled = filled ?? true;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey : Colors.grey[600],
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          fontSize: 14,
        ),
        filled: effectiveFilled,
        fillColor: effectiveFilled
            ? (enabled ? effectiveFillColor : effectiveFillColor?.withOpacity(0.5))
            : null,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white24.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          height: 0.8,
        ),
        counterText: showCounter ? null : '',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
    );
  }
}