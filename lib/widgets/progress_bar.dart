import 'package:flutter/material.dart';

class SignupProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SignupProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = currentStep / totalSteps;
    final int percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Row with title and percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Setup Progress",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "$percentage%",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 🔹 Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.grey,
            color: const Color(0xFF0A1866),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
