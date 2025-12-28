import 'package:flutter/material.dart';

class HoopTheme {
  // Primary Colors - Updated to match web
  static const Color primaryBlue = Color(0xFF09145E);
  static const Color vibrantOrange = Color(0xFFFF6B35);
  static const Color successGreen = Color(0xFF28A745);
  static const Color primaryPurple = Color(0xFFE0C0FF);
  static const Color primaryRed = Color(0xFFFF5722);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF1F3F4);
  
  // Text Colors
  static const Color foreground = Color(0xFF1A1A2E);
  static const Color mutedForeground = Color(0xFF6C757D);
  
  // Border Colors
  static const Color border = Color(0x1A000000); // 0.1 opacity black
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkCard = Color(0xFF1A1F2E);
  static const Color darkForeground = Color(0xFFE8E9EA);
  static const Color darkMuted = Color(0xFF252938);
  static const Color darkMutedForeground = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF374151);

  // Status Colors
  static const Color destructive = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: vibrantOrange,
      surface: card,
      background: background,
      error: destructive,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: foreground,
      onBackground: foreground,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: primaryBlue,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border.withOpacity(0.1)),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: muted,
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
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: mutedForeground, fontSize: 14),
      labelStyle: const TextStyle(color: mutedForeground, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: foreground,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: foreground,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: foreground,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mutedForeground,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedForeground,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryBlue,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedForeground,
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: vibrantOrange,
      surface: darkCard,
      background: darkBackground,
      error: destructive,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkForeground,
      onBackground: darkForeground,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkForeground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: vibrantOrange,
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: vibrantOrange,
        side: const BorderSide(color: vibrantOrange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkMuted,
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
        borderSide: const BorderSide(color: vibrantOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: darkMutedForeground, fontSize: 14),
      labelStyle: const TextStyle(color: darkMutedForeground, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: darkForeground,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: darkForeground,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: darkForeground,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkForeground,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkForeground,
      ),
      titleLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkForeground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkForeground,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkMutedForeground,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: darkMutedForeground,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: vibrantOrange,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: darkMutedForeground,
      ),
    ),
  );

  // Helper methods
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : background;

  static Color getCardColor(bool isDark) =>
      isDark ? darkCard : card;

  static Color getMutedColor(bool isDark) =>
      isDark ? darkMuted : muted;

  static Color getTextPrimary(bool isDark) =>
      isDark ? darkForeground : foreground;

  static Color getTextSecondary(bool isDark) =>
      isDark ? darkMutedForeground : mutedForeground;

  static Color getBorderColor(bool isDark) =>
      isDark ? darkBorder : border;

  // ===== COMMUNITY & CATEGORY COLORS =====
  
  // Community card colors (for lists/grids of communities)
  static const List<Color> communityCardColorsLight = [
    Color(0xFFFFF4EE), // Soft peach (light orange)
    Color(0xFFEFF7FF), // Light blue
    Color(0xFFF5F0FF), // Lavender mist
    Color(0xFFF0FFF4), // Mint cream
    Color(0xFFFFF9F0), // Light apricot
    Color(0xFFF0F8FF), // Alice blue
    Color(0xFFF8F0FF), // Pale lilac
    Color(0xFFF0FFF0), // Honeydew
    Color(0xFFFFF0F5), // Lavender blush
    Color(0xFFF0FFFF), // Azure mist
  ];

  // Dark theme variants (more muted for dark mode)
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

  // Light gradients for community cards
  static const List<LinearGradient> communityGradientsLight = [
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

  // Dark gradients for community cards
  static const List<LinearGradient> communityGradientsDark = [
    LinearGradient(
      colors: [Color(0xFF2A1F1A), Color(0xFF3A2F2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1A222A), Color(0xFF2A323A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF2A1F2A), Color(0xFF3A2F3A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF1A2A1F), Color(0xFF2A3A2F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF2A251A), Color(0xFF3A352A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // Helper method to get community card background color based on index
  static Color getCommunityCardColor(int index, bool isDark) {
    final colors = isDark ? communityCardColorsDark : communityCardColorsLight;
    return colors[index % colors.length];
  }

  // Helper method to get community card gradient based on index
  static LinearGradient getCommunityCardGradient(int index, bool isDark) {
    final gradients = isDark ? communityGradientsDark : communityGradientsLight;
    return gradients[index % gradients.length];
  }

  // ===== CATEGORY/TAG COLORS =====
  
  // Category tag background colors
  static const List<Color> categoryBackgroundColors = [
    Color(0xFFFFF0E8), // Orange tag background
    Color(0xFFE8F0FF), // Blue tag background
    Color(0xFFF0E8FF), // Purple tag background
    Color(0xFFE8FFF0), // Green tag background
    Color(0xFFFFF8E8), // Yellow tag background
    Color(0xFFF0F0FF), // Light indigo
    Color(0xFFFFF0F0), // Light pink
    Color(0xFFF0FFF8), // Light mint
  ];

  // Category tag text colors
  static const List<Color> categoryTextColors = [
    Color(0xFFB84B00), // Orange text
    Color(0xFF0066CC), // Blue text
    Color(0xFF7B1FA2), // Purple text
    Color(0xFF2E7D32), // Green text
    Color(0xFFEF6C00), // Orange-yellow text
    Color(0xFF5C6BC0), // Indigo text
    Color(0xFFE91E63), // Pink text
    Color(0xFF00BFA5), // Teal text
  ];

  // Dark mode variants
  static const List<Color> categoryBackgroundColorsDark = [
    Color(0xFF442E1A), // Dark orange
    Color(0xFF1A2E44), // Dark blue
    Color(0xFF3A1F44), // Dark purple
    Color(0xFF1A442E), // Dark green
    Color(0xFF443A1A), // Dark yellow
    Color(0xFF2A1F44), // Dark indigo
    Color(0xFF441A2E), // Dark pink
    Color(0xFF1A443A), // Dark teal
  ];

  static const List<Color> categoryTextColorsDark = [
    Color(0xFFFFB74D), // Light orange
    Color(0xFF64B5F6), // Light blue
    Color(0xFFBA68C8), // Light purple
    Color(0xFF81C784), // Light green
    Color(0xFFFFD54F), // Light yellow
    Color(0xFF7986CB), // Light indigo
    Color(0xFFF06292), // Light pink
    Color(0xFF4DB6AC), // Light teal
  ];

  // Helper method to get category/tag background color
  static Color getCategoryBackgroundColor(String category, bool isDark) {
    final colors = isDark ? categoryBackgroundColorsDark : categoryBackgroundColors;
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  // Helper method to get category/tag text color
  static Color getCategoryTextColor(String category, bool isDark) {
    final colors = isDark ? categoryTextColorsDark : categoryTextColors;
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  // ===== SWIPE CARD COLORS =====
  
  // Colors for swipeable cards (like in discovery or onboarding)
  static const List<Color> swipeCardColors = [
    Color(0xFFE0C0FF), // Light purple
    Color(0xFFC0FFD6), // Mint green
    Color(0xFFFFD6C0), // Peach
    Color(0xFFC0D6FF), // Light blue
    Color(0xFFFFF0C0), // Pale yellow
    Color(0xFFD6C0FF), // Periwinkle
    Color(0xFFFFC0E0), // Pink
    Color(0xFFC0FFF0), // Turquoise
    Color(0xFFE0FFC0), // Lime
    Color(0xFFFFE0C0), // Apricot
  ];

  // Helper method to get swipe card color
  static Color getSwipeCardColor(int index) {
    return swipeCardColors[index % swipeCardColors.length];
  }

  // ===== NOTIFICATION TYPE COLORS =====
  
  // Notification type colors for consistent theming
  static Color getNotificationTypeColor(String type, bool isDark) {
    switch (type) {
      // Success/Positive events - Green
      case 'CONTRIBUTION_RECEIVED':
      case 'CONTRIBUTION_CONFIRMED':
      case 'GOAL_ACHIEVED':
      case 'GROUP_GOAL_ACHIEVED':
      case 'MEMBER_APPROVED':
      case 'MEMBER_JOINED':
      case 'GROUP_STARTED':
      case 'SLOTS_COMPLETED':
      case 'PAYOUT_ALERT':
        return successGreen;

      // Warning/Attention events - Orange
      case 'CONTRIBUTION_REMINDER':
      case 'PAYMENT_MISSED':
      case 'UPCOMING_MEETING':
      case 'MEETING_SCHEDULED':
      case 'MEETING_REMINDER':
      case 'GOAL_PROGRESS':
      case 'WEEKLY_POLL_UPDATE':
        return vibrantOrange;

      // Urgent/Important events - Red
      case 'PAYMENT_OVERDUE':
      case 'SECURITY':
      case 'ADMIN_ANNOUNCEMENT':
      case 'MEMBER_REJECTED':
        return destructive;

      // Informational events - Blue
      case 'GROUP_UPDATE':
      case 'GROUP_DISBURSED':
      case 'MENTION':
      case 'SLOT_ASSIGNED':
      case 'group_message':
        return primaryBlue;

      // Neutral events - Purple
      case 'MEMBER_LEFT':
      case 'SYSTEM_ALERT':
      case 'WELCOME':
        return primaryPurple;

      // Default
      default:
        return isDark ? Colors.white70 : Colors.grey;
    }
  }
}