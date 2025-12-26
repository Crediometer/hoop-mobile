import 'package:flutter/material.dart';

class HoopTheme {
  // Primary Colors
  static const Color primaryOrange = Color(0xFFFB7F2D);
  static const Color primaryGreen = Color(0xFF00C853);
  static const Color primaryPurple = Color(0xFFE0C0FF);
  static const Color primaryRed = Color(0xFFFF5722);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0E1318);
  static const Color darkCard = Color(0xFF1E2530);
  static const Color darkCardAlt = Color(0xFF2C2C2C);
  static const Color darkElevated = Color(0xFF2D3139);
  static const Color darkChip = Color(0xFF141617);
  static const Color darkChipAlt = Color(0xFF2E2E2E);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Colors.white;
  static const Color lightChip = Colors.white;
  static const Color lightChipAlt = Color(0xFFFFF0E8);

  // Pastel Colors for List View
  static const Color pastelOrange = Color(0xFFFFF4EE);
  static const Color pastelBlue = Color(0xFFEFF7FF);

  // Text Colors
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70% opacity
  static const Color darkTextTertiary = Color(0x99FFFFFF); // 60% opacity

  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF555555);
  static const Color lightTextTertiary = Color(0xFF777777);
  static const Color lightTextAccent = Color(0xFFB84B00);

  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryOrange,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryOrange,
      secondary: primaryGreen,
      surface: darkCard,
      background: darkBackground,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onBackground: darkTextPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryOrange,
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryOrange,
        side: const BorderSide(color: primaryOrange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: darkTextTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D3139),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: darkTextPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: darkTextPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: darkTextTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryOrange,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: darkTextTertiary,
      ),
    ),
  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryOrange,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryOrange,
      secondary: primaryGreen,
      surface: lightCard,
      background: lightBackground,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      onBackground: lightTextPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryOrange,
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryOrange,
        side: const BorderSide(color: primaryOrange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: lightTextTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: lightTextPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: lightTextPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: lightTextPrimary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightTextSecondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: lightTextTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryOrange,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: lightTextTertiary,
      ),
    ),
  );

  // Helper methods for colors based on theme
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;


  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  static Color getTextTertiary(bool isDark) =>
      isDark ? darkTextTertiary : lightTextTertiary;

  static Color getCardColorForList(int index, bool isDark) {
    if (isDark) return darkCard;
    return index % 2 == 0 ? pastelOrange : pastelBlue;
  }

  static Color getChipBackground(bool isDark) =>
      isDark ? darkChipAlt : lightChipAlt;

  static Color getChipTextColor(bool isDark) =>
      isDark ? darkTextSecondary : lightTextAccent;

  // NEW: 10 subtle background colors for community cards
  static const List<Color> communityCardColors = [
    Color(0xFFFFF4EE), // Soft peach (light orange) - Existing
    Color(0xFFEFF7FF), // Light blue - Existing
    Color(0xFFF5F0FF), // Lavender mist
    Color(0xFFF0FFF4), // Mint cream
    Color(0xFFFFF9F0), // Light apricot
    Color(0xFFF0F8FF), // Alice blue
    Color(0xFFF8F0FF), // Pale lilac
    Color(0xFFF0FFF0), // Honeydew
    Color(0xFFFFF0F5), // Lavender blush
    Color(0xFFF0FFFF), // Azure mist
  ];

  // NEW: Dark theme variants (more muted for dark mode)
  static const List<Color> communityCardColorsDark = [
    Color(0xFF2A1F1A), // Dark peach variant
    Color(0xFF1A222A), // Dark blue variant
    Color(0xFF2A1F2A), // Dark lavender
    Color(0xFF1A2A1F), // Dark mint
    Color(0xFF2A251A), // Dark apricot
    Color(0xFF1A252A), // Dark alice
    Color(0xFF251A2A), // Dark lilac
    Color(0xFF1A2A1A), // Dark honeydew
    Color(0xFF2A1A25), // Dark blush
    Color(0xFF1A2A2A), // Dark azure
  ];

  // NEW: Light gradients for cards
  static const List<LinearGradient> communityGradients = [
    LinearGradient(
      colors: [Color(0xFFFFF4EE), Color(0xFFFFE8D6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFEFF7FF), Color(0xFFD6EBFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF5F0FF), Color(0xFFE8D6FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF0FFF4), Color(0xFFD6FFE0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFFF9F0), Color(0xFFFFEBD6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // NEW: Helper method to get a card color based on index
  static Color getCardColor(int index, bool isDark) {
    final colors = isDark ? communityCardColorsDark : communityCardColors;
    return colors[index % colors.length];
  }

  // NEW: Helper method to get a gradient based on index
  static LinearGradient getCardGradient(int index, bool isDark) {
    if (isDark) {
      return LinearGradient(
        colors: [
          getCardColor(index, true),
          getCardColor((index + 1) % 10, true),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return communityGradients[index % communityGradients.length];
  }

  // NEW: For swipe cards (use gradients for better visual)
  static List<Color> swipeCardColors = [
    const Color(0xFFE0C0FF), // Light purple (existing)
    const Color(0xFFC0FFD6), // Mint green
    const Color(0xFFFFD6C0), // Peach
    const Color(0xFFC0D6FF), // Light blue
    const Color(0xFFFFF0C0), // Pale yellow
    const Color(0xFFD6C0FF), // Periwinkle
    const Color(0xFFFFC0E0), // Pink
    const Color(0xFFC0FFF0), // Turquoise
    const Color(0xFFE0FFC0), // Lime
    const Color(0xFFFFE0C0), // Apricot
  ];

  static Color getSwipeCardColor(int index) {
    return swipeCardColors[index % swipeCardColors.length];
  }

  // NEW: Tags/category colors
  static const List<Color> categoryColors = [
    Color(0xFFFFF0E8), // Orange tag background
    Color(0xFFE8F0FF), // Blue tag background
    Color(0xFFF0E8FF), // Purple tag background
    Color(0xFFE8FFF0), // Green tag background
    Color(0xFFFFF8E8), // Yellow tag background
  ];

  static const List<Color> categoryTextColors = [
    Color(0xFFB84B00), // Orange text
    Color(0xFF0066CC), // Blue text
    Color(0xFF7B1FA2), // Purple text
    Color(0xFF2E7D32), // Green text
    Color(0xFFEF6C00), // Orange-yellow text
  ];

  static Color getCategoryColor(String category) {
    final index = category.hashCode.abs() % categoryColors.length;
    return categoryColors[index];
  }

  static Color getCategoryTextColor(String category) {
    final index = category.hashCode.abs() % categoryTextColors.length;
    return categoryTextColors[index];
  }
}
