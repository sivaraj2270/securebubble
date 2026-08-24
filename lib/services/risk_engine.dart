import '../models/risk_result.dart';
import '../models/domain_result.dart';
import '../models/threat_result.dart';

class RiskEngine {
  static RiskResult calculateRiskScore({
    required ThreatResult threatResult,
    required DomainResult domainResult,
    required List<String> heuristicFindings,
    required String scamType,
  }) {
    int threatIntelScore = 0;
    int urlReputationScore = 0;
    int domainSignalsScore = 0;
    int brandImpersonationScore = 0;
    int phishingIndicatorsScore = 0;
    int ocrScamSignalsScore = 0;
    final primaryRiskFactors = <String>[];

    // VirusTotal Score (Up to 30)
    if (threatResult.vtAvailable) {
      if (threatResult.vtMalicious > 0) {
        threatIntelScore += (threatResult.vtMalicious * 5).clamp(10, 30);
        primaryRiskFactors.add("VirusTotal Flagged (${threatResult.vtMalicious} Vendors)");
      } else if (threatResult.vtSuspicious > 0) {
        threatIntelScore += (threatResult.vtSuspicious * 3).clamp(5, 15);
        primaryRiskFactors.add("VirusTotal Suspicious Engine Warnings");
      }
    }

    // Safe Browsing Score (Up to 20)
    if (threatResult.safeBrowsingAvailable && threatResult.safeBrowsingFlagged) {
      urlReputationScore += 20;
      primaryRiskFactors.add("Google Safe Browsing Warning (${threatResult.safeBrowsingThreatType})");
    }

    // urlscan.io Score (Up to 15)
    if (threatResult.urlScanAvailable && threatResult.urlScanFlagged) {
      domainSignalsScore += 15;
      primaryRiskFactors.add("urlscan.io Deep Scan Security Alert");
    }

    // Domain Intelligence Signals (Up to 15)
    if (!domainResult.isHttps) {
      domainSignalsScore += 5;
      primaryRiskFactors.add("Unencrypted HTTP Connection");
    }

    // Brand Impersonation Signals (Up to 15)
    if (domainResult.brandImpersonationStatus.contains('Impersonation')) {
      brandImpersonationScore += 15;
      primaryRiskFactors.add("Brand Impersonation Target: ${domainResult.detectedBrand}");
    }

    // Local Heuristics (Up to 10)
    if (heuristicFindings.isNotEmpty) {
      phishingIndicatorsScore += (heuristicFindings.length * 3).clamp(3, 10);
      primaryRiskFactors.addAll(heuristicFindings);
    }

    // OCR Scam Signals (Up to 10)
    if (scamType != "None Detected") {
      ocrScamSignalsScore += 10;
      primaryRiskFactors.add("Scam Text Pattern: $scamType");
    }

    final totalScore = (threatIntelScore +
            urlReputationScore +
            domainSignalsScore +
            brandImpersonationScore +
            phishingIndicatorsScore +
            ocrScamSignalsScore)
        .clamp(0, 100);

    RiskLevel level;
    if (totalScore >= 75) {
      level = RiskLevel.malicious;
    } else if (totalScore >= 50) {
      level = RiskLevel.high;
    } else if (totalScore >= 25) {
      level = RiskLevel.suspicious;
    } else if (totalScore > 0) {
      level = RiskLevel.low;
    } else {
      level = RiskLevel.unknown;
    }

    return RiskResult(
      score: totalScore,
      level: level,
      threatIntelScore: threatIntelScore,
      urlReputationScore: urlReputationScore,
      domainSignalsScore: domainSignalsScore,
      brandImpersonationScore: brandImpersonationScore,
      phishingIndicatorsScore: phishingIndicatorsScore,
      ocrScamSignalsScore: ocrScamSignalsScore,
      primaryRiskFactors: primaryRiskFactors.toSet().toList(),
    );
  }
}
