import 'package:flutter/material.dart';
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

class QuickScanScreen extends StatefulWidget {
  const QuickScanScreen({super.key});

  @override
  State<QuickScanScreen> createState() => _QuickScanScreenState();
}

class _QuickScanScreenState extends State<QuickScanScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  Future<void> _runQuickScan() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);

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

    final aiSummary = AiSecurityService.generateAnalysis(
      riskResult: riskResult,
      domainResult: domainResult,
      threatResult: threatResult,
      rawText: input,
    );

    final scanResult = ScanResult(
      scanId: "SB-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      timestamp: DateTime.now(),
      scanType: "Quick Scan",
      extractedText: input,
      qrPayload: urls.isNotEmpty ? urls.first : "",
      urlResult: urlResult,
      domainResult: domainResult,
      threatResult: threatResult,
      riskResult: riskResult,
      aiSummary: aiSummary.summary,
      aiRecommendation: aiSummary.recommendation,
      confirmedEvidence: aiSummary.confirmedEvidence,
      privacyAlerts: const [],
    );

    if (mounted) {
      setState(() => _isLoading = false);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: const Text("Quick Scan • Fast Reputation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Inspect URL, Text, or Domain",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Paste any suspicious link, message, or domain below for fast local heuristics & VirusTotal reputation lookup.",
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inputController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Paste link or message here (e.g. trycloudflare.com/auth)...",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF18102B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2E1E4E))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _runQuickScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                  : const Text("RUN QUICK SCAN (300ms)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
