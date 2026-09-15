import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/hyperlink_threat_engine.dart';
import '../services/scan_history_database.dart';
import '../utils/page_routes.dart';
import '../theme/app_theme.dart';
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
import 'blocklist_screen.dart';
import 'firewall_screen.dart';
import '../models/scan_result.dart';
import '../models/risk_result.dart';
import '../models/hyperlink_scan_result.dart';

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

  final authService = AuthService();
  int totalScans = 0;
  int safeCount = 0;
  int suspiciousCount = 0;
  int dangerousCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final list = await ScanHistoryDatabase.getScanHistory();
    setState(() {
      totalScans = list.length;
      safeCount = list.where((item) => item.status == "SAFE").length;
      suspiciousCount = list.where((item) => item.status == "SUSPICIOUS" || item.status == "LOW RISK").length;
      dangerousCount = list.where((item) => item.status == "DANGEROUS" || item.status == "HIGH RISK").length;
    });
  }

  Future<void> toggleBubbleService() async {
    setState(() => isLoading = true);
    try {
      if (isBubbleActive) {
        await platform.invokeMethod("stopBubble");
        setState(() => isBubbleActive = false);
      } else {
        await platform.invokeMethod("startBubble");
        setState(() => isBubbleActive = true);
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to toggle service: ${e.message}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Agent';

    return Scaffold(
      backgroundColor: ZentraTheme.background,
      body: ZentraTheme.buildAmbientBackground(
        child: Column(
          children: [
            // Top Zentra Navigation Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ZentraTheme.primaryBlue.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(fontSize: 12, color: ZentraTheme.textSecondary),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.security_rounded, color: Color(0xFF38BDF8), size: 22),
                    onPressed: () => Navigator.push(context, SmoothPageRoute(page: const FirewallScreen())),
                    tooltip: "VPN Firewall",
                  ),
                  IconButton(
                    icon: const Icon(Icons.block, color: Color(0xFFEF4444), size: 20),
                    onPressed: () => Navigator.push(context, SmoothPageRoute(page: const BlocklistScreen())),
                    tooltip: "Blocklist",
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.push(context, SmoothPageRoute(page: const ScanHistoryScreen())),
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

            // Scrollable Content Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // AI Action Orb Floating Hero Card
                    ZentraTheme.buildGlassCard(
                      borderColor: isBubbleActive ? const Color(0xFF38BDF8) : ZentraTheme.surfaceBorder,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Rainbow Ambient Ring
                              Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF8B5CF6),
                                      Color(0xFFF59E0B),
                                      Color(0xFF10B981),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                ),
                              ),
                              // Pitch Black Core Orb Center
                              Container(
                                width: 122,
                                height: 122,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF060911),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // AI Action Left Capsule Eye
                                    Container(
                                      width: 10,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // AI Action Right Capsule Eye
                                    Container(
                                      width: 10,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "NUKEZERO AI Floating Shield",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isBubbleActive
                                ? "🟢 Autonomous Overlay Active • Tap Orb to Scan"
                                : "⚪ Protection Inactive • Tap below to enable",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isBubbleActive ? const Color(0xFF4ADE80) : ZentraTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 22),

                          ZentraTheme.buildPrimaryButton(
                            text: isBubbleActive ? "DISABLE PROTECTION" : "ENABLE PROTECTION",
                            isLoading: isLoading,
                            icon: isBubbleActive ? Icons.power_settings_new_rounded : Icons.shield_rounded,
                            onPressed: toggleBubbleService,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Security Statistics Overview
                    Row(
                      children: [
                        Expanded(child: _buildStatWidget("Total Scans", "$totalScans", const Color(0xFF38BDF8))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatWidget("Clean Links", "$safeCount", const Color(0xFF4ADE80))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatWidget("Threats Blocked", "$dangerousCount", const Color(0xFFEF4444))),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Security Tools Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Cyber Analysis Tools",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildToolTile(
                      context,
                      title: "Manual URL Scanner",
                      subtitle: "Inspect links, IP addresses & domain spoofing",
                      icon: Icons.link_rounded,
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        final dummyScan = HyperlinkScanResult(
                          visibleText: "Inspect URL",
                          actualUrl: "https://example.com",
                          normalizedUrl: "https://example.com",
                          finalUrl: "https://example.com",
                          sourceApp: "Manual Scanner",
                          visibleDomain: "example.com",
                          actualDomain: "example.com",
                          domainMatch: true,
                          https: true,
                          ipBased: false,
                          punycode: false,
                          typosquatting: false,
                          obfuscated: false,
                          shortened: false,
                          redirectDetected: false,
                          detectionType: "MANUAL_SCAN",
                          riskLevel: "SAFE",
                          confidence: 1.0,
                          reasons: ["Ready to scan custom input."],
                        );
                        Navigator.push(context, SmoothPageRoute(page: HyperlinkAnalysisScreen(result: dummyScan)));
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildToolTile(
                      context,
                      title: "QR Code Lens Scanner",
                      subtitle: "Decode payment QR payloads & logo-centered QR codes",
                      icon: Icons.qr_code_scanner_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(context, SmoothPageRoute(page: const CircleScanScreen())),
                    ),
                    const SizedBox(height: 10),

                    _buildToolTile(
                      context,
                      title: "Deep VirusTotal Cloud Scan",
                      subtitle: "Query 90+ antivirus security vendor engines",
                      icon: Icons.biotech_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(context, SmoothPageRoute(page: const DeepScanScreen())),
                    ),
                    const SizedBox(height: 10),

                    _buildToolTile(
                      context,
                      title: "AI Cyber Assistant",
                      subtitle: "Ask questions & learn scam defense strategies",
                      icon: Icons.psychology_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        final dummyScanResult = ScanResult(
                          scanId: "ai_1",
                          timestamp: DateTime.now(),
                          scanType: "AI Assistant",
                          extractedText: "System Protection",
                          qrPayload: "",
                          riskResult: RiskResult(
                            score: 5,
                            level: RiskLevel.low,
                            threatIntelScore: 0,
                            urlReputationScore: 0,
                            domainSignalsScore: 0,
                            brandImpersonationScore: 0,
                            phishingIndicatorsScore: 0,
                            ocrScamSignalsScore: 0,
                            primaryRiskFactors: ["AI Protection Active"],
                          ),
                          aiSummary: "AI Cyber Protection is active.",
                          aiRecommendation: "Proceed with standard awareness.",
                          confirmedEvidence: [],
                          privacyAlerts: [],
                        );
                        Navigator.push(context, SmoothPageRoute(page: AiAssistantScreen(scanResult: dummyScanResult)));
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatWidget(String label, String value, Color accentColor) {
    return ZentraTheme.buildGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderColor: accentColor.withOpacity(0.3),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: ZentraTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ZentraTheme.buildGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: ZentraTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 16),
          ],
        ),
      ),
    );
  }
}