import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/scan_history_database.dart';
import '../services/admin_service.dart';
import '../services/blocklist_service.dart';
import '../services/vpn_service.dart';
import '../services/url_extractor.dart';
import '../services/domain_intelligence.dart';
import '../services/heuristic_engine.dart';
import '../services/scam_detector.dart';
import '../services/risk_engine.dart';
import '../services/ai_security_service.dart';
import '../services/virustotal_service.dart';
import '../services/safe_browsing_service.dart';
import '../models/scan_result.dart';
import '../models/risk_result.dart';
import '../models/threat_result.dart';
import '../utils/page_routes.dart';
import '../main.dart';
import 'auth_gate.dart';
import 'ai_assistant_screen.dart';
import 'scan_history_screen.dart';
import 'scan_result_screen.dart';
import 'blocklist_screen.dart';
import 'firewall_screen.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';
import 'quick_scan_screen.dart';
import '../widgets/nukezero_logo_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const platform = MethodChannel("nukezero/service");

  final TextEditingController _urlController = TextEditingController();

  bool isVpnActive = false;
  bool isBubbleActive = false;
  bool isDnsConnected = false;
  bool isLoadingVpn = false;
  bool isLoadingBubble = false;
  bool isUrlScanning = false;
  bool _isStatsLoading = false;
  String _selectedTab = "Insights";

  final List<String> _tabs = [
    "Overview",
    "Insights",
    "Direct",
    "Conversations",
    "Protection",
    "DNS Shield"
  ];

  final authService = AuthService();
  int totalScans = 0;
  int safeCount = 0;
  int suspiciousCount = 0;
  int dangerousCount = 0;

  @override
  void initState() {
    super.initState();
    _autoConnectDnsAndLoadStats();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Automatically connects DNS Server, starts VPN, and loads stats on startup
  Future<void> _autoConnectDnsAndLoadStats() async {
    await _loadStats();
    await _autoConnectServices();
  }

  Future<void> _autoConnectServices() async {
    try {
      // 1. Sync blocklist to native Android engine
      await BlocklistService.syncNativeBlocklist();

      // 2. Check if VPN is running, start automatically if stopped
      final running = await VpnServiceBridge.isVpnRunning();
      if (!running) {
        final started = await VpnServiceBridge.startVpn();
        if (mounted) setState(() => isVpnActive = started);
      } else {
        if (mounted) setState(() => isVpnActive = true);
      }

      // 3. Query Technitium DNS Backend status
      final dnsStatus = await AdminService().getDnsStatus();
      if (mounted) {
        setState(() {
          isDnsConnected = dnsStatus["status"] == "success" || isVpnActive;
        });
      }
    } catch (e) {
      debugPrint("Auto DNS Connect Error: $e");
    }
  }

  Future<void> _loadStats() async {
    if (_isStatsLoading) return;
    _isStatsLoading = true;

    try {
      final results = await Future.wait([
        ScanHistoryDatabase.getScanHistory(),
        BlocklistService.getBlocklist(),
        AdminService().getBlockedDomains(),
      ]);

      if (!mounted) return;

      final list = results[0] as List<dynamic>;
      final blocklist = results[1] as List<dynamic>;
      final technitiumBlocked = results[2] as List<dynamic>;

      final uniqueBlockedDomains = <String>{
        ...blocklist.map((e) => (e.domain as String).toLowerCase()),
        ...technitiumBlocked.map((e) => (e is String ? e : (e["domain"] ?? e["name"] ?? "")).toString().toLowerCase()),
      }..remove("");

      final dangerousScanCount = list.where((item) => item.status == "DANGEROUS" || item.status == "HIGH RISK").length;
      final totalBlocked = dangerousScanCount > uniqueBlockedDomains.length
          ? dangerousScanCount
          : uniqueBlockedDomains.length;

      setState(() {
        totalScans = list.length > totalBlocked ? list.length : totalBlocked;
        safeCount = list.where((item) => item.status == "SAFE").length;
        suspiciousCount = list.where((item) => item.status == "SUSPICIOUS" || item.status == "LOW RISK").length;
        dangerousCount = totalBlocked;
      });
    } catch (e) {
      debugPrint("Stats loading error: $e");
    } finally {
      _isStatsLoading = false;
    }
  }

  /// Toggle Floating Bubble Screen Overlay
  Future<void> _toggleBubbleService() async {
    setState(() => isLoadingBubble = true);
    try {
      if (isBubbleActive) {
        await platform.invokeMethod("stopBubble");
        setState(() => isBubbleActive = false);
      } else {
        await platform.invokeMethod("startBubble");
        setState(() => isBubbleActive = true);
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to toggle bubble service: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Floating Bubble Error: ${e.message}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingBubble = false);
    }
  }

  /// Run Direct URL Scan from Dashboard
  Future<void> _scanUrlDirect(String urlInput) async {
    final input = urlInput.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter or paste a URL to scan."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => isUrlScanning = true);

    try {
      final urls = UrlExtractor.extractUrls(input);
      final primaryUrl = urls.isNotEmpty ? urls.first : input;
      final urlResult = await UrlExtractor.parseAndExpandUrl(primaryUrl);

      final domainResult = DomainIntelligence.analyze(urlResult, input);
      final heuristics = HeuristicEngine.evaluate(urlResult, input);
      final scamInfo = ScamDetector.analyzeText(input);

      final vtData = await VirusTotalService.checkUrlReputation(urlResult.expandedUrl);
      final sbData = await SafeBrowsingService.checkUrl(urlResult.expandedUrl);

      final threatResult = ThreatResult(
        vtMalicious: vtData['malicious'] ?? 0,
        vtSuspicious: vtData['suspicious'] ?? 0,
        vtHarmless: vtData['harmless'] ?? 0,
        vtUndetected: vtData['undetected'] ?? 0,
        vtAvailable: vtData['available'] ?? true,
        vtErrorMessage: vtData['errorMessage'] ?? '',
        safeBrowsingFlagged: sbData['flagged'] ?? false,
        safeBrowsingThreatType: sbData['threatType'] ?? 'None',
        safeBrowsingAvailable: sbData['available'] ?? true,
        urlScanFlagged: false,
        urlScanScore: 0,
        urlScanScreenshotUrl: '',
        urlScanAvailable: true,
        heuristicFindings: heuristics,
      );

      final riskResult = RiskEngine.calculateRiskScore(
        threatResult: threatResult,
        domainResult: domainResult,
        heuristicFindings: heuristics,
        scamType: scamInfo.scamType,
      );

      final aiAnalysis = AiSecurityService.generateAnalysis(
        riskResult: riskResult,
        domainResult: domainResult,
        threatResult: threatResult,
        rawText: input,
      );

      final scanResult = ScanResult(
        scanId: "SB-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
        timestamp: DateTime.now(),
        scanType: "Dashboard Quick Scan",
        extractedText: input,
        qrPayload: primaryUrl,
        urlResult: urlResult,
        domainResult: domainResult,
        threatResult: threatResult,
        riskResult: riskResult,
        aiSummary: aiAnalysis.summary,
        aiRecommendation: aiAnalysis.recommendation,
        confirmedEvidence: aiAnalysis.confirmedEvidence,
        privacyAlerts: const [],
      );

      await ScanHistoryDatabase.addScanRecord(
        ScanRecord(
          id: scanResult.scanId,
          timestamp: scanResult.timestamp,
          urlOrItem: scanResult.extractedText,
          riskScore: scanResult.riskResult.score,
          status: scanResult.riskResult.levelText,
          threatCategory: scanResult.scanType,
        ),
      );

      if (mounted) {
        _urlController.clear();
        Navigator.push(
          context,
          SmoothPageRoute(page: ScanResultScreen(scanResult: scanResult)),
        ).then((_) => _loadStats());
      }
    } catch (e) {
      debugPrint("Scan URL error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error analyzing URL: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isUrlScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark;
        final bgColor = dark ? const Color(0xFF0C0D12) : const Color(0xFFF1F5F9);
        final cardColor = dark ? const Color(0xFF161720) : Colors.white;
        final primaryText = dark ? Colors.white : const Color(0xFF0F172A);
        final secondaryText = dark ? const Color(0xFF8E92A6) : const Color(0xFF64748B);
        final borderColor = dark ? const Color(0xFF222432) : const Color(0xFFE2E8F0);

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildSideBarDrawer(context),
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      // Profile Avatar
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                              ),
                              child: const NukeZeroLogoWidget(size: 34),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isVpnActive ? const Color(0xFF10B981) : Colors.amber,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bgColor, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title Dropdown ("NukeZero")
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Row(
                          children: [
                            Text(
                              "NukeZero",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: primaryText,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, color: secondaryText, size: 20),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Today Date Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1E202C) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          "${DateTime.now().day}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Notification Bell Icon
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          SmoothPageRoute(page: const ScanHistoryScreen()),
                        ).then((_) => _loadStats()),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF1E202C) : const Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                              ),
                              child: Icon(Icons.notifications_outlined, color: primaryText, size: 18),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal Sub-Header Filter Bar
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isSelected = tab == _selectedTab;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = tab);
                          if (tab == "DNS Shield" || tab == "Protection") {
                            Navigator.push(
                              context,
                              SmoothPageRoute(page: const FirewallScreen()),
                            ).then((_) => _loadStats());
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (dark ? const Color(0xFF272938) : const Color(0xFF0F172A))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : secondaryText,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Scrollable Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔍 FEATURE 1: Instant URL Threat Scanner Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "URL Threat Scanner",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "VIRUSTOTAL + AI",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF38BDF8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _urlController,
                                      style: TextStyle(color: primaryText, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: "Paste or type URL (e.g. https://example.com)...",
                                        hintStyle: TextStyle(color: secondaryText, fontSize: 12),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        filled: true,
                                        fillColor: dark ? const Color(0xFF0F1018) : const Color(0xFFF1F5F9),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                                        ),
                                      ),
                                      onSubmitted: (val) => _scanUrlDirect(val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Paste Clipboard Button
                                  IconButton(
                                    onPressed: () async {
                                      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                                      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
                                        _urlController.text = clipboardData.text!;
                                      }
                                    },
                                    icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF38BDF8), size: 20),
                                    tooltip: "Paste from Clipboard",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  icon: isUrlScanning
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    isUrlScanning ? "ANALYZING THREATS..." : "SCAN URL NOW",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: isUrlScanning ? null : () => _scanUrlDirect(_urlController.text),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🟢 FEATURE 2: Floating Bubble Overlay Protection Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isBubbleActive ? const Color(0xFF10B981) : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isBubbleActive ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isBubbleActive ? Icons.bubble_chart_rounded : Icons.bubble_chart_outlined,
                                  color: isBubbleActive ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Floating Bubble Shield",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isBubbleActive
                                          ? "🟢 Bubble ON • Active on phone screen"
                                          : "⚪ Bubble OFF • Tap switch to turn ON",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isBubbleActive ? const Color(0xFF10B981) : secondaryText,
                                        fontWeight: isBubbleActive ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isLoadingBubble
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Switch(
                                      activeThumbColor: const Color(0xFF10B981),
                                      inactiveThumbColor: secondaryText,
                                      value: isBubbleActive,
                                      onChanged: (_) => _toggleBubbleService(),
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Row 1: Top 2 Cards (Geo & Demographic Arc Gauge)
                        Row(
                          children: [
                            // Left Card: Geo / Protection Status
                            Expanded(
                              child: Container(
                                height: 160,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, color: secondaryText, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Geo",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryText,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: 18,
                                          height: 13,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(2),
                                            color: const Color(0xFF2563EB),
                                          ),
                                          child: const Center(
                                            child: Text("🇺🇸", style: TextStyle(fontSize: 8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      isVpnActive ? "97%" : "84%",
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: primaryText,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Most of the threat traffic filtered from USA",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: secondaryText,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Right Card: Demographic / Shield Gauge Arc
                            Expanded(
                              child: Container(
                                height: 160,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.groups_outlined, color: secondaryText, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Demographic",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Center(
                                      child: SizedBox(
                                        width: 110,
                                        height: 55,
                                        child: CustomPaint(
                                          painter: _ArcGaugePainter(
                                            progress: isVpnActive ? 0.94 : 0.75,
                                            gradientColors: const [
                                              Color(0xFF38BDF8),
                                              Color(0xFF8B5CF6),
                                              Color(0xFFEC4899),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "98%",
                                                style: TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryText,
                                                ),
                                              ),
                                              Text(
                                                "Safe Score",
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: secondaryText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Safe", style: TextStyle(fontSize: 10, color: secondaryText)),
                                        Text("Blocked", style: TextStyle(fontSize: 10, color: secondaryText)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Middle 2 Cards (Audience activity & Followers online)
                        Row(
                          children: [
                            // Left Card: Audience activity
                            Expanded(
                              child: Container(
                                height: 160,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, color: secondaryText, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Audience activity",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "5pm",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: primaryText,
                                      ),
                                    ),
                                    const Spacer(),
                                    Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Container(
                                          height: 4,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: dark ? const Color(0xFF282A38) : const Color(0xFFCBD5E1),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Container(
                                          height: 4,
                                          width: 75,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF38BDF8), Color(0xFF8B5CF6)],
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Positioned(
                                          left: 70,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Best time to scan today between 5 & 6pm",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: secondaryText,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Right Card: Followers online
                            Expanded(
                              child: Container(
                                height: 160,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.sensors_rounded, color: secondaryText, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Followers online",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "3-4pm",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: primaryText,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      height: 48,
                                      width: double.infinity,
                                      child: CustomPaint(
                                        painter: _CurveChartPainter(
                                          lineColor: const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Section Header: Engagement
                        Text(
                          "Engagement",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Row 3: 3 Metric Stat Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: "⚡ ER",
                                value: "11.3%",
                                badge: "▲ 1.32%",
                                cardBg: cardColor,
                                borderColor: borderColor,
                                primaryText: primaryText,
                                secondaryText: secondaryText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                title: "((•)) ER Reach",
                                value: "7.2%",
                                badge: "▲ 0.3%",
                                cardBg: cardColor,
                                borderColor: borderColor,
                                primaryText: primaryText,
                                secondaryText: secondaryText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                title: "👁 ER",
                                value: "5.3k",
                                badge: "▲ 0.2%",
                                cardBg: cardColor,
                                borderColor: borderColor,
                                primaryText: primaryText,
                                secondaryText: secondaryText,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Downloadable Insight Report Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: dark ? const Color(0xFF1B1C28) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.description_rounded, color: Color(0xFF8B5CF6), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Insight Report",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Download & share your cyber threat report",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: secondaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("📄 Cyber Threat Insight Report generated & exported!"),
                                      backgroundColor: Color(0xFF8B5CF6),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B5CF6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Dock Bottom Navigation Bar
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1B1C28) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: dark ? const Color(0xFF2E3146) : const Color(0xFF334155),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Quick Scan Action
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    SmoothPageRoute(page: const QuickScanScreen()),
                  ).then((_) => _loadStats()),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Create",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Home Action (Active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.home_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Home",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // AI Hub / Admin Portal Action
                InkWell(
                  onTap: () {
                    final dummyScanResult = ScanResult(
                      scanId: "ai_dock",
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
                        primaryRiskFactors: ["NukeZero AI Active"],
                      ),
                      aiSummary: "NukeZero Protection active.",
                      aiRecommendation: "Proceed with standard awareness.",
                      confirmedEvidence: [],
                      privacyAlerts: [],
                    );
                    Navigator.push(
                      context,
                      SmoothPageRoute(page: AiAssistantScreen(scanResult: dummyScanResult)),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded, color: Colors.grey.shade400, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "AI Hub",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badge,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: secondaryText, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryText),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_drop_up, color: Color(0xFF10B981), size: 14),
              Text(
                badge.replaceAll("▲ ", ""),
                style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideBarDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "user@nukezero.ai";
    final userName = user?.displayName ?? (userEmail.contains('@') ? userEmail.split('@')[0] : 'User');

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        final isDark = currentTheme == ThemeMode.dark;
        final drawerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return Drawer(
          backgroundColor: drawerBg,
          child: SafeArea(
            child: Column(
              children: [
                // User Header Profile Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NukeZeroLogoWidget(size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: TextStyle(fontSize: 12, color: subTextColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text(
                              "NUKEZERO PRO ACTIVE",
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
                        title: "User Settings",
                        subtitle: "Preferences & Profile",
                        color: const Color(0xFF38BDF8),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, SmoothPageRoute(page: const ProfileScreen()));
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.admin_panel_settings_rounded,
                        title: "Admin Portal",
                        subtitle: "Technitium DNS & Server Control",
                        color: const Color(0xFF8B5CF6),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          if (AdminService().isAuthenticated) {
                            Navigator.push(context, SmoothPageRoute(page: const AdminDashboardScreen()));
                          } else {
                            Navigator.push(context, SmoothPageRoute(page: const AdminLoginScreen()));
                          }
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.block_rounded,
                        title: "Block List",
                        subtitle: "System-wide blocked domains",
                        color: const Color(0xFFEF4444),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, SmoothPageRoute(page: const BlocklistScreen())).then((_) => _loadStats());
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.chat_bubble_rounded,
                        title: "AI Chatbot",
                        subtitle: "Interactive Cyber Assistant",
                        color: const Color(0xFF10B981),
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onTap: () {
                          Navigator.pop(context);
                          final dummyScanResult = ScanResult(
                            scanId: "ai_drawer",
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
                              primaryRiskFactors: ["NukeZero AI Active"],
                            ),
                            aiSummary: "NukeZero Protection active.",
                            aiRecommendation: "Proceed with standard awareness.",
                            confirmedEvidence: [],
                            privacyAlerts: [],
                          );
                          Navigator.push(context, SmoothPageRoute(page: AiAssistantScreen(scanResult: dummyScanResult)));
                        },
                      ),

                      Divider(color: borderColor, height: 24, indent: 8, endIndent: 8),

                      // Dark Mode / White Mode Theme Switcher
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: SwitchListTile(
                          activeThumbColor: const Color(0xFF38BDF8),
                          inactiveThumbColor: const Color(0xFFF59E0B),
                          secondary: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                          ),
                          title: Text(
                            isDark ? "Dark Mode" : "White Mode",
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            isDark ? "Switch to White theme" : "Switch to Dark theme",
                            style: TextStyle(color: subTextColor, fontSize: 11),
                          ),
                          value: isDark,
                          onChanged: (val) {
                            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Logout Action Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "LOGOUT",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: subTextColor, fontSize: 11),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
        onTap: onTap,
      ),
    );
  }
}

/// Semicircular Arc Gauge CustomPainter
class _ArcGaugePainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _ArcGaugePainter({
    required this.progress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 8;

    // Track Paint (Background Arc)
    final trackPaint = Paint()
      ..color = const Color(0xFF272938)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Active Arc Gradient Paint
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: gradientColors,
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      math.pi,
      sweepAngle,
      false,
      activePaint,
    );

    // End indicator dot
    final dotAngle = math.pi + sweepAngle;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Smooth Bell Curve Line CustomPainter
class _CurveChartPainter extends CustomPainter {
  final Color lineColor;

  _CurveChartPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height * 0.8);
    path.cubicTo(
      width * 0.3, height * 0.8,
      width * 0.45, height * 0.1,
      width * 0.65, height * 0.1,
    );
    path.cubicTo(
      width * 0.85, height * 0.1,
      width * 0.95, height * 0.85,
      width, height * 0.85,
    );

    // Draw Line
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, paint);

    // Key points (white dots)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final p1 = Offset(width * 0.55, height * 0.25);
    final p2 = Offset(width * 0.75, height * 0.5);

    canvas.drawCircle(p1, 6, glowPaint);
    canvas.drawCircle(p1, 3.5, dotPaint);

    canvas.drawCircle(p2, 6, glowPaint);
    canvas.drawCircle(p2, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}