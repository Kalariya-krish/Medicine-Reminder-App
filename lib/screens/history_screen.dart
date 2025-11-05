// In a file named: lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = "Daily";

  Stream<List<HistoryEntry>>? _historyStream;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Normalize selected day to midnight UTC for comparison consistency
    _selectedDay = _focusedDay.toUtc().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    if (_user != null) {
      _historyStream = _fetchHistoryStream();
    }
  }

  // --- Helper Date Calculations ---

  DateTime _getStartOfWeek(DateTime date) {
    // Finds the previous Monday (start of the week)
    return date.subtract(Duration(days: date.weekday - 1)).toUtc().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  }

  DateTime _getEndOfWeek(DateTime date) {
    // Finds the next Sunday (end of the week)
    return date
        .add(Duration(days: DateTime.daysPerWeek - date.weekday))
        .toUtc()
        .copyWith(
            hour: 23,
            minute: 59,
            second: 59,
            millisecond: 999,
            microsecond: 999);
  }

  DateTime _getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).toUtc().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  }

  DateTime _getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).toUtc().copyWith(
        hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999);
  }

  // --- Firebase Fetch Logic (UPDATED for Ranges) ---
  Stream<List<HistoryEntry>> _fetchHistoryStream() {
    if (_user == null) return const Stream.empty();

    // Get the base query reference
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('history');

    // Always order by timestamp, as it's the only field that supports range queries
    query = query.orderBy('timestamp', descending: true);

    if (_selectedFilter == "Daily" && _selectedDay != null) {
      // For Daily view, we use the exact date string match (relies on your existing composite index)
      final formattedDate =
          DateFormat('dd/MM/yyyy').format(_selectedDay!.toLocal());
      query = query.where('date', isEqualTo: formattedDate);
    } else if (_selectedDay != null) {
      // For Weekly or Monthly, use timestamp range query
      late DateTime startDate;
      late DateTime endDate;

      if (_selectedFilter == "Weekly") {
        startDate = _getStartOfWeek(_selectedDay!.toLocal());
        endDate = _getEndOfWeek(_selectedDay!.toLocal());
      } else if (_selectedFilter == "Monthly") {
        startDate = _getStartOfMonth(_selectedDay!.toLocal());
        endDate = _getEndOfMonth(_selectedDay!.toLocal());
      }

      // Filter by timestamp range (this REQUIRES a single index on 'timestamp')
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate);
    }

    // Execute the query
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data =
            doc.data() as Map<String, dynamic>; // This confirms the type.
        return HistoryEntry.fromMap(data, doc.id);
      }).toList();
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Note: We use toLocal() before calculating the day range to ensure calculations are correct
    // for the user's local day boundaries, then convert back to UTC for Firestore.
    final normalizedSelectedDay = selectedDay.toUtc().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    if (!isSameDay(_selectedDay, normalizedSelectedDay)) {
      setState(() {
        _selectedDay = normalizedSelectedDay;
        _focusedDay = focusedDay;
        _historyStream = _fetchHistoryStream(); // Re-fetch data
      });
    }
  }

  // Function called when filter tabs are tapped
  void _onFilterChanged(String newFilter) {
    if (_selectedFilter != newFilter) {
      setState(() {
        _selectedFilter = newFilter;
        _historyStream = _fetchHistoryStream(); // Re-fetch data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (User check remains the same)
    if (_user == null) {
      return const Center(child: Text("Please log in to view your history."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          onTap: () => _onFilterChanged(tab), // Use new handler
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

                // Calendar (Only show in Daily View)
                if (_selectedFilter == "Daily")
                  TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    // ... (rest of calendar styles and logic remain the same)
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

                // Show selected range for Weekly/Monthly
                if (_selectedFilter != "Daily" && _selectedDay != null)
                  _buildRangeDisplay(),

                const SizedBox(height: 20),

                // Date Title
                Text(
                  _getHistoryTitle(), // Use helper for dynamic title
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Medicines List (StreamBuilder)
                _buildHistoryList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to display the time range selected
  Widget _buildRangeDisplay() {
    if (_selectedDay == null) return const SizedBox.shrink();

    String rangeText;
    if (_selectedFilter == "Weekly") {
      final start = _getStartOfWeek(_selectedDay!.toLocal());
      final end = _getEndOfWeek(_selectedDay!.toLocal());
      rangeText =
          '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    } else {
      // Monthly
      final date = _selectedDay!.toLocal();
      rangeText = DateFormat('MMMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          rangeText,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700]),
        ),
      ),
    );
  }

  String _getHistoryTitle() {
    if (_selectedDay == null) return "Select a Date";
    if (_selectedFilter == "Daily") {
      return DateFormat('EEEE, MMM d, yyyy').format(_selectedDay!.toLocal());
    }
    // For Weekly/Monthly, the RangeDisplay widget handles the primary title
    return "Total Records for Selected Range";
  }

  // StreamBuilder for history list (same logic, but querying the range stream)
  Widget _buildHistoryList() {
    // ... (stream check remains the same)

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
              child: Text('Error loading history: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        final List<HistoryEntry> medicines = snapshot.data ?? [];

        // Show total count for Weekly/Monthly view
        if (_selectedFilter != "Daily") {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Records Found: ${medicines.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  return _buildHistoryItem(medicines[index]);
                },
              ),
            ],
          );
        }

        // Default Daily View rendering:
        if (medicines.isEmpty) {
          return const Center(
            child: Text(
              "No medications recorded for this day.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            return _buildHistoryItem(medicines[index]);
          },
        );
      },
    );
  }

  // Helper widget for a single history item row
  Widget _buildHistoryItem(HistoryEntry med) {
    final bool isTaken = med.status == "Taken";
    final Color statusColor = isTaken ? Colors.green : Colors.red;
    final Color backgroundColor =
        isTaken ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
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
  }
}
