import 'package:flutter/material.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart'; // Import the package

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkBackgroundColor = Color(0xFF1A1A1D);
    const Color textColor = Colors.white;
    const Color accentColor = Color(0xFFEF6A6A);

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- Close Button ---
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: textColor, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(flex: 1),

                // --- Reminder Details ---
                const Icon(Icons.notifications_active,
                    color: accentColor, size: 40),
                const SizedBox(height: 20),
                const Text(
                  'Dolo 650',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'DAY 01',
                  style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 18,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 40),

                // --- Pill Image ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Image.asset(
                    'assets/pill_icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 40),

                // --- Time and Instructions ---
                const Text(
                  '08 : 00 AM',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Take 1 Pill',
                  style: TextStyle(color: textColor, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Before Breakfast',
                  style: TextStyle(
                      color: textColor.withOpacity(0.7), fontSize: 18),
                ),
                const Spacer(flex: 1),

                // --- Swipe to Stop Button ---
                ConfirmationSlider(
                  onConfirmation: () {
                    // TODO: Add logic for stopping the reminder
                    Navigator.pop(context);
                  },
                  text: 'Swipe to Stop',
                  textStyle:
                      const TextStyle(fontSize: 16, color: Colors.black87),
                  backgroundColor: Colors.white,
                  foregroundColor: accentColor,
                  iconColor: Colors.white,
                  sliderButtonContent:
                      const Icon(Icons.check, color: Colors.white),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
