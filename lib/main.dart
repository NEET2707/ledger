import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ledger/settings/currencymanager.dart';
import 'ADD/notification_service.dart';
import 'DataBase/database_helper.dart';
import 'password/splashscreen.dart';

String? initialNotificationPayload; // ✅ Store payload globally

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request(); // Request early permission

  runApp(
    ChangeNotifierProvider(
      create: (_) => CurrencyManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await NotificationService.initializeNotification(context);

      // ✅ Store launch payload if app was opened via notification
      final launchDetails = await NotificationService.getLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        initialNotificationPayload =
            launchDetails!.notificationResponse?.payload;
      }

      // ✅ Schedule today's reminders
      final db = DatabaseHelper.instance;
      final today = DateTime.now();
      final allReminders = await db.getReminderTransactions();
      final todayReminders = allReminders.where((tx) {
        final rawDate = tx['reminder_date'];
        if (rawDate == null || rawDate.toString().trim().isEmpty) return false;

        try {
          final date = DateTime.parse(rawDate);
          final today = DateTime.now();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        } catch (e) {
          print("Invalid reminder_date: $rawDate");
          return false;
        }
      }).toList();

      await NotificationService.scheduleDailyReminderNotification(
        todayReminders,
        hour: 13,
        minute: 52,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledger Book',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // App will start here
    );
  }
}
