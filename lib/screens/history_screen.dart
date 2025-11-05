// In a file named: lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart'; // Ensure this path is correct

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = "Daily";

  // Stream to hold the history data for the selected day
  Stream<List<HistoryEntry>>? _historyStream;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Normalize selected day to midnight UTC for comparison consistency
    _selectedDay = _focusedDay.toUtc().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    if (_user != null) {
      _historyStream = _fetchHistoryForSelectedDay(_selectedDay!);
    }
  }

  // Function to fetch history for a specific day
  Stream<List<HistoryEntry>> _fetchHistoryForSelectedDay(DateTime date) {
    if (_user == null) return const Stream.empty();

    // Format the date string exactly as it is saved in Firestore
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('history')
        .where('date', isEqualTo: formattedDate)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryEntry.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Normalize the selected day before setting state and fetching data
    final normalizedSelectedDay = selectedDay.toUtc().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    if (!isSameDay(_selectedDay, normalizedSelectedDay)) {
      setState(() {
        _selectedDay = normalizedSelectedDay;
        _focusedDay = focusedDay;
        _historyStream = _fetchHistoryForSelectedDay(
            normalizedSelectedDay); // Start new fetch
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is logged in
    if (_user == null) {
      return const Center(child: Text("Please log in to view your history."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // FIX: Use SingleChildScrollView to prevent overflow
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Since the outer Column is scrollable, the list inside must be wrapped with a flexible widget.
              children: [
                // Title
                const Text(
                  "History",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Tabs (Daily, Weekly, Monthly)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ["Daily", "Weekly", "Monthly"].map((tab) {
                      final isSelected = _selectedFilter == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = tab;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.red : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tab,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Calendar (Daily View)
                if (_selectedFilter == "Daily")
                  TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.red.shade200,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: _onDaySelected,
                  ),

                const SizedBox(height: 20),

                // Date Title
                Text(
                  _selectedDay != null
                      ? DateFormat('EEEE, MMM d, yyyy')
                          .format(_selectedDay!.toLocal())
                      : "Select a Date",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Medicines List (Uses StreamBuilder to fetch live data)
                // FIX: Use a constrained SizedBox or remove Expanded and let the ListView naturally size itself.
                // We use a ListView with `shrinkWrap: true` inside the SingleChildScrollView
                _buildHistoryList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // StreamBuilder for history list
  Widget _buildHistoryList() {
    if (_historyStream == null) {
      return const Center(child: Text("Select a date to view history."));
    }

    return StreamBuilder<List<HistoryEntry>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(30.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading history: ${snapshot.error}'));
        }

        final List<HistoryEntry> medicines = snapshot.data ?? [];

        if (medicines.isEmpty) {
          return const Center(
            child: Text(
              "No medications recorded for this day.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Key Fixes: Set physics to NeverScrollableScrollPhysics and shrinkWrap to true
        // when a ListView is nested inside a SingleChildScrollView.
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final med = medicines[index];
            final bool isTaken = med.status == "Taken";
            final Color statusColor = isTaken ? Colors.green : Colors.red;
            final Color backgroundColor =
                isTaken ? Colors.green.shade50 : Colors.red.shade50;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Use a subtle background color
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.medication, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${med.dosage} at ${med.time}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2), // Lighter fill
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      med.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
