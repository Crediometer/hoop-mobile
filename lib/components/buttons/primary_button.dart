import 'package:flutter/material.dart';

class HoopButton extends StatelessWidget {
  final bool isLoading;
  final bool disabled;
  final String buttonText;
  final VoidCallback? onPressed;

  HoopButton({
    super.key,

    this.isLoading = false,
    this.onPressed,
    this.disabled = false,
    this.buttonText = "Click me",
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (disabled || isLoading) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: disabled || isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0a1866), Color(0xFF1347cd)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: disabled || isLoading ? Colors.grey[400] : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: disabled || isLoading
              ? []
              : [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                buttonText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
