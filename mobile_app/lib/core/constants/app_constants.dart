class AppConstants {
  // App Info
  static const String appName = 'LocalLink';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Privacy-focused phone control';

  // Server Configuration
  static const int defaultPort = 8080;
  static const String defaultHost = '0.0.0.0';
  static const int serverTimeout = 30; // seconds

  // Storage Keys
  static const String keyServerPort = 'server_port';
  static const String keyAutoStart = 'auto_start';
  static const String keyAuthEnabled = 'auth_enabled';
  static const String keyThemeMode = 'theme_mode';

  // File Limits
  static const int maxFileSize = 500 * 1024 * 1024; // 500 MB
  static const int maxUploadChunkSize = 1024 * 1024; // 1 MB

  // UI Constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
