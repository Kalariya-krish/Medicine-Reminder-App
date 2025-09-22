// In a file named: lib/screens/today_screen.dart

import 'package:flutter/material.dart';
// Import the screen you want to navigate to
import 'package:medicine_reminder_system/screens/add_medicine_screen.dart';
// Import your new model file
import 'package:medicine_reminder_system/models/medication_model.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // Sample data now uses the imported Medication model
  final List<Medication> _medications = [
    Medication(
        name: 'Peracetamol',
        dosage: '1 Tablet',
        time: '8:00 AM',
        icon: Icons.medication),
    Medication(
        name: 'Cough Syrup',
        dosage: '2 Teaspoon',
        time: '2:00 AM',
        icon: Icons.medication_liquid,
        isTaken: true),
    Medication(
        name: 'Antibiotic',
        dosage: '1 Tablet',
        time: '9:00 AM',
        icon: Icons.medication),
  ];

  int _selectedDateIndex = 3;

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
                  '2 of 3 medications taken today',
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

  // --- Date Selector Widget ---
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

  // --- Medication List Widget ---
  Widget _buildMedicationList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _medications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return MedicationCard(medication: _medications[index]);
      },
    );
  }
}

// --- Medication Card Widget (Remains in the screen file as it's a UI component) ---
class MedicationCard extends StatefulWidget {
  final Medication medication;

  const MedicationCard({super.key, required this.medication});

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  late bool isTaken;

  @override
  void initState() {
    super.initState();
    isTaken = widget.medication.isTaken;
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
              Icon(widget.medication.icon,
                  color: const Color(0xFFEF6A6A), size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.medication.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Dosage: ${widget.medication.dosage} | ${widget.medication.time}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          if (widget.medication.name != 'Antibiotic')
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
                    onPressed: isTaken ? null : () {},
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
