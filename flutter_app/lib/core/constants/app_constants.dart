/// Application constants used throughout the app
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Information
  static const String appName = 'Hardware Store Manager';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Complete hardware wholesale store management system';

  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = '/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiRetryDelay = Duration(seconds: 2);
  static const int maxRetries = 3;

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/user/profile';
  static const String usersEndpoint = '/users';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String onboardingKey = 'onboarding_completed';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  static const double defaultRadius = 8.0;
  static const double smallRadius = 4.0;
  static const double largeRadius = 12.0;
  static const double extraLargeRadius = 16.0;

  static const double defaultElevation = 2.0;
  static const double smallElevation = 1.0;
  static const double largeElevation = 4.0;

  // Validation Constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxEmailLength = 254;
  static const int maxNameLength = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  // Error Messages
  static const String networkErrorMessage = 'Network error occurred. Please check your connection.';
  static const String serverErrorMessage = 'Server error occurred. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  static const String emailAlreadyExistsMessage = 'Email already exists.';
  static const String weakPasswordMessage = 'Password is too weak.';
  static const String invalidEmailMessage = 'Please enter a valid email address.';
  static const String requiredFieldMessage = 'This field is required.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registerSuccessMessage = 'Registration successful!';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully!';
  static const String passwordChangeSuccessMessage = 'Password changed successfully!';

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  static final RegExp phoneRegex = RegExp(
    r'^\+?[\d\s-()]+$',
  );

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

  // Localization
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de'];

  // Currency
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enablePushNotifications = true;
  static const bool enableBiometricAuth = true;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration shortCacheExpiration = Duration(minutes: 30);
  static const Duration longCacheExpiration = Duration(days: 7);

  // Deep Links
  static const String deepLinkScheme = 'flutterapp';
  static const String deepLinkHost = 'example.com';
}
