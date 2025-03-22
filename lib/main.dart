import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ledger/settings/currencymanager.dart';
import 'ADD/notification_service.dart';
import 'DataBase/database_helper.dart';
import 'password/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request(); // Request permission early

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

      // ✅ New: Schedule today's reminder notification at 9:00 AM
      final db = DatabaseHelper.instance;
      final today = DateTime.now();
      final allReminders = await db.getReminderTransactions();

      final todayReminders = allReminders.where((tx) {
        final date = DateTime.parse(tx['reminder_date']);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      }).toList();

      await NotificationService.scheduleDailyReminderNotification(
        todayReminders,
        hour: 9,
        minute: 0,
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
      home: SplashScreen(),
    );
  }
}
