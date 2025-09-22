// In a file named: lib/models/medication_model.dart

import 'package:flutter/material.dart';

// This class defines the structure for a single medication item.
// Keeping it separate allows you to reuse it across different screens.
class Medication {
  final String name;
  final String dosage;
  final String time;
  final IconData icon;
  final bool isTaken;

  Medication({
    required this.name,
    required this.dosage,
    required this.time,
    required this.icon,
    this.isTaken = false,
  });
}
