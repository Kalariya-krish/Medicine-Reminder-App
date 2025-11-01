// In lib/screens/reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW
import 'package:intl/intl.dart'; // NEW
import '../models/medicine.dart';

class ReminderScreen extends StatefulWidget {
  final Medicine medicine;
  final String alarmTime;

  const ReminderScreen(
      {super.key, required this.medicine, required this.alarmTime});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  // Function to log a record to Firestore history collection
  Future<void> _logHistory(String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .add({
      'medicineId': widget.medicine.id,
      'name': widget.medicine.name,
      'dosage': widget.medicine.dosage,
      'time': widget.alarmTime,
      'date': formattedDate,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _confirmTaken() {
    _logHistory('Taken'); // Log as Taken
    // NOTE: Cancelling the specific notification for this dose is tricky
    // and would require tracking the notification ID passed via payload.
    // For simplicity, we just close the screen.
    Navigator.pop(context);
  }

  void _skipAction() {
    _logHistory('Skipped'); // Log as Skipped
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBackgroundColor = Color(0xFF1A1A1D);
    const Color textColor = Colors.white;
    const Color accentColor = Color(0xFFEF6A6A);

    final medicineName = widget.medicine.name;
    final dosage = widget.medicine.dosage;
    final notes = widget.medicine.notes;

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- Close Button (now Skips) ---
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: textColor, size: 30),
                    onPressed: _skipAction, // Close button triggers Skip
                  ),
                ),
                const Spacer(flex: 1),

                // --- Reminder Details ---
                const Icon(Icons.notifications_active,
                    color: accentColor, size: 40),
                const SizedBox(height: 20),
                Text(
                  medicineName,
                  style: const TextStyle(
                      color: textColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'TIME TO TAKE MEDICINE',
                  style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 18,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 40),

                // --- Pill Icon ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Icon(widget.medicine.icon, // Use model icon
                      color: accentColor,
                      size: 80),
                ),
                const SizedBox(height: 40),

                // --- Time and Instructions ---
                Text(
                  widget.alarmTime,
                  style: const TextStyle(
                      color: textColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 20),
                Text(
                  'Take $dosage',
                  style: const TextStyle(color: textColor, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  notes.isEmpty ? 'Notes: None' : 'Notes: $notes',
                  style: TextStyle(
                      color: textColor.withOpacity(0.7), fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),

                // --- Swipe to Confirm Taken ---
                ConfirmationSlider(
                  onConfirmation: _confirmTaken, // Logs as Taken
                  text: 'Swipe to Confirm Taken',
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
