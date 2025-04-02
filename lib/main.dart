import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ledger/settings/currencymanager.dart';
import 'ADD/notification_service.dart';
import 'DataBase/database_helper.dart';
import 'password/splashscreen.dart';

String? initialNotificationPayload;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();
  await Permission.scheduleExactAlarm.request();

  runApp(
    ChangeNotifierProvider(
      create: (_) => CurrencyManager(),
      child: const MyApp(),
    ),
  );

  Future.delayed(Duration.zero, () async {
    await NotificationService.initializeNotification(null);
    final db = DatabaseHelper.instance;
    final today = DateTime.now();
    final allReminders = await db.getReminderTransactions();
    final todayReminders = allReminders.where((tx) {
      final rawDate = tx['reminder_date'];
      if (rawDate == null || rawDate.toString().trim().isEmpty) return false;

      try {
        final date = DateTime.parse(rawDate);
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
      hour: 11, // Change to your preferred time
      minute: 45,
    );
  });
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

      final launchDetails = await NotificationService.getLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        initialNotificationPayload = launchDetails!.notificationResponse?.payload;
      }
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




// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'package:ledger/settings/currencymanager.dart';
// import 'ADD/notification_service.dart';
// import 'DataBase/database_helper.dart';
// import 'color/my_theme.dart';
// import 'color/theme_controlloer.dart';
// import 'password/splashscreen.dart';
//
// String? initialNotificationPayload;
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Request required permissions
//   await Permission.notification.request();
//   await Permission.scheduleExactAlarm.request();
//
//   // Ensure ThemeController is registered before GetMaterialApp runs
//   Get.put(ThemeController());
//
//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => CurrencyManager(),
//       child: const MyApp(),
//     ),
//   );
//
//   Future.delayed(Duration.zero, () async {
//     await NotificationService.initializeNotification(null);
//
//     final db = DatabaseHelper.instance;
//     final today = DateTime.now();
//     final allReminders = await db.getReminderTransactions();
//
//     final todayReminders = allReminders.where((tx) {
//       final rawDate = tx['reminder_date'];
//       if (rawDate == null || rawDate.toString().trim().isEmpty) return false;
//
//       try {
//         final date = DateTime.parse(rawDate);
//         return date.year == today.year &&
//             date.month == today.month &&
//             date.day == today.day;
//       } catch (e) {
//         print("Invalid reminder_date: $rawDate");
//         return false;
//       }
//     }).toList();
//
//     await NotificationService.scheduleDailyReminderNotification(
//       todayReminders,
//       hour: 11, // Change to your preferred time
//       minute: 45,
//     );
//   });
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration.zero, () async {
//       await NotificationService.initializeNotification(context);
//
//       final launchDetails = await NotificationService.getLaunchDetails();
//       if (launchDetails?.didNotificationLaunchApp ?? false) {
//         initialNotificationPayload = launchDetails!.notificationResponse?.payload;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Retrieve ThemeController instance
//     final ThemeController controller = Get.find<ThemeController>();
//
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Ledger Book',
//       theme: lightTheme,
//       darkTheme: darkTheme,
//       themeMode: controller.isDark.value ? ThemeMode.dark : ThemeMode.light,
//       home: SplashScreen(),
//     );
//   }
// }
