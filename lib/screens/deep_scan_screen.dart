import 'package:flutter/material.dart';
import '../services/url_extractor.dart';
import '../services/domain_intelligence.dart';
import '../services/heuristic_engine.dart';
import '../services/scam_detector.dart';
import '../services/risk_engine.dart';
import '../services/ai_security_service.dart';
import '../services/virustotal_service.dart';
import '../services/safe_browsing_service.dart';
import '../services/urlscan_service.dart';
import '../models/scan_result.dart';
import '../models/threat_result.dart';
import 'scan_result_screen.dart';

class DeepScanScreen extends StatefulWidget {
  final String? initialUrl;
  const DeepScanScreen({super.key, this.initialUrl});

  @override
  State<DeepScanScreen> createState() => _DeepScanScreenState();
}

class _DeepScanScreenState extends State<DeepScanScreen> {
  late TextEditingController _inputController;
  bool _isScanning = false;
  double _progress = 0.0;
  String _statusText = "Ready for Deep Scan Inspection";

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initialUrl ?? "");
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _startDeepScan();
    }
  }

  Future<void> _startDeepScan() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isScanning = true;
      _progress = 0.1;
      _statusText = "1/5 Extracting & Unshortening Redirect Chains...";
    });

    final urls = UrlExtractor.extractUrls(input);
    final primaryUrl = urls.isNotEmpty ? urls.first : input;
    final urlResult = await UrlExtractor.parseAndExpandUrl(primaryUrl);

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _progress = 0.3;
      _statusText = "2/5 Domain Intelligence & Brand Impersonation Check...";
    });

    final domainResult = DomainIntelligence.analyze(urlResult, input);
    final heuristics = HeuristicEngine.evaluate(urlResult, input);
    final scamInfo = ScamDetector.analyzeText(input);

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _progress = 0.6;
      _statusText = "3/5 Querying VirusTotal v3 & Safe Browsing APIs...";
    });

    final vtData = await VirusTotalService.checkUrlReputation(urlResult.expandedUrl);
    final sbData = await SafeBrowsingService.checkUrl(urlResult.expandedUrl);

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _progress = 0.85;
      _statusText = "4/5 Executing urlscan.io Deep Inspection Sandbox...";
    });

    final usData = await UrlScanService.submitAndAnalyze(urlResult.expandedUrl);

    setState(() {
      _progress = 1.0;
      _statusText = "5/5 Synthesizing Multi-Engine Scoring & AI Analyst Advice...";
    });

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
      urlScanFlagged: usData['flagged'] ?? false,
      urlScanScore: usData['score'] ?? 0,
      urlScanScreenshotUrl: usData['screenshotUrl'] ?? '',
      urlScanAvailable: usData['available'] ?? true,
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
      scanType: "Deep Scan",
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
      setState(() => _isScanning = false);
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
        title: const Text("Deep Scan • Full Forensics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Deep Multi-Engine Inspection",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Runs full pipeline: VirusTotal API v3, Google Safe Browsing, urlscan.io, Domain Intel, Heuristic rules & AI Threat Analysis.",
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inputController,
              enabled: !_isScanning,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter URL to deep scan...",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF18102B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2E1E4E))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
              ),
            ),
            const SizedBox(height: 20),
            if (_isScanning) ...[
              LinearProgressIndicator(value: _progress, backgroundColor: const Color(0xFF18102B), color: const Color(0xFF8B5CF6), minHeight: 8),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ] else
              ElevatedButton(
                onPressed: _startDeepScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("EXECUTE DEEP SCAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
