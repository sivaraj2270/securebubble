import 'package:flutter/material.dart';
import '../utils/page_routes.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Autonomous Security Bubble',
      'desc': 'NUKEZERO Shield runs as a draggable floating bubble overlay over WhatsApp, Chrome, SMS, and supported apps for instant "Scan Before You Click" protection.',
      'icon': 'shield_rounded',
    },
    {
      'title': 'Real-Time Hyperlink & QR Defense',
      'desc': 'Detects deceptive links, typosquatting domains, fake UPI payment QRs, and phishing traps directly on your screen without opening suspicious sites.',
      'icon': 'qr_code_scanner_rounded',
    },
    {
      'title': 'Privacy & Consent First',
      'desc': 'Scanning is executed strictly upon explicit user interaction. No silent background screenshots or unauthorized data logging. Processed safely on-device.',
      'icon': 'lock_rounded',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF140C24),
                            border: Border.all(color: const Color(0xFFEF4444), width: 2),
                          ),
                          child: Icon(
                            index == 0 ? Icons.shield_rounded : (index == 1 ? Icons.qr_code_scanner_rounded : Icons.lock_rounded),
                            color: const Color(0xFFEF4444),
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator & Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? const Color(0xFFEF4444) : const Color(0xFF2E1E4E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          SmoothPageRoute(page: const DashboardScreen()),
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
