import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:medicine_reminder_system/screens/splash_screen.dart';
import 'package:medicine_reminder_system/screens/login_screen.dart';
import 'package:medicine_reminder_system/screens/register_screen.dart';
import 'package:medicine_reminder_system/screens/home_screen.dart';
import 'package:medicine_reminder_system/screens/forgot_password_screen.dart';
import 'package:medicine_reminder_system/screens/otp_verification_screen.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/notification_service.dart';

// 1. Define the GlobalKey here
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the notification service right at startup
  await NotificationService.initializeNotifications();

  // ✅ Ensure Firebase initialized properly on Web & Mobile
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: kIsWeb
          ? DefaultFirebaseOptions.web
          : DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MediMateApp());
}

class MediMateApp extends StatelessWidget {
  const MediMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'MediMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        ),
        home: const SplashScreen(),
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
