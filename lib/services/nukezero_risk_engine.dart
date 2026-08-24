import '../models/hyperlink_scan_result.dart';
import 'threat_intel_provider.dart';
import 'phishing_language_analyzer.dart';

class NukezeroRiskOutput {
  final int score; // 0 to 100
  final String statusLabel; // 'SAFE', 'LOW RISK', 'SUSPICIOUS', 'DANGEROUS'
  final List<String> threatsDetected;
  final String recommendation;
  final String providerSummary;

  NukezeroRiskOutput({
    required this.score,
    required this.statusLabel,
    required this.threatsDetected,
    required this.recommendation,
    required this.providerSummary,
  });
}

class NukezeroRiskEngine {
  static NukezeroRiskOutput evaluate({
    required HyperlinkScanResult hyperlinkResult,
    ThreatIntelResult? threatIntel,
    PhishingLanguageResult? languageResult,
  }) {
    int totalScore = 0;
    final threats = <String>[];

    // 1. Hyperlink Mismatch / Deceptive Link Signals (Up to 35 pts)
    if (!hyperlinkResult.domainMatch &&
        hyperlinkResult.visibleDomain.isNotEmpty &&
        hyperlinkResult.actualDomain != "NOT_EXPOSED") {
      totalScore += 35;
      threats.add("Possible phishing URL (Visible domain mismatch: ${hyperlinkResult.visibleDomain} vs ${hyperlinkResult.actualDomain})");
    }

    // 2. Typosquatting / Brand Impersonation (Up to 25 pts)
    if (hyperlinkResult.typosquatting) {
      totalScore += 25;
      threats.add("Lookalike domain / brand impersonation detected");
    }

    // 3. Punycode & Homograph Characters (Up to 20 pts)
    if (hyperlinkResult.punycode) {
      totalScore += 20;
      threats.add("Punycode homograph characters detected (${hyperlinkResult.actualDomain})");
    }

    // 4. IP-Based URL (Up to 20 pts)
    if (hyperlinkResult.ipBased) {
      totalScore += 20;
      threats.add("Raw IP address URL instead of legitimate domain");
    }

    // 5. UserInfo Obfuscation or Percent Encoding (Up to 15 pts)
    if (hyperlinkResult.obfuscated) {
      totalScore += 15;
      threats.add("URL percent-encoding or UserInfo '@' parameter obfuscation");
    }

    // 6. Threat Intel Reputation Signals (Up to 30 pts)
    if (threatIntel != null && threatIntel.isAvailable) {
      if (threatIntel.isMalicious) {
        totalScore += 30;
        threats.add("Threat intelligence reputation warning (${threatIntel.maliciousVotes} vendors flagged)");
      } else if (threatIntel.isSuspicious) {
        totalScore += 15;
        threats.add("Threat intelligence flagged suspicious indicators");
      }
    }

    // 7. Phishing Language Signals (Up to 25 pts)
    if (languageResult != null && languageResult.isPhishingLanguage) {
      totalScore += languageResult.scoreContribution;
      threats.addAll(languageResult.detectedTriggers);
    }

    // 8. Insecure HTTP Signal (Up to 10 pts)
    if (!hyperlinkResult.https && hyperlinkResult.actualUrl != "ACTUAL_URL_NOT_EXPOSED") {
      totalScore += 10;
      threats.add("Unencrypted HTTP link");
    }

    // Clamp score strictly 0 to 100
    final finalScore = totalScore.clamp(0, 100);

    // Map Risk Status Categories
    String statusLabel = "SAFE";
    String recText = "Visible hyperlink and target domain match verified. Safe to proceed with normal caution.";

    if (finalScore >= 76) {
      statusLabel = "DANGEROUS";
      recText = "Do not open this link. Do not enter passwords, OTPs, banking details, or personal information. Verify the service using its official application or website.";
    } else if (finalScore >= 51) {
      statusLabel = "SUSPICIOUS";
      recText = "Exercise extreme caution. Link exhibits suspicious domain structure or urgency manipulation triggers.";
    } else if (finalScore >= 26) {
      statusLabel = "LOW RISK";
      recText = "Low risk indicators detected. Ensure URL matches expected official site before authenticating.";
    }

    if (threats.isEmpty) {
      threats.add("No significant threat indicators detected");
    }

    return NukezeroRiskOutput(
      score: finalScore,
      statusLabel: statusLabel,
      threatsDetected: threats,
      recommendation: recText,
      providerSummary: threatIntel?.providerName ?? "Local Heuristic Engine",
    );
  }
}
