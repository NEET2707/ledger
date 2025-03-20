import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ledger/password/pin_verify.dart';
import '../ADD/home.dart';
import '../main.dart';
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
    await Future.delayed(Duration(seconds: 1));

    String? savedPin = await SharedPreferenceHelper.get(prefKey: PrefKey.pin);

    if (savedPin != null && savedPin.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerifyPinScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()), // Go to home directly if PIN not set
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
              'assets/image/logo.png', // Path to your logo image
              width: 150, // Adjust the size if needed
              height: 150, // Adjust the size if needed
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
