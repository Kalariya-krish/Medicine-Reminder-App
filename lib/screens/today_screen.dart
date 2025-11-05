// In a file named: lib/screens/today_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:medicine_reminder_system/screens/add_medicine_screen.dart';
import '../models/medicine.dart';
import '../models/history_model.dart';
import '../services/notification_service.dart'; // Assuming this is fixed

// Helper extension to mimic functional `firstWhereOrNull`
extension IterableExtensions<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// Helper class to represent a single dose time slot for a medicine
class _MedicationTimeSlot {
  final Medicine medicine;
  final String time;

  _MedicationTimeSlot({required this.medicine, required this.time});
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Stream<List<Medicine>>? _medicinesStream;
  Stream<List<HistoryEntry>>? _historyStream;
  final User? _user = FirebaseAuth.instance.currentUser;

  int _selectedDateIndex = 3;

  @override
  void initState() {
    super.initState();
    // FIX: Listen to notification taps from the service
    NotificationService.selectNotificationSubject.listen((payload) {
      if (payload != null && mounted) {
        NotificationService.onSelectNotification(payload);
      }
    });

    if (_user != null) {
      _medicinesStream = _fetchMedicinesStream();
      _historyStream = _fetchTodayHistoryStream();
      _scheduleAllNotifications();
    }
  }

  // Fetches all active medicines
  Stream<List<Medicine>> _fetchMedicinesStream() {
    final todayFormatted = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('medicines')
        .where('startDate', isLessThanOrEqualTo: todayFormatted)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Medicine.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Fetches history entries for today
  Stream<List<HistoryEntry>> _fetchTodayHistoryStream() {
    final todayFormatted = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('history')
        .where('date', isEqualTo: todayFormatted)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryEntry.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Schedules all reminders for fetched medicines
  void _scheduleAllNotifications() {
    NotificationService.cancelAllNotifications();

    _medicinesStream?.first.then((medicines) {
      int idCounter = 0;
      for (var medicine in medicines) {
        final times24h = medicine.alarmTimes.split(',');
        for (var time24h in times24h) {
          idCounter++;

          final parts = time24h.split(':');
          if (parts.length != 2) continue; // Skip invalid times

          final time =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          final alarmTime = time.format(context);

          NotificationService.scheduleMedicineReminder(
            id: idCounter,
            medicine: medicine,
            time24h: time24h,
            alarmTime: alarmTime,
          );
        }
      }
    });
  }

  // Helper to flatten medicine list by time slots
  List<_MedicationTimeSlot> _getDailyTimeSlots(List<Medicine> medicines) {
    final List<_MedicationTimeSlot> slots = [];
    for (var medicine in medicines) {
      final times24h = medicine.alarmTimes.split(',');
      for (var time24h in times24h) {
        try {
          final parts = time24h.split(':');
          final time =
              TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          final alarmTime = time.format(context);
          slots.add(_MedicationTimeSlot(medicine: medicine, time: alarmTime));
        } catch (e) {
          // Ignore invalid time formats
        }
      }
    }
    slots.sort((a, b) => a.time.compareTo(b.time));
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFEF6A6A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildDateSelector(),
              const SizedBox(height: 30),
              const Text(
                "Today's Medication",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildMedicationList(),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Medication status updated in real-time from history.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddMedicineScreen()));
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Medication List Widget (Uses nested StreamBuilder for live data + history) ---
  Widget _buildMedicationList() {
    if (_user == null || _medicinesStream == null || _historyStream == null) {
      return const Center(child: Text("Loading user data..."));
    }

    return StreamBuilder<List<Medicine>>(
      stream: _medicinesStream,
      builder: (context, medicineSnapshot) {
        if (medicineSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: CircularProgressIndicator()));
        }

        final List<Medicine> medicines = medicineSnapshot.data ?? [];
        if (medicines.isEmpty) {
          return const Center(child: Text('No active medicines found.'));
        }

        // Nested StreamBuilder for History
        return StreamBuilder<List<HistoryEntry>>(
          stream: _historyStream,
          builder: (context, historySnapshot) {
            final List<HistoryEntry> history = historySnapshot.data ?? [];
            final List<_MedicationTimeSlot> dailySlots =
                _getDailyTimeSlots(medicines);

            if (dailySlots.isEmpty) {
              return const Center(child: Text('No doses scheduled for today.'));
            }

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: dailySlots.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final slot = dailySlots[index];

                // Find matching history entry (by name and time)
                final HistoryEntry? entry = history.firstWhereOrNull(
                  (h) => h.time == slot.time && h.name == slot.medicine.name,
                );

                return MedicationCard(
                  key: ValueKey(
                      '${slot.medicine.id}_${slot.time}'), // Unique key
                  medicine: slot.medicine,
                  alarmTime: slot.time,
                  historyEntry: entry, // Pass the history status
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Header and Date Selector Widgets (unchanged) ---
  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage('assets/profile_pic.png'),
        ),
        const SizedBox(width: 15),
        const Text(
          'Hey, Jocab',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none, size: 28),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 28),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final List<Map<String, String>> dates = [
      {'day': 'THU', 'date': '07'},
      {'day': 'FRI', 'date': '08'},
      {'day': 'SAT', 'date': '09'},
      {'day': 'SUN', 'date': '10'},
      {'day': 'MON', 'date': '11'},
      {'day': 'TUS', 'date': '12'},
      {'day': 'WED', 'date': '13'},
    ];

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          bool isSelected = index == _selectedDateIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFEF6A6A) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dates[index]['day']!,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey)),
                  const SizedBox(height: 8),
                  Text(dates[index]['date']!,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Medication Card Widget (UPDATED) ---
class MedicationCard extends StatelessWidget {
  final Medicine medicine;
  final String alarmTime;
  final HistoryEntry? historyEntry; // Holds the history status

  const MedicationCard({
    super.key,
    required this.medicine,
    required this.alarmTime,
    this.historyEntry,
  });

  // Function to log a record to Firestore history collection
  Future<void> _logHistory(BuildContext context, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'medicineId': medicine.id,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'time': alarmTime,
        'date': formattedDate,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medicine marked as $status!')),
        );
      }
    } catch (e) {
      debugPrint('Error logging history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTaken = historyEntry?.status == 'Taken';
    final bool isSkipped = historyEntry?.status == 'Skipped';
    final bool isHandled = isTaken || isSkipped;
    final Color primaryColor = const Color(0xFFEF6A6A);
    final Color takenColor = Colors.green.shade600;
    final Color handledColor = isTaken ? takenColor : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isHandled ? Colors.grey.shade100 : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(medicine.icon,
                  color:
                      isHandled ? handledColor.withOpacity(0.5) : primaryColor,
                  size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medicine.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Dosage: ${medicine.dosage} | $alarmTime',
                    style: TextStyle(
                      color: isHandled
                          ? handledColor.withOpacity(0.8)
                          : Colors.grey[600],
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Display status text if handled
              if (isHandled)
                Text(historyEntry!.status.toUpperCase(),
                    style: TextStyle(
                        color: handledColor, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!isHandled) // Only show buttons if not handled
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    label: 'Taken',
                    icon: Icons.check,
                    color: takenColor,
                    onPressed: () =>
                        _logHistory(context, 'Taken'), // Firebase Log
                  ),
                  _buildActionButton(
                    label: 'Skip',
                    icon: Icons.close,
                    color: Colors.red,
                    onPressed: () =>
                        _logHistory(context, 'Skipped'), // Firebase Log
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: TextButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
    );
  }
}
