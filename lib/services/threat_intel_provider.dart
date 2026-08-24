class ThreatIntelResult {
  final String providerName;
  final bool isAvailable;
  final bool isMalicious;
  final bool isSuspicious;
  final int maliciousVotes;
  final int suspiciousVotes;
  final int harmlessVotes;
  final int undetectedVotes;
  final String errorMessage;

  ThreatIntelResult({
    required this.providerName,
    required this.isAvailable,
    required this.isMalicious,
    required this.isSuspicious,
    required this.maliciousVotes,
    required this.suspiciousVotes,
    required this.harmlessVotes,
    required this.undetectedVotes,
    this.errorMessage = '',
  });

  factory ThreatIntelResult.unavailable(String provider, String error) {
    return ThreatIntelResult(
      providerName: provider,
      isAvailable: false,
      isMalicious: false,
      isSuspicious: false,
      maliciousVotes: 0,
      suspiciousVotes: 0,
      harmlessVotes: 0,
      undetectedVotes: 0,
      errorMessage: error,
    );
  }
}

abstract class ThreatIntelProvider {
  String get providerName;

  Future<ThreatIntelResult> analyzeUrl(String url);
  Future<int> getMaliciousVotes(String url);
  Future<int> getSuspiciousVotes(String url);
  Future<Map<String, dynamic>> getReputation(String url);
}
