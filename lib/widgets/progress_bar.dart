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

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 5,
          backgroundColor: Colors.white12,
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
