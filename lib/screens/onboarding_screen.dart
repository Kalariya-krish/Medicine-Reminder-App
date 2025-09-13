import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medicine_reminder_system/screens/login_screen.dart';
import 'package:medicine_reminder_system/screens/register_screen.dart';

class OnboardingItem {
  final String imagePath;
  final String title;

  OnboardingItem({required this.imagePath, required this.title});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingData = [
    OnboardingItem(
      imagePath: 'assets/images/onboarding1.png',
      title: 'Get timely notifications so you never forget your medicines.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding2.png',
      title:
          'Log your vitals like BP, sugar, and temperature with easy-to-read graphs.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding3.png',
      title:
          'View your medicine schedule, history, and store emergency contacts in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onboardingData.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return OnboardingPage(item: _onboardingData[index]);
                  },
                ),
              ),

              // Section 2: Page Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => buildDot(index: index),
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6A6A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create an Account',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6A6A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Already Have an Account?',
                    style: GoogleFonts.(
                      color : Colors.white,

                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the dot indicator
  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFFEF6A6A)
            : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// Helper widget for the content of each page in the PageView
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
            height: 1.4, // Line spacing
          ),
        ),
      ],
    );
  }
}
