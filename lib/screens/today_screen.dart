// In a file named: lib/screens/today_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:medicine_reminder_system/screens/add_medicine_screen.dart';
import '../models/medicine.dart';
import '../models/history_model.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

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
  Stream<UserProfile?>? _userProfileStream;

  final User? _user = FirebaseAuth.instance.currentUser;

  // FIX 1: Use DateTime? for selected date, initialized to today
  DateTime? _selectedDay;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = _today;

    // FIX: Listen to notification taps from the service
    NotificationService.selectNotificationSubject.listen((payload) {
      if (payload != null && mounted) {
        NotificationService.onSelectNotification(payload);
      }
    });

    if (_user != null) {
      _userProfileStream = _fetchUserProfileStream();
      _loadDataForSelectedDay();
      _scheduleAllNotifications();
    }
  }

// NEW: Function to stream user profile from Firestore
  Stream<UserProfile?> _fetchUserProfileStream() {
    if (_user == null) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserProfile.fromFirestore(docSnapshot.data()!, _user!.uid);
      }
      return null;
    });
  }

  // FIX 2: Unified method to load streams based on _selectedDay
  void _loadDataForSelectedDay() {
    if (_user == null || _selectedDay == null) return;

    setState(() {
      // Re-initialize streams with the current selected day
      _medicinesStream = _fetchMedicinesStream(_selectedDay!);
      _historyStream = _fetchTodayHistoryStream(_selectedDay!);
    });
  }

  // NOTE: This helper is needed to parse the date strings from Firestore/UI
  DateTime _parseDateString(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      // Return a date far in the past to ensure invalid dates don't block display
      return DateTime(1900);
    }
  }

  // Fetches all active medicines (UPDATED to accept date)
  Stream<List<Medicine>> _fetchMedicinesStream(DateTime date) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('medicines')
        .snapshots()
        .map((snapshot) {
      // Filter in Dart to check the duration range
      final filteredMedicines = snapshot.docs.map((doc) {
        return Medicine.fromMap(doc.data()!, doc.id);
      }).where((medicine) {
        // 1. Check if the selected date is ON or AFTER the start date
        final start = _parseDateString(medicine.startDate);
        final isOnOrAfterStart =
            date.isAfter(start) || DateUtils.isSameDay(date, start);

        // 2. Check if the selected date is ON or BEFORE the end date
        // If endDate is empty (or 'N/A'), assume the treatment is ongoing (indefinite future date)
        final endString = medicine.endDate.isEmpty || medicine.endDate == 'N/A'
            ? '31/12/2100'
            : medicine.endDate;
        final end = _parseDateString(endString);
        final isOnOrBeforeEnd =
            date.isBefore(end) || DateUtils.isSameDay(date, end);

        return isOnOrAfterStart && isOnOrBeforeEnd;
      }).toList();

      return filteredMedicines;
    });
  }

  // Fetches history entries for the selected day (UPDATED to accept date)
  Stream<List<HistoryEntry>> _fetchTodayHistoryStream(DateTime date) {
    // Filter history by the exact selected date
    final selectedDateFormatted = DateFormat('dd/MM/yyyy').format(date);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('history')
        .where('date', isEqualTo: selectedDateFormatted)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryEntry.fromMap(doc.data()!, doc.id);
      }).toList();
    });
  }

  // Schedules all reminders for fetched medicines (Called ONLY once on startup for today)
  void _scheduleAllNotifications() {
    // Check if the current selected day is today. Only schedule reminders for TODAY.
    if (!DateUtils.isSameDay(_selectedDay, _today)) return;

    NotificationService.cancelAllNotifications();

    _medicinesStream?.first.then((medicines) {
      int idCounter = 0;
      for (var medicine in medicines) {
        final times24h = medicine.alarmTimes.split(',');
        for (var time24h in times24h) {
          idCounter++;

          final parts = time24h.split(':');
          if (parts.length != 2) continue;

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

  // Helper to get the starting date of the week (Monday) based on _today
  DateTime _getStartOfWeek() {
    final start = _today.subtract(Duration(days: _today.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  // Helper to flatten medicine list by time slots
  List<_MedicationTimeSlot> _getDailyTimeSlots(List<Medicine> medicines) {
    final List<_MedicationTimeSlot> slots = [];
    // Only show scheduled doses if the selected date is today or in the future.
    // If viewing history (past date), we might only want to rely on the history log.
    // We keep the logic simple here: just list all active slots.

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
              _buildDateSelector(), // Now interactive
              const SizedBox(height: 30),
              Text(
                // Dynamic title based on selected date
                DateUtils.isSameDay(_selectedDay, _today)
                    ? "Today's Medication"
                    : "Medication on ${DateFormat('EEE, MMM d').format(_selectedDay!)}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

    // NEW: Determine if the currently selected day is TODAY
    final bool isTodaySelected = DateUtils.isSameDay(_selectedDay, _today);

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
              return const Center(
                  child: Text('No doses scheduled for this day.'));
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
                  key: ValueKey('${slot.medicine.id}_${slot.time}'),
                  medicine: slot.medicine,
                  alarmTime: slot.time,
                  historyEntry: entry, // Pass the history status
                  isActionEnabled:
                      isTodaySelected, // <-- NEW: Pass the boolean flag
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Header Widget (UPDATED to use StreamBuilder) ---
  Widget _buildHeader() {
    if (_userProfileStream == null) {
      // Display placeholder if stream hasn't initialized (shouldn't happen post-login)
      return _buildHeaderContent(
          username: 'Loading...',
          imageUrl: 'assets/images/default_profile.png');
    }

    return StreamBuilder<UserProfile?>(
      stream: _userProfileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHeaderContent(
              username: 'Loading...',
              imageUrl: 'assets/images/default_profile.png');
        }

        final userProfile = snapshot.data;
        // Use username/image from profile, defaulting to 'Guest'/'assets/profile_pic.png' if null
        final username = userProfile?.username ?? 'Guest';
        final imageUrl =
            userProfile?.imageUrl ?? 'assets/images/default_profile.png';

        return _buildHeaderContent(username: username, imageUrl: imageUrl);
      },
    );
  }

  // Helper to render the actual Row content
  Widget _buildHeaderContent(
      {required String username, required String imageUrl}) {
    // FIX: Check for the exact default path saved in Firestore
    final bool isDefaultImage =
        imageUrl == 'assets/images/default_profile.png' ||
            imageUrl == 'assets/profile_pic.png';

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: isDefaultImage
              // Use AssetImage for local default path
              ? AssetImage(imageUrl) as ImageProvider
              // Use NetworkImage for Firebase URL
              : NetworkImage(imageUrl),
        ),
        const SizedBox(width: 15),
        Text(
          'Hey, $username',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final startOfWeek = _getStartOfWeek();
    final List<DateTime> dates =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          // FIX 3: Check if the current date is the selected day for highlighting
          final bool isSelected = DateUtils.isSameDay(_selectedDay, date);

          return GestureDetector(
            onTap: () {
              // FIX 4: Update _selectedDay and reload data
              setState(() {
                _selectedDay = date;
                _loadDataForSelectedDay();
              });
            },
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
                  Text(DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey)),
                  const SizedBox(height: 8),
                  Text(DateFormat('d').format(date),
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

// --- Medication Card Widget (Unchanged) ---
class MedicationCard extends StatelessWidget {
  final Medicine medicine;
  final String alarmTime;
  final HistoryEntry? historyEntry; // Holds the history status
  final bool isActionEnabled; // <-- NEW FIELD

  const MedicationCard({
    super.key,
    required this.medicine,
    required this.alarmTime,
    this.historyEntry,
    this.isActionEnabled = false, // Default to false for safety
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

    // Determine if the button should be active for press (must be today AND not yet handled)
    final bool buttonActive = isActionEnabled && !isHandled;

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
                    color: buttonActive
                        ? takenColor
                        : Colors.grey, // Grey if disabled
                    // NEW: Disable onPressed if buttonActive is false
                    onPressed: buttonActive
                        ? () => _logHistory(context, 'Taken')
                        : null,
                  ),
                  _buildActionButton(
                    label: 'Skip',
                    icon: Icons.close,
                    color: buttonActive
                        ? Colors.red
                        : Colors.grey, // Grey if disabled
                    // NEW: Disable onPressed if buttonActive is false
                    onPressed: buttonActive
                        ? () => _logHistory(context, 'Skipped')
                        : null,
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
    required VoidCallback? onPressed,
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
