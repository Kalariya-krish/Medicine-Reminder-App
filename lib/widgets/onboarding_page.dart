import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/onboarding_item.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(item.imagePath, height: 300),
        const SizedBox(height: 40),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.itim(
            fontSize: 20,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
