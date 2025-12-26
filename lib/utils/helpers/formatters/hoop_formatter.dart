// lib/utils/formatters.dart
import 'dart:math';
import 'package:intl/intl.dart';

class HoopFormatters {
  // ========== CURRENCY FORMATTING ==========
  
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 1,
  );

  static String formatCurrency(double amount, {bool compact = false}) {
    if (compact && amount >= 1000) {
      return _compactCurrencyFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatCurrencyWithoutSymbol(double amount, {bool compact = false}) {
    final formatted = formatCurrency(amount, compact: compact);
    return formatted.replaceFirst('\$', '');
  }

  static String formatCompactNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  // ========== DATE & TIME FORMATTING ==========
  
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _relativeDateFormat = DateFormat('EEE, dd MMM');

  static String formatDate(DateTime date, {String? pattern}) {
    if (pattern != null) {
      return DateFormat(pattern).format(date);
    }
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  static String formatRelativeDate(DateTime date) {
    return _relativeDateFormat.format(date);
  }

  static String formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }

  // ========== TEXT FORMATTING ==========
  
  static String getInitials(String name, {int maxLength = 2}) {
    if (name.isEmpty) return '??';
    
    final parts = name.trim().split(' ');
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(maxLength)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    
    return initials.isNotEmpty ? initials : '??';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  static String truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  // ========== PHONE NUMBER FORMATTING ==========
  
  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone;
  }

  static String maskPhoneNumber(String phone) {
    if (phone.length < 6) return phone;
    final masked = '*' * (phone.length - 4) + phone.substring(phone.length - 4);
    return formatPhoneNumber(masked);
  }

  // ========== EMAIL FORMATTING ==========
  
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '${'*' * username.length}@$domain';
    }
    
    final firstChar = username[0];
    final lastChar = username[username.length - 1];
    final maskedMiddle = '*' * (username.length - 2);
    
    return '$firstChar$maskedMiddle$lastChar@$domain';
  }

  // ========== FILE SIZE FORMATTING ==========
  
  static String formatFileSize(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // ========== PERCENTAGE FORMATTING ==========
  
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  static String formatPercentageChange(double change, {bool withSign = true}) {
    final formatted = '${(change * 100).toStringAsFixed(1)}%';
    if (!withSign) return formatted;
    
    if (change > 0) return '+$formatted';
    if (change < 0) return formatted;
    return formatted;
  }

  // ========== SOCIAL MEDIA FORMATTING ==========
  
  static String formatSocialCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 10000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // ========== TIME & DURATION ==========
  
  static String formatSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${remainingSeconds.toString().padLeft(2, '0')}';
    }
    
    return '${minutes.toString().padLeft(2, '0')}:'
           '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ========== VALIDATION HELPERS ==========
  
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    ).hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  static bool isValidPassword(String password) {
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  // ========== COLOR FORMATTING ==========
  
  static String getHexColor(int color) {
    return '#${color.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static String rgbToHex(int r, int g, int b) {
    return '#${((1 << 24) + (r << 16) + (g << 8) + b).toRadixString(16).substring(1).toUpperCase()}';
  }

  // ========== TEXT STYLING HELPERS ==========
  
  static String wrapWithSpan(String text, String style) {
    return '<span style="$style">$text</span>';
  }

  static String highlightText(String text, String query) {
    if (query.isEmpty) return text;
    
    final pattern = RegExp(query, caseSensitive: false);
    return text.replaceAllMapped(pattern, (match) {
      return '<mark>${match.group(0)}</mark>';
    });
  }

  // ========== URL & LINKS ==========
  
  static String ensureHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    if (!url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  static String getUrlDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  // ========== ARRAY/LIST FORMATTING ==========
  
  static String joinListWithOxfordComma(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    
    final allButLast = items.sublist(0, items.length - 1).join(', ');
    return '$allButLast, and ${items.last}';
  }

  static String formatListAsBullets(List<String> items, {String bullet = '•'}) {
    return items.map((item) => '$bullet $item').join('\n');
  }

  // ========== RANDOM GENERATORS ==========
  
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static String generateId({String prefix = '', int length = 8}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = generateRandomString(length);
    return prefix.isNotEmpty ? '$prefix-$timestamp-$random' : '$timestamp-$random';
  }

  // ========== SPECIALIZED FORMATTING ==========
  
  static String formatOrdinal(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  static String formatCreditCard(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) return cardNumber;
    
    return '${digits.substring(0, 4)} '
           '${digits.substring(4, 8)} '
           '${digits.substring(8, 12)} '
           '${digits.substring(12)}';
  }

  static String maskCreditCard(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) return cardNumber;
    
    return '**** **** **** ${digits.substring(12)}';
  }
}