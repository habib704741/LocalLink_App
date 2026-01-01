class AppConstants {
  // App Info
  static const String appName = 'LocalLink';
  static const String appVersion = '1.0.0';

  // Connection
  static const int connectionTimeout = 10; // seconds
  static const int retryAttempts = 3;

  // Storage Keys
  static const String keyLastConnectedIp = 'last_connected_ip';
  static const String keyAutoConnect = 'auto_connect';

  // UI Constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
}
