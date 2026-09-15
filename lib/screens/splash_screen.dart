import 'package:flutter/material.dart';
import '../utils/page_routes.dart';
import '../widgets/app_logo_widget.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          SmoothPageRoute(page: const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZentraTheme.background,
      body: ZentraTheme.buildAmbientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Geometric Hexagon Logo with pulsing scale animation (matching media_1789140159280.jpg & media_1789140023331.jpg)
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const HexagonLogoWidget(
                    size: 130,
                    badgeText: "AI",
                    showContainer: true,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Sparkling Blue AI Stars + SecureBubble AI Title (matching media_1789140023331.jpg)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "SecureBubble AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "®",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Text(
                "Autonomous Phishing & Threat Intelligence",
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 60),

              // Sleek Loading Progress Indicator
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    backgroundColor: Color(0xFF1E293B),
                    minHeight: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
