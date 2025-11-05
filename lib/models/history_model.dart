// In a file named: lib/models/history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryEntry {
  final String id;
  final String name;
  final String dosage;
  final String time;
  final String date;
  final String status; // "Taken" or "Skipped"
  final DateTime timestamp;

  HistoryEntry({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.date,
    required this.status,
    required this.timestamp,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> map, String docId) {
    return HistoryEntry(
      id: docId,
      name: map['name'] as String? ?? 'Unknown Medicine',
      dosage: map['dosage'] as String? ?? 'N/A',
      time: map['time'] as String? ?? 'N/A',
      date: map['date'] as String? ?? 'N/A',
      status: map['status'] as String? ?? 'Unknown',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
