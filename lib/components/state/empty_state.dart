import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/constants/themes.dart';

class HoopEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String? secondaryActionText;
  final IconData? iconData;
  final VoidCallback? onPress;

   const HoopEmptyState({
    super.key,
    this.onPress,
    this.color = HoopTheme.error,
    required this.title,
    this.iconData = Icons.download_rounded,
    required this.subtitle,
    this.secondaryActionText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F2A17)
                  : color.withOpacity(0.095),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(iconData, color: color, size: 34),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            textAlign: TextAlign.center,
          ),
          if (onPress != null) ...[
            const SizedBox(height: 20),
        
            ElevatedButton(
              onPressed: onPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(secondaryActionText ?? "Retry"),
            ),
          ],
        ],
      ),
    );
  }
}
