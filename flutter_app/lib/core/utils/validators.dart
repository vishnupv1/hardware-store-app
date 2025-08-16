import '../constants/app_constants.dart';

/// Utility class for form validation
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (!AppConstants.emailRegex.hasMatch(value)) {
      return AppConstants.invalidEmailMessage;
    }
    
    if (value.length > AppConstants.maxEmailLength) {
      return 'Email must be less than ${AppConstants.maxEmailLength} characters.';
    }
    
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long.';
    }
    
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters.';
    }
    
    if (!AppConstants.passwordRegex.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value != password) {
      return 'Passwords do not match.';
    }
    
    return null;
  }

  /// Validates username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value.length < AppConstants.minUsernameLength) {
      return 'Username must be at least ${AppConstants.minUsernameLength} characters long.';
    }
    
    if (value.length > AppConstants.maxUsernameLength) {
      return 'Username must be less than ${AppConstants.maxUsernameLength} characters.';
    }
    
    // Username should only contain alphanumeric characters, underscores, and hyphens
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens.';
    }
    
    return null;
  }

  /// Validates full name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value.length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters.';
    }
    
    // Name should only contain letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes.';
    }
    
    return null;
  }

  /// Validates first or last name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters long.';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters.';
    }
    
    // Name should only contain letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes.';
    }
    
    return null;
  }

  /// Validates phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove all non-digit characters for validation
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length < 10 || cleanValue.length > 15) {
      return 'Please enter a valid phone number.';
    }
    
    return null;
  }

  /// Validates phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (!AppConstants.phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number.';
    }
    
    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Validates minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters long.';
    }
    return null;
  }

  /// Validates maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters.';
    }
    return null;
  }

  /// Validates URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL.';
    }
    
    return null;
  }

  /// Validates numeric value
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number.';
    }
    
    return null;
  }

  /// Validates positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericValidation = validateNumeric(value, fieldName);
    if (numericValidation != null) {
      return numericValidation;
    }
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0.';
    }
    
    return null;
  }

  /// Validates age (must be between 13 and 120)
  static String? validateAge(String? value) {
    final numericValidation = validateNumeric(value, 'Age');
    if (numericValidation != null) {
      return numericValidation;
    }
    
    final age = int.parse(value!);
    if (age < 13 || age > 120) {
      return 'Age must be between 13 and 120.';
    }
    
    return null;
  }

  /// Validates date of birth (must be in the past and reasonable)
  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required.';
    }
    
    final now = DateTime.now();
    final age = now.year - value.year - (now.month < value.month || (now.month == value.month && now.day < value.day) ? 1 : 0);
    
    if (age < 13) {
      return 'You must be at least 13 years old.';
    }
    
    if (age > 120) {
      return 'Please enter a valid date of birth.';
    }
    
    if (value.isAfter(now)) {
      return 'Date of birth cannot be in the future.';
    }
    
    return null;
  }

  /// Validates file size
  static String? validateFileSize(int fileSize, int maxSize) {
    if (fileSize > maxSize) {
      final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(1);
      return 'File size must be less than ${maxSizeMB}MB.';
    }
    return null;
  }

  /// Validates image file type
  static String? validateImageType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) {
      return 'Please select a valid image file.';
    }
    
    if (!AppConstants.allowedImageTypes.contains(mimeType.toLowerCase())) {
      return 'Please select a valid image file (JPEG, PNG, or WebP).';
    }
    
    return null;
  }

  /// Validates credit card number (basic Luhn algorithm)
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    // Remove spaces and dashes
    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Please enter a valid credit card number.';
    }
    
    // Check length (most cards are 13-19 digits)
    if (cleanValue.length < 13 || cleanValue.length > 19) {
      return 'Please enter a valid credit card number.';
    }
    
    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanValue.length - 1; i >= 0; i--) {
      int n = int.parse(cleanValue[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    
    if (sum % 10 != 0) {
      return 'Please enter a valid credit card number.';
    }
    
    return null;
  }

  /// Validates CVV
  static String? validateCvv(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'Please enter a valid CVV (3-4 digits).';
    }
    
    return null;
  }

  /// Validates expiration date
  static String? validateExpirationDate(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.requiredFieldMessage;
    }
    
    // Expected format: MM/YY or MM/YYYY
    final regex = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2}|[0-9]{4})$');
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid expiration date (MM/YY or MM/YYYY).';
    }
    
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    
    final now = DateTime.now();
    final currentYear = now.year % 100; // Last two digits
    final currentMonth = now.month;
    
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired.';
    }
    
    return null;
  }
}
