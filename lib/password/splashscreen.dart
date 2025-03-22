import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ledger/password/pin_verify.dart';
import '../ADD/home.dart';
import '../ADD/reminder.dart';
import '../main.dart'; // For access to initialNotificationPayload
import '../DataBase/sharedpreferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _showSplashScreen();
  }

  Future<void> _showSplashScreen() async {
    await Future.delayed(const Duration(seconds: 1));

    String? savedPin = await SharedPreferenceHelper.get(prefKey: PrefKey.pin);

    if (savedPin != null && savedPin.isNotEmpty) {
      // ✅ Navigate to PIN screen, then decide where to go
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyPinScreen(
            onSuccess: () {
              _navigateAfterPin();
            },
          ),
        ),
      );
    } else {
      // ✅ No PIN: go to ReminderPage if notification tapped
      _navigateAfterPin();
    }
  }

  void _navigateAfterPin() {
    if (initialNotificationPayload == 'reminder') {
      initialNotificationPayload = null; // clear payload after use

      // ✅ First go to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );

      // ✅ Then push ReminderPage on top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReminderPage()),
        );
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/logo.png',
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
