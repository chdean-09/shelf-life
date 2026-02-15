class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // For Android emulator, use: http://10.0.2.2:8080/api/v1
  // For iOS simulator, use: http://localhost:8080/api/v1
  // For physical device, use: http://YOUR_COMPUTER_IP:8080/api/v1
}

class AppConstants {
  static const String appName = 'ShelfLife';
  static const String appTagline = 'Stop Hoarding. Start Saving.';

  // Expiry urgency thresholds (in days)
  static const int urgentDays = 3;
  static const int warningDays = 7;

  // Sync interval (in minutes)
  static const int syncIntervalMinutes = 15;

  // Notification channel
  static const String expiryChannelId = 'expiry_channel';
  static const String expiryChannelName = 'Expiry Alerts';
  static const String expiryChannelDescription =
      'Notifications for items expiring soon';

  // Secure storage keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
}
