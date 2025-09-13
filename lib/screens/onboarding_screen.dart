import 'package:flutter/material.dart';
import '../models/onboarding_item.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> pages = [
    OnboardingItem(
      imagePath: "assets/images/onboarding1.png",
      title: "Get timely notifications so you never forget your medicines.",
    ),
    OnboardingItem(
      imagePath: "assets/images/onboarding2.png",
      title: "Log your vitals like BP, sugar, and temperature with graphs.",
    ),
    OnboardingItem(
      imagePath: "assets/images/onboarding3.png",
      title: "View your schedule, history, and store emergency contacts.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => OnboardingPage(item: pages[i]),
                ),
              ),

              // Dots indicator (clickable)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => GestureDetector(
                    onTap: () {
                      _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == i ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? const Color(0xFFEF6A6A)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              CustomButton(
                text: "Create an Account",
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: "Already Have an Account?",
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
