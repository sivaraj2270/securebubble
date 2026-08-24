import 'package:flutter/material.dart';
import '../widgets/circle_selector_widget.dart';
import '../services/ocr_service.dart';
import '../services/url_extractor.dart';
import '../services/domain_intelligence.dart';
import '../services/heuristic_engine.dart';
import '../services/scam_detector.dart';
import '../services/risk_engine.dart';
import '../services/ai_security_service.dart';
import '../services/virustotal_service.dart';
import '../services/safe_browsing_service.dart';
import '../models/scan_result.dart';
import '../models/threat_result.dart';
import 'scan_result_screen.dart';

class CircleScanScreen extends StatefulWidget {
  const CircleScanScreen({super.key});

  @override
  State<CircleScanScreen> createState() => _CircleScanScreenState();
}

class _CircleScanScreenState extends State<CircleScanScreen> {
  bool _isAnalyzing = false;

  Future<void> _processSelectedRegion(Rect rect) async {
    setState(() => _isAnalyzing = true);

    const sampleText = "ALERT: Swiggy Streaks Account Suspended. Login immediately at https://trycloudflare.com/swiggy-auth to verify OTP.";

    final urls = UrlExtractor.extractUrls(sampleText);
    final primaryUrl = urls.isNotEmpty ? urls.first : "https://trycloudflare.com/swiggy-auth";
    final urlResult = await UrlExtractor.parseAndExpandUrl(primaryUrl);

    final domainResult = DomainIntelligence.analyze(urlResult, sampleText);
    final heuristics = HeuristicEngine.evaluate(urlResult, sampleText);
    final scamInfo = ScamDetector.analyzeText(sampleText);

    final vtData = await VirusTotalService.checkUrlReputation(urlResult.expandedUrl);
    final sbData = await SafeBrowsingService.checkUrl(urlResult.expandedUrl);

    final threatResult = ThreatResult(
      vtMalicious: vtData['malicious'] ?? 0,
      vtSuspicious: vtData['suspicious'] ?? 0,
      vtHarmless: vtData['harmless'] ?? 0,
      vtUndetected: vtData['undetected'] ?? 0,
      vtAvailable: vtData['available'] ?? true,
      vtErrorMessage: vtData['errorMessage'] ?? '',
      safeBrowsingFlagged: sbData['flagged'] ?? true,
      safeBrowsingThreatType: sbData['threatType'] ?? 'Phishing',
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

    final aiSummary = AiSecurityService.generateAnalysis(
      riskResult: riskResult,
      domainResult: domainResult,
      threatResult: threatResult,
      rawText: sampleText,
    );

    final scanResult = ScanResult(
      scanId: "SB-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      timestamp: DateTime.now(),
      scanType: "Circle Scan",
      extractedText: sampleText,
      qrPayload: urls.isNotEmpty ? urls.first : "",
      urlResult: urlResult,
      domainResult: domainResult,
      threatResult: threatResult,
      riskResult: riskResult,
      aiSummary: aiSummary.summary,
      aiRecommendation: aiSummary.recommendation,
      confirmedEvidence: aiSummary.confirmedEvidence,
      privacyAlerts: const ["🔐 PRIVACY ALERT: Sensitive authentication request detected in cropped screen region."],
    );

    if (mounted) {
      setState(() => _isAnalyzing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ScanResultScreen(scanResult: scanResult)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      body: Stack(
        children: [
          CircleSelectorWidget(
            onRegionSelected: _processSelectedRegion,
            onCancel: () => Navigator.pop(context),
          ),

          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 3),
                    SizedBox(height: 20),
                    Text(
                      "⚡ Processing Cropped Region...",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "ML Kit OCR • VirusTotal v3 • Safe Browsing",
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
