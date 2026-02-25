// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../controllers/auth_controller.dart';
import 'home_view.dart';
import 'login_view.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  // Navigate to the appropriate screen after a delay
  void _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 7));

    try {
      // Check for internet connectivity
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Check if the user is logged in
        final isLoggedIn = authController.firebaseUser.value != null;

        // Navigate to the appropriate screen
        if (isLoggedIn) {
          Get.off(() => HomeView());
        } else {
          Get.off(() => LoginView());
        }
      }
    } on SocketException catch (_) {
      // Handle offline scenario
      Get.snackbar(
        'No Internet Connection',
        'Please check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            CircleAvatar(
              backgroundImage: AssetImage("assets/logo.png"),
              radius: 50,
            ),
            SizedBox(height: 16),
            // App Name
            Text(
              'korlinks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            // Loading Indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
