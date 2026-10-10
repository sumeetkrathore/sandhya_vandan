import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

import '../models/program.dart';

import 'notification_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Could not set local timezone: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: DarwinInitializationSettings(),
        );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint(
          "Local notification clicked: payload=${response.payload}, actionId=${response.actionId}",
        );
        NotificationRouter().routeFromLocalPayload(response.payload);
      },
    );

    // Check if the app was launched by tapping a local notification
    try {
      final launchDetails = await notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        debugPrint(
          "App launched via local notification: ${launchDetails.notificationResponse!.payload}",
        );
        NotificationRouter().routeFromLocalPayload(
          launchDetails.notificationResponse!.payload,
        );
      }
    } catch (e) {
      debugPrint("Error checking notification launch details: $e");
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  Future<void> scheduleSandhyaReminder() async {
    if (!_isInitialized) await init();

    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('dailyReminderTime') ?? '19:45';
    final parts = timeStr.split(':');
    int hour = 19;
    int minute = 45;
    if (parts.length == 2) {
      hour = int.tryParse(parts[0]) ?? 19;
      minute = int.tryParse(parts[1]) ?? 45;
    }

    await notificationsPlugin.zonedSchedule(
      0, // ID 0 for Sandhya Reminder
      'Sandhya Vandan Nem',
      "It is time for your Sandhya Vandan nem. Dedicate this moment to Satguru's Dhyan and Ustati.",
      _nextInstanceOfTime(hour, minute), // Dynamic time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sandhya_vandan_nem',
          'Sandhya Reminders',
          channelDescription: 'Daily evening Sandhya Vandan reminders',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            "It is time for your Sandhya Vandan nem. Dedicate this moment to Satguru's Dhyan and Ustati.",
            contentTitle: 'Sandhya Vandan Nem',
          ),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '{"type":"nem"}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    debugPrint("Scheduled Sandhya reminder for $timeStr.");
  }

  Future<void> scheduleEventReminders(List<Program> programs) async {
    if (!_isInitialized) await init();

    final now = tz.TZDateTime.now(tz.local);

    for (final program in programs) {
      if (program.startDate.isEmpty) continue;

      try {
        final parsedDate = DateTime.parse(program.startDate);

        // 3 days prior, 1 day prior, and day of (0)
        final offsets = [3, 1, 0];
        for (final offset in offsets) {
          // Evening (6:00 PM) for 3-days and 1-day prior. Morning (9:00 AM) for Day Of.
          int hour = (offset == 0) ? 9 : 18;
          int minute = 0;

          final eventDateLocal = tz.TZDateTime(
            tz.local,
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            hour,
            minute,
          );
          final reminderDate = eventDateLocal.subtract(Duration(days: offset));

          // Only schedule if the reminder date is in the future
          if (reminderDate.isAfter(now)) {
            // Create a deterministic ID based on program ID and offset
            final notificationId =
                (program.id.hashCode.abs() % 100000) * 10 + offset;

            String title = 'Upcoming Event: ${program.title}';
            String body = '';
            if (offset == 0) {
              body = 'The event is happening today! Tap to see details.';
            } else if (offset == 1) {
              body = 'The event is happening tomorrow. Tap to see details.';
            } else {
              body =
                  'The event is happening in $offset days. Tap to see details.';
            }

            await notificationsPlugin.zonedSchedule(
              notificationId,
              title,
              body,
              reminderDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'event_reminders_channel',
                  'Event Reminders',
                  channelDescription:
                      'Automated reminders for upcoming programs',
                  importance: Importance.max,
                  priority: Priority.high,
                  largeIcon: DrawableResourceAndroidBitmap(
                    '@mipmap/ic_launcher',
                  ),
                ),
                iOS: DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        }
      } catch (e) {
        debugPrint("Error scheduling reminder for program ${program.id}: $e");
      }
    }
    debugPrint("Scheduled event reminders successfully.");
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await init();
    await notificationsPlugin.cancelAll();
    debugPrint("Cancelled all daily reminders.");
  }

  Future<void> showTestNotification() async {
    if (!_isInitialized) await init();

    await notificationsPlugin.show(
      99, // Unique ID for test notification
      'Test Notification',
      'This is how your daily reminders will look!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Used for testing notifications',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(
            'This is how your daily reminders will look! Testing multi-line text to ensure it expands nicely on your device.',
            contentTitle: 'Test Notification',
          ),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint("Sent test notification.");
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
