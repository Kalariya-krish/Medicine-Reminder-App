import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthTrackerScreen extends StatelessWidget {
  const HealthTrackerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          _buildVitalItem(Icons.lock, "Weight", Colors.green),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Progress Section
                const Text(
                  "Progress",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 60),
                            FlSpot(1, 100),
                            FlSpot(2, 80),
                            FlSpot(3, 150),
                          ],
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
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.red,
                          value: 40,
                          title: '',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: 30,
                          title: '',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: 30,
                          title: '',
                          radius: 40,
                        ),
                      ],
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
                  "History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                _buildHistoryRow("February 14", "120/28", "130 mg/dL"),
                const Divider(),
                _buildHistoryRow("February 25", "150/32", "170 mg/dL"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Vitals Item Widget
  Widget _buildVitalItem(IconData icon, String title, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // History Row Widget
  Widget _buildHistoryRow(String date, String bp, String sugar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(date, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Text(bp, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(sugar, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// Legend Widget
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

void _showAddVital(BuildContext context, String vitalType) {
  final TextEditingController valueController = TextEditingController();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add $vitalType",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "$vitalType Value",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6A6A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  String value = valueController.text.trim();
                  if (value.isNotEmpty) {
                    // 🔥 Here you can save value to DB or State
                    print("$vitalType Added: $value");
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            )
          ],
        ),
      );
    },
  );
}
