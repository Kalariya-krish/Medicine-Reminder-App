// In a file named: lib/models/medicine.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String timeSlot;
  final String alarmTimes; // Comma separated 24h times (e.g., "08:00,14:00")
  final String startDate;
  final String endDate; // NEW FIELD
  final String notes;

  // Fields added for TodayScreen UI compatibility
  final IconData icon;
  final bool isTaken;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timeSlot,
    required this.alarmTimes,
    required this.startDate,
    required this.endDate, // REQUIRED
    required this.notes,
    this.icon = Icons.medication,
    this.isTaken = false,
  });

  // Factory constructor to create from Firestore Map
  factory Medicine.fromMap(Map<String, dynamic> map, String docId) {
    return Medicine(
      id: docId,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      timeSlot: map['timeSlot'] as String,
      alarmTimes: map['alarmTimes'] as String,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String? ?? 'N/A',
      notes: map['notes'] as String,
      icon: (map['dosage'] as String).toLowerCase().contains('syrup')
          ? Icons.medication_liquid
          : Icons.medication,
      isTaken: false,
    );
  }

  // Factory constructor for Notification Payload (JSON)
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      timeSlot: json['timeSlot'] as String,
      alarmTimes: json['alarmTimes'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String, // REQUIRED
      notes: json['notes'] as String,
      icon:
          Icons.medication, // Default icon, as IconData isn't JSON serializable
      isTaken: false,
    );
  }

  // To map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeSlot': timeSlot,
      'alarmTimes': alarmTimes,
      'startDate': startDate,
      'endDate': endDate, // NEW FIELD
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // To JSON for Notification Payload
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeSlot': timeSlot,
      'alarmTimes': alarmTimes,
      'startDate': startDate,
      'endDate': endDate, // NEW FIELD
      'notes': notes,
    };
  }
}
