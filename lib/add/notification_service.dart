import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../ADD/reminder.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (Platform.isAndroid && await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  static Future<void> initializeNotification(BuildContext? context) async {
    await _initializeTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'reminder_channel',
            'Reminders',
            description: 'Daily due reminders',
            importance: Importance.max, // Ensure High Priority
            playSound: true,
          ),
        );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (context != null && response.payload == 'reminder') {
          _navigateToReminderPage(context);
        }
      },
    );
  }

  static Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  static void _navigateToReminderPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReminderPage()),
    );
  }

  static Future<void> scheduleDailyReminderNotification(
      List<Map<String, dynamic>> dueReminders,
      {int hour = 11,
      int minute = 45}) async {
    if (dueReminders.isEmpty) return;

    await _initializeTimeZone();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    debugPrint("🕒 Current Time: $now");

    debugPrint("📅 Corrected Scheduled Time: $scheduledTime");

    final reminderDetails = dueReminders.take(5).map((tx) {
      return "${tx['account_name']}: ₹${tx['transaction_amount']}";
    }).join("\n");

    const int notificationId = 9999;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Today\'s Due Reminders',
      reminderDetails,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          channelDescription: 'Daily due reminders at scheduled time',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder',
    );
  }

  static Future<void> showImmediateNotification(
      List<Map<String, dynamic>> dueReminders) async {
    final reminderDetails = dueReminders.take(5).map((tx) {
      return "${tx['account_name']}: ₹${tx['transaction_amount']}";
    }).join("\n");

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _notificationsPlugin.show(
      notificationId,
      'Immediate Reminder',
      reminderDetails,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Notifications',
          channelDescription: 'Immediate reminder alert',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: 'reminder',
    );
  }
}
