import 'package:flutter/material.dart';
import 'package:ledger/password/splashscreen.dart';
import 'package:provider/provider.dart';
import 'package:ledger/ADD/home.dart';
import 'package:ledger/settings/currencymanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final currencyManager = CurrencyManager();
  await currencyManager.loadCurrency(); // Load saved currency from SharedPreferences

  runApp(
    ChangeNotifierProvider<CurrencyManager>.value(
      value: currencyManager,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
