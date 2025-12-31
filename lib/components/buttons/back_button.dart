import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';

class HoopBackButton extends StatelessWidget {
  const HoopBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      style: IconButton.styleFrom(
        backgroundColor: HoopTheme.getCategoryBackgroundColor(
          'back_button',
          isDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
