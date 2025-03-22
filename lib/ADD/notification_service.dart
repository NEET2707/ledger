import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../ADD/reminder.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  static Future<void> initializeNotification(BuildContext context) async {
    await _initializeTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'reminder_channel',
            'Reminders',
            description: 'Daily due reminders',
            importance: Importance.max,
          ),
        );

    await _notificationsPlugin.initialize(
      initSettings,
      // onDidReceiveNotificationResponse: (response) {
      //   if (response.payload == 'reminder') {
      //     _navigateToReminderPage(context);
      //   }
      // },
    );

    // final launchDetails =
    // await _notificationsPlugin.getNotificationAppLaunchDetails();
    // if (launchDetails?.didNotificationLaunchApp ?? false) {
    //   if (launchDetails!.notificationResponse?.payload == 'reminder') {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       _navigateToReminderPage(context);
    //     });
    //   }
    // }
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
    List<Map<String, dynamic>> dueReminders, {
    int hour = 9,
    int minute = 0,
  }) async {
    if (dueReminders.isEmpty) {
      return;
    }

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

    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

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
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      // uiLocalNotificationDateInterpretation:
      // UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder',
    );
  }

  static Future<void> showImmediateNotification(
      List<Map<String, dynamic>> dueReminders) async {
    final reminderDetails = dueReminders.take(5).map((tx) {
      return "${tx['account_name']}: ₹${tx['transaction_amount']}";
    }).join("\n");

    final int notificationId = DateTime.now().millisecondsSinceEpoch % 10000;

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
        ),
      ),
      payload: 'reminder',
    );
  }
}
