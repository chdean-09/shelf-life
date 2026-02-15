import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/pantry_item.dart';
import '../utils/constants.dart';
import 'database_service.dart';

/// Service for scheduling local notifications for expiring items.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  /// Initialize the notification system.
  Future<void> initialize() async {
    // Initialize timezone database
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on Android 13+
    await _requestPermissions();
  }

  /// Request notification permissions.
  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Handle notification tap.
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigate to the item detail screen — handled by the app
  }

  /// Schedule expiry reminders for items expiring within 3 days.
  Future<void> scheduleExpiryReminders() async {
    // Cancel all existing notifications
    await _notifications.cancelAll();

    final db = DatabaseService();
    final items = await db.getExpiringSoon(days: 3);

    for (var item in items) {
      await _scheduleReminder(item);
    }

    debugPrint(
        'NotificationService: Scheduled ${items.length} expiry reminders');
  }

  /// Schedule a single reminder for an item.
  Future<void> _scheduleReminder(PantryItem item) async {
    final daysLeft = item.daysUntilExpiry;
    final String body;

    if (daysLeft <= 0) {
      body = '${item.name} has expired! Consider using or discarding it.';
    } else if (daysLeft == 1) {
      body = '${item.name} expires tomorrow!';
    } else {
      body = '${item.name} expires in $daysLeft days';
    }

    const androidDetails = AndroidNotificationDetails(
      AppConstants.expiryChannelId,
      AppConstants.expiryChannelName,
      channelDescription: AppConstants.expiryChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Show immediately for already-expired or expiring-today items
    if (daysLeft <= 0) {
      await _notifications.show(
        item.id,
        'Item Expired!',
        body,
        details,
        payload: item.id.toString(),
      );
    } else {
      // Schedule for 9 AM the day before expiry
      final scheduledDate = DateTime(
        item.expiryDate.year,
        item.expiryDate.month,
        item.expiryDate.day - 1,
        9, // 9 AM
        0,
      );

      // Only schedule future notifications
      if (scheduledDate.isAfter(DateTime.now())) {
        await _notifications.zonedSchedule(
          item.id,
          'Item Expiring Soon!',
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.id.toString(),
        );
      } else {
        // If the scheduled time has passed, show now
        await _notifications.show(
          item.id,
          'Item Expiring Soon!',
          body,
          details,
          payload: item.id.toString(),
        );
      }
    }
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
