class AppConstants {
  AppConstants._();

  // ── App Info ───────────────────────────────────────────────
  static const String appName = 'HISP Mobile Tracker';
  static const String appVersion = '1.0.0';

  // ── Storage Keys ───────────────────────────────────────────
  static const String keyAuthToken = 'auth_token';
  static const String keyUsername = 'username';
  static const String keyBaseUrl = 'base_url';
  // static const String keyBaseUrl = 'http://192.168.100.149:8081/me';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserData = 'user_data';

  // ── Validation ─────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 50;

  // ── Animation Durations ────────────────────────────────────
  static const int animFast = 150;
  static const int animNormal = 250;
  static const int animSlow = 400;
  static const int animVerySlow = 600;
}
