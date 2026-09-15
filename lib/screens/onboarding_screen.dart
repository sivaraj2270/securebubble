import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/page_routes.dart';
import 'auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 3; // Matching Step 3 Preferences in media_1789140178332.jpg

  // Preferences state
  bool _floatingBubbleEnabled = true;
  bool _vpnFirewallEnabled = true;
  bool _autoInspectLinks = true;
  String _selectedProtectionLevel = "Balanced Protection (Recommended)";

  final List<String> _protectionLevels = [
    "Balanced Protection (Recommended)",
    "Strict Anti-Phishing Shield",
    "Maximum Paranoid Firewall Mode",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZentraTheme.background,
      body: ZentraTheme.buildAmbientBackground(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    "Welcome to SecureBubble AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Set up your security preferences for real-time protection",
                    style: TextStyle(
                      color: ZentraTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Horizontal Stepper Bar (matching media_1789140178332.jpg)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepItem(stepNum: 1, title: "Profile Info", isCompleted: _currentStep > 1, isActive: _currentStep == 1),
                  _buildStepConnector(isCompleted: _currentStep > 1),
                  _buildStepItem(stepNum: 2, title: "Experience", isCompleted: _currentStep > 2, isActive: _currentStep == 2),
                  _buildStepConnector(isCompleted: _currentStep > 2),
                  _buildStepItem(stepNum: 3, title: "Preferences", isCompleted: _currentStep > 3, isActive: _currentStep == 3),
                  _buildStepConnector(isCompleted: _currentStep > 3),
                  _buildStepItem(stepNum: 4, title: "Finish", isCompleted: _currentStep > 4, isActive: _currentStep == 4),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Center Glassmorphic Setup Form Card (matching media_1789140178332.jpg)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ZentraTheme.buildGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle 1: Floating Bubble Defense
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bubble_chart_rounded, color: ZentraTheme.accentCyan, size: 22),
                              SizedBox(width: 12),
                              Text(
                                "Floating Bubble Scanner",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _floatingBubbleEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: ZentraTheme.primaryBlue,
                            onChanged: (val) => setState(() => _floatingBubbleEnabled = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Toggle 2: Local VPN Firewall
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_rounded, color: ZentraTheme.primaryBlue, size: 22),
                              SizedBox(width: 12),
                              Text(
                                "Local VPN Firewall",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _vpnFirewallEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: ZentraTheme.primaryBlue,
                            onChanged: (val) => setState(() => _vpnFirewallEnabled = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Toggle 3: Auto Link Inspection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.link_rounded, color: ZentraTheme.safeGreen, size: 22),
                              SizedBox(width: 12),
                              Text(
                                "Disguised Link Inspector",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _autoInspectLinks,
                            activeThumbColor: Colors.white,
                            activeTrackColor: ZentraTheme.primaryBlue,
                            onChanged: (val) => setState(() => _autoInspectLinks = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Dropdown: Protection Level
                      const Text(
                        "Shield Protection Mode",
                        style: TextStyle(
                          color: ZentraTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070A12).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ZentraTheme.surfaceBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProtectionLevel,
                            dropdownColor: const Color(0xFF0F172A),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ZentraTheme.textSecondary),
                            isExpanded: true,
                            items: _protectionLevels.map((String level) {
                              return DropdownMenuItem<String>(
                                value: level,
                                child: Text(
                                  level,
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedProtectionLevel = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Continue Action Button (matching media_1789140178332.jpg)
                      ZentraTheme.buildPrimaryButton(
                        text: _currentStep == 4 ? "GET STARTED" : "Continue",
                        onPressed: () {
                          if (_currentStep < 4) {
                            setState(() => _currentStep++);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              SmoothPageRoute(page: const AuthGate()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNum,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? const Color(0xFF2563EB)
                : const Color(0xFF1E293B),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF38BDF8)
                  : (isCompleted ? const Color(0xFF2563EB) : const Color(0xFF334155)),
              width: isActive ? 2.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : Text(
                    "$stepNum",
                    style: TextStyle(
                      color: isActive || isCompleted ? Colors.white : ZentraTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Step $stepNum",
          style: TextStyle(
            color: isActive ? Colors.white : ZentraTheme.textSecondary,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : ZentraTheme.textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 24),
        color: isCompleted ? const Color(0xFF2563EB) : const Color(0xFF334155),
      ),
    );
  }
}
