// In a file named: lib/screens/today_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // NEW for date formatting
import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW

import 'package:medicine_reminder_system/screens/add_medicine_screen.dart';
import '../models/medicine.dart'; // Import the updated model
import 'package:medicine_reminder_system/screens/reminder_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // Use a Stream to listen for real-time updates
  Stream<List<Medicine>>? _medicinesStream;
  final User? _user = FirebaseAuth.instance.currentUser;

  int _selectedDateIndex = 3;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _medicinesStream = _fetchMedicinesStream();
    }
  }

  // Function to get the stream of medicines for the current user
  Stream<List<Medicine>> _fetchMedicinesStream() {
    // Only fetch for the current day's start date
    final todayFormatted = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // NOTE: This basic filter fetches medicines whose startDate is today or earlier
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
              _buildMedicationList(), // Uses StreamBuilder
              const SizedBox(height: 20),
              // This part will need dynamic calculation based on fetched data
              const Center(
                child: Text(
                  'Loading medication count...',
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

  // --- Medication List Widget (Updated to use StreamBuilder) ---
  Widget _buildMedicationList() {
    if (_user == null) {
      return const Center(
          child: Text("Please log in to see your medications."));
    }

    if (_medicinesStream == null) {
      return const Center(child: Text("Loading..."));
    }

    return StreamBuilder<List<Medicine>>(
      stream: _medicinesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(30.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final medicines = snapshot.data ?? [];

        if (medicines.isEmpty) {
          return const Center(child: Text('No medicines found for this user.'));
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: medicines.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return MedicationCard(medicine: medicines[index]);
          },
        );
      },
    );
  }

  // --- Header Widget ---
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

  // --- Date Selector Widget (unchanged) ---
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

// --- Medication Card Widget (Updated to use Medicine model) ---
class MedicationCard extends StatefulWidget {
  final Medicine medicine; // Renamed property

  const MedicationCard({super.key, required this.medicine});

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  late bool isTaken;

  @override
  void initState() {
    super.initState();
    isTaken = widget.medicine.isTaken; // Use model property
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.medicine.icon, // Use model icon
                  color: const Color(0xFFEF6A6A),
                  size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.medicine.name, // Use model name
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    // Use model dosage and alarmTimes
                    'Dosage: ${widget.medicine.dosage} | ${widget.medicine.alarmTimes}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          if (widget.medicine.name != 'Antibiotic') // Use model name
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    label: 'Taken',
                    icon: Icons.check,
                    color:
                        isTaken ? Colors.green.withOpacity(0.5) : Colors.green,
                    onPressed:
                        isTaken ? null : () => setState(() => isTaken = true),
                  ),
                  _buildActionButton(
                    label: 'Snooze',
                    icon: Icons.snooze,
                    color: isTaken ? Colors.blue.withOpacity(0.5) : Colors.blue,
                    onPressed: isTaken
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReminderScreen(
                                  // FIX: Pass the required Medicine object
                                  medicine: widget.medicine,
                                  // FIX: Pass the required alarmTime string
                                  alarmTime: widget.medicine.alarmTimes,
                                ),
                              ),
                            );
                          },
                  ),
                  _buildActionButton(
                    label: 'Skip',
                    icon: Icons.close,
                    color: isTaken ? Colors.red.withOpacity(0.5) : Colors.red,
                    onPressed: isTaken ? null : () {},
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
// NOTE: I've removed the redundant `FirebaseAuthService` section as it was already 
// provided and not directly required for the screen updates.