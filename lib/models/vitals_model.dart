// In a file named: lib/models/vitals_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class VitalEntry {
  final String id;
  final String type; // e.g., "Blood Pressure", "Blood Sugar", "Weight"
  final String value; // e.g., "120/80", "130", "75"
  final DateTime timestamp;

  VitalEntry({
    required this.id,
    required this.type,
    required this.value,
    required this.timestamp,
  });

  factory VitalEntry.fromMap(Map<String, dynamic> map, String docId) {
    return VitalEntry(
      id: docId,
      type: map['type'] as String,
      value: map['value'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
