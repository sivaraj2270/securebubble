enum RiskLevel { low, suspicious, high, malicious, unknown }

class RiskResult {
  final int score; // 0 to 100
  final RiskLevel level;
  final int threatIntelScore;
  final int urlReputationScore;
  final int domainSignalsScore;
  final int brandImpersonationScore;
  final int phishingIndicatorsScore;
  final int ocrScamSignalsScore;
  final List<String> primaryRiskFactors;

  RiskResult({
    required this.score,
    required this.level,
    required this.threatIntelScore,
    required this.urlReputationScore,
    required this.domainSignalsScore,
    required this.brandImpersonationScore,
    required this.phishingIndicatorsScore,
    required this.ocrScamSignalsScore,
    required this.primaryRiskFactors,
  });

  String get levelLabel {
    switch (level) {
      case RiskLevel.low:
        return "🟢 LOW RISK";
      case RiskLevel.suspicious:
        return "🟡 SUSPICIOUS";
      case RiskLevel.high:
        return "🟠 HIGH RISK";
      case RiskLevel.malicious:
        return "🔴 MALICIOUS";
      case RiskLevel.unknown:
        return "⚪ UNKNOWN";
    }
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': levelLabel,
        'threatIntelScore': threatIntelScore,
        'urlReputationScore': urlReputationScore,
        'domainSignalsScore': domainSignalsScore,
        'brandImpersonationScore': brandImpersonationScore,
        'phishingIndicatorsScore': phishingIndicatorsScore,
        'ocrScamSignalsScore': ocrScamSignalsScore,
        'primaryRiskFactors': primaryRiskFactors,
      };
}
