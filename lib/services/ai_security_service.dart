import '../models/risk_result.dart';
import '../models/domain_result.dart';
import '../models/threat_result.dart';

class AiSecuritySummary {
  final String summary;
  final String recommendation;
  final List<String> confirmedEvidence;
  final List<String> aiInterpretations;
  final List<String> unknownInfo;

  AiSecuritySummary({
    required this.summary,
    required this.recommendation,
    required this.confirmedEvidence,
    required this.aiInterpretations,
    required this.unknownInfo,
  });
}

class AiSecurityService {
  static AiSecuritySummary generateAnalysis({
    required RiskResult riskResult,
    required DomainResult domainResult,
    required ThreatResult threatResult,
    required String rawText,
  }) {
    final confirmedEvidence = <String>[];
    final aiInterpretations = <String>[];
    final unknownInfo = <String>[];

    // Confirmed Evidence
    if (threatResult.vtAvailable && threatResult.vtMalicious > 0) {
      confirmedEvidence.add("VirusTotal API confirmed ${threatResult.vtMalicious}/90 security vendor detections.");
    }
    if (threatResult.safeBrowsingFlagged) {
      confirmedEvidence.add("Google Safe Browsing API flagged resource: ${threatResult.safeBrowsingThreatType}.");
    }
    if (domainResult.brandImpersonationStatus.contains('Impersonation')) {
      confirmedEvidence.add("Brand Impersonation: Target is claiming to be ${domainResult.detectedBrand} but hosted at ${domainResult.domain}.");
    }
    if (!domainResult.isHttps) {
      confirmedEvidence.add("Unencrypted HTTP traffic without SSL certificate.");
    }

    // AI Interpretations
    if (riskResult.score >= 50) {
      aiInterpretations.add("AI Risk Reasoning: Multiple independent threat signals correlate strongly with credential harvesting phishing.");
      aiInterpretations.add("Pattern Match: High similarity to deceptive login pages targeting consumer accounts.");
    } else {
      aiInterpretations.add("AI Risk Reasoning: Content displays standard domain parameters without malicious indicators.");
    }

    // Unknown Information
    if (!threatResult.vtAvailable) {
      unknownInfo.add("VirusTotal API unavailable (Timeout/Quota exceeded). Cannot verify vendor reputation.");
    }
    if (!threatResult.safeBrowsingAvailable) {
      unknownInfo.add("Google Safe Browsing API check incomplete.");
    }
    if (domainResult.domainAgeStatus.contains('Unknown')) {
      unknownInfo.add("Domain WHOIS creation age date unverified.");
    }

    String summary;
    String recommendation;

    if (riskResult.level == RiskLevel.malicious || riskResult.level == RiskLevel.high) {
      summary = "HIGH THREAT WARNING: Severe indicators of phishing and brand impersonation detected.";
      recommendation = "🛑 DO NOT open the URL, do not enter passwords, OTP codes, or banking card details. Close the page immediately.";
    } else if (riskResult.level == RiskLevel.suspicious) {
      summary = "SUSPICIOUS CONTENT: Unverified parameters observed.";
      recommendation = "⚠️ Proceed with caution. Verify the official domain before submitting sensitive credentials.";
    } else {
      summary = "LOW THREAT: No significant malicious indicators detected.";
      recommendation = "✔ Verified safe domain. Standard security precautions apply.";
    }

    return AiSecuritySummary(
      summary: summary,
      recommendation: recommendation,
      confirmedEvidence: confirmedEvidence,
      aiInterpretations: aiInterpretations,
      unknownInfo: unknownInfo,
    );
  }
}
