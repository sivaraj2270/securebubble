import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/hyperlink_threat_engine.dart';
import '../services/scan_history_database.dart';
import '../utils/page_routes.dart';
import 'auth_gate.dart';
import 'activity_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'quick_scan_screen.dart';
import 'circle_scan_screen.dart';
import 'deep_scan_screen.dart';
import 'privacy_guard_screen.dart';
import 'forensics_screen.dart';
import 'ai_assistant_screen.dart';
import 'hyperlink_analysis_screen.dart';
import 'scan_history_screen.dart';
import 'privacy_policy_screen.dart';
import '../models/scan_result.dart';
import '../models/risk_result.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const platform = MethodChannel("nukezero/service");
  bool isBubbleActive = false;
  bool isLoading = false;
  int selectedTab = 0;

  int todayScansCount = 12;
  int threatsDetectedCount = 3;
  int safeLinksCount = 9;
  int dangerousLinksCount = 2;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final history = await ScanHistoryDatabase.getScanHistory();
    if (history.isNotEmpty) {
      setState(() {
        todayScansCount = history.length;
        threatsDetectedCount = history.where((r) => r.status == 'DANGEROUS' || r.status == 'SUSPICIOUS').length;
        safeLinksCount = history.where((r) => r.status == 'SAFE' || r.status == 'LOW RISK').length;
        dangerousLinksCount = history.where((r) => r.status == 'DANGEROUS').length;
      });
    }
  }

  Future<void> _toggleProtection(bool enable) async {
    setState(() => isLoading = true);
    try {
      if (enable) {
        await platform.invokeMethod("startBubble");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("NUKEZERO Shield Active • Draggable Floating Assistant Enabled"),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      } else {
        await platform.invokeMethod("stopBubble");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Protection Disabled"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      setState(() {
        isBubbleActive = enable;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Service Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _runHyperlinkEngine() async {
    setState(() => isLoading = true);
    try {
      final scanResult = await HyperlinkThreatEngine.analyzeCurrentScreen();
      if (mounted) {
        setState(() => isLoading = false);
        Navigator.push(
          context,
          SmoothPageRoute(page: HyperlinkAnalysisScreen(result: scanResult)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hyperlink Engine Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _onNavTap(int index) {
    if (index == selectedTab) return;
    if (index == 1) {
      Navigator.push(context, SmoothPageRoute(page: const ActivityScreen()));
    } else if (index == 2) {
      Navigator.push(context, SmoothPageRoute(page: const AnalyticsScreen()));
    } else if (index == 3) {
      Navigator.push(context, SmoothPageRoute(page: const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();
    final username = (user?.email?.isNotEmpty == true) ? user!.email!.split('@')[0] : "Security Hero";

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, SmoothPageRoute(page: const ProfileScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140C24),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $username 👋",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          isBubbleActive ? "Protection: ACTIVE" : "Protection: INACTIVE",
                          style: TextStyle(
                            fontSize: 12,
                            color: isBubbleActive ? const Color(0xFF4ADE80) : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.push(context, SmoothPageRoute(page: const ScanHistoryScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 22),
                    onPressed: () => Navigator.push(context, SmoothPageRoute(page: const PrivacyPolicyScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      await authService.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthGate()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 6),

                    // Hero Radar Shield Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140C24),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFEF4444)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent).withOpacity(0.06),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent).withOpacity(0.12),
                                  border: Border.all(color: (isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent).withOpacity(0.2), width: 1.5),
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent).withOpacity(0.2),
                                  border: Border.all(color: isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent).withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(isBubbleActive ? Icons.shield_rounded : Icons.shield_outlined, color: Colors.white, size: 36),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "NUKEZERO SHIELD",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Protection Status: ${isBubbleActive ? 'ACTIVE' : 'INACTIVE'}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isBubbleActive ? const Color(0xFF4ADE80) : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Autonomous Scan Before You Click • Floating Shield Assistant",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), height: 1.4),
                          ),
                          const SizedBox(height: 18),
                          InkWell(
                            onTap: isLoading ? null : () => _toggleProtection(!isBubbleActive),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isBubbleActive ? const Color(0xFFEF4444) : Colors.redAccent,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isLoading) ...[
                                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                                    const SizedBox(width: 12),
                                  ] else ...[
                                    Icon(isBubbleActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    isBubbleActive ? "DISABLE PROTECTION" : "ENABLE PROTECTION",
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Today's Scans & Threat Statistics Row
                    Row(
                      children: [
                        _buildStatCard("Today's Scans", "$todayScansCount", const Color(0xFF60A5FA)),
                        const SizedBox(width: 10),
                        _buildStatCard("Threats", "$threatsDetectedCount", const Color(0xFFF59E0B)),
                        const SizedBox(width: 10),
                        _buildStatCard("Safe Links", "$safeLinksCount", const Color(0xFF4ADE80)),
                        const SizedBox(width: 10),
                        _buildStatCard("Dangerous", "$dangerousLinksCount", const Color(0xFFEF4444)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // NUKEZERO Shield Tools Launchers Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("NUKEZERO Security Tools", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("7 Active Modules", style: TextStyle(fontSize: 12, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildToolCard(
                          Icons.link_rounded,
                          "🔗 Hyperlink Engine",
                          "Real visible vs actual URL & typosquatting detection",
                          _runHyperlinkEngine,
                        ),
                        _buildToolCard(
                          Icons.center_focus_strong_rounded,
                          "⭕ Circle-to-Scan",
                          "Assistant-style touch region screen selection",
                          () => Navigator.push(context, SmoothPageRoute(page: const CircleScanScreen())),
                        ),
                        _buildToolCard(
                          Icons.flash_on_rounded,
                          "⚡ Quick Scan",
                          "Fast 300ms OCR, QR & reputation lookup",
                          () => Navigator.push(context, SmoothPageRoute(page: const QuickScanScreen())),
                        ),
                        _buildToolCard(
                          Icons.radar_rounded,
                          "🔬 Deep Scan",
                          "Full VirusTotal, Safe Browsing & urlscan.io pipeline",
                          () => Navigator.push(context, SmoothPageRoute(page: const DeepScanScreen())),
                        ),
                        _buildToolCard(
                          Icons.security_rounded,
                          "🔐 Privacy Guard",
                          "Local PII, OTP, email & secret token scanner",
                          () => Navigator.push(context, SmoothPageRoute(page: const PrivacyGuardScreen())),
                        ),
                        _buildToolCard(
                          Icons.analytics_rounded,
                          "📄 Forensics Mode",
                          "Professional investigation report generator",
                          () {
                            final dummyScan = ScanResult(
                              scanId: "SB-2026-0001",
                              timestamp: DateTime.now(),
                              scanType: "Forensics Audit",
                              extractedText: "Swiggy Streaks Suspended. Verify at trycloudflare.com",
                              qrPayload: "https://trycloudflare.com",
                              riskResult: RiskResult(
                                score: 87,
                                level: RiskLevel.high,
                                threatIntelScore: 30,
                                urlReputationScore: 20,
                                domainSignalsScore: 15,
                                brandImpersonationScore: 15,
                                phishingIndicatorsScore: 7,
                                ocrScamSignalsScore: 0,
                                primaryRiskFactors: const ["VirusTotal Flagged (7 Vendors)", "Cloudflare Phishing Tunnel", "Brand Impersonation Target: Swiggy"],
                              ),
                              aiSummary: "HIGH THREAT WARNING: Severe indicators of phishing and brand impersonation detected.",
                              aiRecommendation: "🛑 DO NOT open the URL or submit credentials. Close the page immediately.",
                              confirmedEvidence: const ["VirusTotal API confirmed 7/90 security vendor detections", "Brand Impersonation: Target claiming to be Swiggy"],
                              privacyAlerts: const ["🔐 PRIVACY ALERT: Authentication token pattern detected."],
                            );
                            Navigator.push(context, SmoothPageRoute(page: ForensicsScreen(scanResult: dummyScan)));
                          },
                        ),
                        _buildToolCard(
                          Icons.psychology_rounded,
                          "🤖 AI Security Assistant",
                          "Conversational AI reasoning on threat evidence",
                          () {
                            final dummyScan = ScanResult(
                              scanId: "SB-2026-0002",
                              timestamp: DateTime.now(),
                              scanType: "AI Assistant",
                              extractedText: "Swiggy Streaks Suspended",
                              qrPayload: "",
                              riskResult: RiskResult(
                                score: 87,
                                level: RiskLevel.high,
                                threatIntelScore: 30,
                                urlReputationScore: 20,
                                domainSignalsScore: 15,
                                brandImpersonationScore: 15,
                                phishingIndicatorsScore: 7,
                                ocrScamSignalsScore: 0,
                                primaryRiskFactors: const ["Phishing Indicator"],
                              ),
                              aiSummary: "High risk phishing attempt.",
                              aiRecommendation: "Do not open link.",
                              confirmedEvidence: const ["Phishing Domain"],
                              privacyAlerts: const [],
                            );
                            Navigator.push(context, SmoothPageRoute(page: AiAssistantScreen(scanResult: dummyScan)));
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF140C24),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF2E1E4E)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, "Home", 0),
                  _buildNavItem(Icons.swap_horiz_rounded, "Activity", 1),
                  GestureDetector(
                    onTap: () => _toggleProtection(!isBubbleActive),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0xFFEF4444), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  _buildNavItem(Icons.pie_chart_outline_rounded, "Analytics", 2),
                  _buildNavItem(Icons.person_outline_rounded, "Profile", 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF140C24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E1E4E)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: (MediaQuery.of(context).size.width - 50) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF140C24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E1E4E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFEF4444), size: 22),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}