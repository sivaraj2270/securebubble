import 'url_result.dart';
import 'domain_result.dart';
import 'threat_result.dart';
import 'risk_result.dart';

class ScanResult {
  final String scanId;
  final DateTime timestamp;
  final String scanType; // 'Quick Scan', 'Circle Scan', 'Deep Scan'
  final String extractedText;
  final String qrPayload;
  final UrlResult? urlResult;
  final DomainResult? domainResult;
  final ThreatResult? threatResult;
  final RiskResult riskResult;
  final String aiSummary;
  final String aiRecommendation;
  final List<String> confirmedEvidence;
  final List<String> privacyAlerts;

  ScanResult({
    required this.scanId,
    required this.timestamp,
    required this.scanType,
    required this.extractedText,
    required this.qrPayload,
    this.urlResult,
    this.domainResult,
    this.threatResult,
    required this.riskResult,
    required this.aiSummary,
    required this.aiRecommendation,
    required this.confirmedEvidence,
    required this.privacyAlerts,
  });

  Map<String, dynamic> toJson() => {
        'scanId': scanId,
        'timestamp': timestamp.toIso8601String(),
        'scanType': scanType,
        'extractedText': extractedText,
        'qrPayload': qrPayload,
        'urlResult': urlResult?.toJson(),
        'domainResult': domainResult?.toJson(),
        'threatResult': threatResult?.toJson(),
        'riskResult': riskResult.toJson(),
        'aiSummary': aiSummary,
        'aiRecommendation': aiRecommendation,
        'confirmedEvidence': confirmedEvidence,
        'privacyAlerts': privacyAlerts,
      };
}
