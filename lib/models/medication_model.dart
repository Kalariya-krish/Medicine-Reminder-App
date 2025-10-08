import 'package:flutter/material.dart';

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
