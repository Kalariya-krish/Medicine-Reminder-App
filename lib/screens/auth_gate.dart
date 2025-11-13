// In a file named: lib/screens/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicine_reminder_system/screens/home_screen.dart';
import '../screens/onboarding_screen.dart'; // Path to your OnboardingScreen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to the user's authentication state in real-time
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Connection is still active (checking status)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a simple loading screen while Firebase initializes
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. User is logged in (User object is NOT null)
        if (snapshot.hasData && snapshot.data != null) {
          // Send user directly to the home screen
          return const HomeScreen(); // MainScreen typically holds the bottom navigation bar
        }

        // 3. User is NOT logged in (User object IS null)
        // Send user to the Onboarding/Login flow
        return const OnboardingScreen();
      },
    );
  }
}
