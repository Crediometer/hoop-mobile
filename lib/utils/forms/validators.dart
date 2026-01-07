// lib/utils/validators.dart
class Validators {
  // Required field validator
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validator
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    return null;
  }

  // Strong password validator
  static String? strongPassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Phone number validator
  static String? phoneNumber(String? value, {String? countryCode}) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Basic phone validation (adjust for your country)
    if (digits.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Confirm password validator
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Minimum length validator
  static String? minLength(String? value, int min, {String fieldName = 'Field'}) {
    if (value == null || value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  // Maximum length validator
  static String? maxLength(String? value, int max, {String fieldName = 'Field'}) {
    if (value != null && value.length > max) {
      return '$fieldName must be less than $max characters';
    }
    return null;
  }

  // Numeric validator
  static String? numeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    
    return null;
  }

  // Integer validator
  static String? integer(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (int.tryParse(value) == null) {
      return '$fieldName must be a whole number';
    }
    
    return null;
  }

  // URL validator
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?' // protocol
      r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|' // domain name
      r'((\d{1,3}\.){3}\d{1,3}))' // OR ip (v4) address
      r'(\:\d+)?' // port
      r'(\/[-a-z\d%_.~+]*)*' // path
      r'(\?[;&a-z\d%_.~+=-]*)?' // query string
      r'(\#[-a-z\d_]*)?$', // fragment locator
      caseSensitive: false,
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Date validator (YYYY-MM-DD format)
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter date in YYYY-MM-DD format';
    }
    
    try {
      DateTime.parse(value);
    } catch (e) {
      return 'Please enter a valid date';
    }
    
    return null;
  }

  // Age restriction validator (minimum age)
  static String? minimumAge(String? value, int minAge) {
    final dateError = date(value);
    if (dateError != null) {
      return dateError;
    }
    
    final birthDate = DateTime.parse(value!);
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    if (age < minAge) {
      return 'You must be at least $minAge years old';
    }
    
    return null;
  }

  // Credit card number validator (Luhn algorithm)
  static String? creditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length < 13 || digits.length > 19) {
      return 'Invalid card number length';
    }
    
    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    if (sum % 10 != 0) {
      return 'Invalid card number';
    }
    
    return null;
  }

  // CVV validator
  static String? cvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }
    
    return null;
  }

  // Expiry date validator (MM/YY format)
  static String? expiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    if (!RegExp(r'^\d{2}\/\d{2}$').hasMatch(value)) {
      return 'Please use MM/YY format';
    }
    
    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Invalid date';
    }
    
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }
    
    return null;
  }

  // Custom regex validator
  static String? pattern(String? value, RegExp pattern, {String errorMessage = 'Invalid format'}) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }
    
    if (!pattern.hasMatch(value)) {
      return errorMessage;
    }
    
    return null;
  }

  // Compose multiple validators
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }
}