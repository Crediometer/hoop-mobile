import 'package:flutter/material.dart';
import 'package:hoop/constants/themes.dart';

class HoopSegmentButton extends StatelessWidget {
  const HoopSegmentButton({
    super.key,
    required this.label,
    required this.segment,
    this.handleSegmentChange,
    required this.isSelected,
  });
  final String label;
  final int segment;
  final bool isSelected;
  final Function? handleSegmentChange;

  

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: handleSegmentChange != null
          ? () => handleSegmentChange!(segment)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2D3139) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : HoopTheme.primaryRed)
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
