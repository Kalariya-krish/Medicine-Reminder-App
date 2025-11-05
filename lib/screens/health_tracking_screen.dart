// In a file named: lib/screens/health_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW
import 'package:intl/intl.dart'; // NEW
import '../models/vitals_model.dart'; // NEW

// Legend Widget (Remains a separate class)
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// Convert to StatefulWidget
class HealthTrackerScreen extends StatefulWidget {
  const HealthTrackerScreen({Key? key}) : super(key: key);

  @override
  State<HealthTrackerScreen> createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Stream<List<VitalEntry>>? _vitalsStream;
  List<VitalEntry> _vitalsData = [];

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _vitalsStream = _fetchVitalsStream();
      // Start listening to update local state for charts
      _vitalsStream!.listen((data) {
        if (mounted) {
          setState(() {
            _vitalsData = data;
          });
        }
      });
    }
  }

  // --- Firebase Fetch Logic ---
  Stream<List<VitalEntry>> _fetchVitalsStream() {
    if (_user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('vitals') // NEW SUBCOLLECTION
        .orderBy('timestamp', descending: true)
        .limit(10) // Limit to last 10 entries for history/charts
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VitalEntry.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- Firebase Save Logic (Modal) ---
  Future<void> _saveVital(String type, String value) async {
    if (_user == null || value.isEmpty) return;

    final newVital = VitalEntry(
      id: '',
      type: type,
      value: value,
      timestamp: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('vitals')
          .add(newVital.toMap());

      // Success feedback (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save $type: $e')),
      );
    }
  }

  // --- Modal Bottom Sheet (UPDATED to call _saveVital) ---
  void _showAddVital(BuildContext context, String vitalType) {
    final TextEditingController valueController = TextEditingController();
    final _modalFormKey = GlobalKey<FormState>(); // NEW: Form Key

    String label = vitalType == "Blood Pressure"
        ? "Systolic/Diastolic (e.g., 120/80)"
        : vitalType == "Blood Sugar"
            ? "Value (mg/dL)"
            : "Value (kg)";
    TextInputType keyboardType = vitalType == "Blood Pressure"
        ? TextInputType.text
        : TextInputType.number;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: Form(
            // NEW: Added Form
            key: _modalFormKey, // NEW: Assign Form Key
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add $vitalType",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  // NEW: Changed to TextFormField for validation
                  controller: valueController,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    // NEW: Validation Logic
                    if (value == null || value.isEmpty) {
                      return 'Value is required.';
                    }

                    if (vitalType == "Blood Pressure") {
                      final parts = value.split('/');
                      if (parts.length != 2)
                        return 'Format must be systolic/diastolic.';
                      final systolic = double.tryParse(parts[0]) ?? 0;
                      final diastolic = double.tryParse(parts[1]) ?? 0;
                      // Realistic BP range check
                      if (systolic < 70 ||
                          systolic > 250 ||
                          diastolic < 30 ||
                          diastolic > 150) {
                        return 'BP values seem unrealistic (70-250/30-150).';
                      }
                    } else if (vitalType == "Blood Sugar") {
                      final sugar = double.tryParse(value) ?? 0;
                      // Realistic Sugar range check (mg/dL)
                      if (sugar < 40 || sugar > 600) {
                        return 'Sugar value must be between 40-600 mg/dL.';
                      }
                    } else if (vitalType == "Weight") {
                      final weight = double.tryParse(value) ?? 0;
                      // Realistic Weight range check (kg)
                      if (weight < 20 || weight > 300) {
                        return 'Weight must be between 20-300 kg.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF6A6A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Check validation on press
                      if (_modalFormKey.currentState!.validate()) {
                        String value = valueController.text.trim();
                        _saveVital(vitalType, value);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Save"),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Chart Data Processing ---
  List<FlSpot> _getChartSpots(String type) {
    final filtered =
        _vitalsData.where((v) => v.type == type).toList().reversed.toList();

    // Assign a fixed color based on type for consistency
    final Map<String, Color> colorMap = {
      "Blood Pressure": Colors.red,
      "Blood Sugar": Colors.blue,
      "Weight": Colors.green,
    };

    if (type == "Blood Pressure") {
      // Use Systolic value (the first number in "120/80")
      return List.generate(filtered.length, (index) {
        final entry = filtered[index];
        final systolic = double.tryParse(entry.value.split('/').first) ?? 0;
        return FlSpot(index.toDouble(), systolic);
      });
    } else {
      // Use value directly (Blood Sugar or Weight)
      return List.generate(filtered.length, (index) {
        final entry = filtered[index];
        final value = double.tryParse(entry.value) ?? 0;
        return FlSpot(index.toDouble(), value);
      });
    }
  }

  // --- Widget Builders (Updated to use dynamic data) ---

  // Vitals Item Widget (Unchanged)
  Widget _buildVitalItem(IconData icon, String title, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width / 3.5,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // History Row Widget (Updated to use VitalsModel)
  Widget _buildHistoryRow(VitalEntry entry) {
    String valueDisplay;
    Color iconColor;

    if (entry.type == "Blood Pressure") {
      valueDisplay = entry.value;
      iconColor = Colors.red;
    } else if (entry.type == "Blood Sugar") {
      valueDisplay = "${entry.value} mg/dL";
      iconColor = Colors.blue;
    } else {
      valueDisplay = "${entry.value} kg";
      iconColor = Colors.green;
    }

    final formattedDate =
        DateFormat('MMM d, h:mm a').format(entry.timestamp.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(formattedDate,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.monitor_heart, color: iconColor, size: 18),
                const SizedBox(width: 6),
                Text(valueDisplay,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(entry.type.split(' ').last,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  // Pie Chart Section Helper
  List<PieChartSectionData> _getPieSections() {
    int bpCount = _vitalsData.where((v) => v.type == "Blood Pressure").length;
    int sugarCount = _vitalsData.where((v) => v.type == "Blood Sugar").length;
    int weightCount = _vitalsData.where((v) => v.type == "Weight").length;
    int total = bpCount + sugarCount + weightCount;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No Data',
          radius: 40,
        )
      ];
    }

    return [
      if (bpCount > 0)
        PieChartSectionData(
          color: Colors.red,
          value: (bpCount / total) * 100,
          title: '',
          radius: 40,
        ),
      if (sugarCount > 0)
        PieChartSectionData(
          color: Colors.blue,
          value: (sugarCount / total) * 100,
          title: '',
          radius: 40,
        ),
      if (weightCount > 0)
        PieChartSectionData(
          color: Colors.green,
          value: (weightCount / total) * 100,
          title: '',
          radius: 40,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text("Please log in to track your health."));
    }

    final bpSpots = _getChartSpots("Blood Pressure");
    final sugarSpots = _getChartSpots("Blood Sugar");
    final weightSpots = _getChartSpots("Weight");

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Health Tracker",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Add Vitals Section
                const Text(
                  "Add Vitals",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => _showAddVital(context, "Blood Pressure"),
                      child: _buildVitalItem(
                          Icons.favorite, "Blood Pressure", Colors.red),
                    ),
                    GestureDetector(
                      onTap: () => _showAddVital(context, "Blood Sugar"),
                      child: _buildVitalItem(
                          Icons.opacity, "Blood Sugar", Colors.blue),
                    ),
                    GestureDetector(
                      onTap: () => _showAddVital(context, "Weight"),
                      child:
                          _buildVitalItem(Icons.scale, "Weight", Colors.green),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Progress Section (Line Chart)
                const Text(
                  "Systolic Blood Pressure Progress",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (bpSpots.length - 1)
                          .toDouble()
                          .clamp(0, double.infinity),
                      minY: 60,
                      maxY: 200,
                      borderData: FlBorderData(show: false),

                      // ✅ TITLES
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        // ✅ LEFT TITLES
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              if (value % 50 != 0) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta, // ✅ Updated (no axisSide:, space:)
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // ✅ BOTTOM TITLES
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: bpSpots.length > 1,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0)
                                return const SizedBox.shrink();

                              final index = bpSpots.length - 1 - value.toInt();
                              if (index < 0 || index >= _vitalsData.length) {
                                return const SizedBox.shrink();
                              }

                              final date =
                                  _vitalsData[index].timestamp.toLocal();
                              return SideTitleWidget(
                                meta: meta, // ✅ Updated (no axisSide:, space:)
                                child: Text(
                                  DateFormat('d MMM').format(date),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ✅ GRID
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 0.5,
                        ),
                      ),

                      // ✅ LINE DATA
                      lineBarsData: [
                        LineChartBarData(
                          spots: bpSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Pie Chart
                const Text(
                  "Vital Entry Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieSections(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _LegendItem(color: Colors.red, text: "Blood Pressure"),
                    _LegendItem(color: Colors.blue, text: "Blood Sugar"),
                    _LegendItem(color: Colors.green, text: "Weight"),
                  ],
                ),
                const SizedBox(height: 30),

                // History Section
                const Text(
                  "Recent History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Dynamic History List
                if (_vitalsData.isEmpty)
                  const Center(child: Text("No vital entries recorded yet."))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vitalsData.length.clamp(0, 5), // Show top 5
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      return _buildHistoryRow(_vitalsData[index]);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
