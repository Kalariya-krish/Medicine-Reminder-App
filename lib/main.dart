import 'package:flutter/material.dart';
import 'package:medicine_reminder_system/screens/forgot_password_screen.dart';
import 'package:medicine_reminder_system/screens/home_screen.dart';
import 'package:medicine_reminder_system/screens/otp_verification_screen.dart';
import 'package:medicine_reminder_system/screens/splash_screen.dart';
import 'package:medicine_reminder_system/screens/login_screen.dart';
import 'package:medicine_reminder_system/screens/register_screen.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(const MediMateApp());
}

class MediMateApp extends StatelessWidget {
  const MediMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MediMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        ),
        home: const SplashScreen(), // starting screen
        routes: {
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/forgetpassword': (context) => const ForgetPasswordScreen(),
          '/otpverification': (context) => const VerifyOtpScreen(),
        },
      ),
    );
  }
}
