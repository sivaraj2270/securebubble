class HyperlinkResult {
  final String visibleText;
  final String actualUrl;
  final String sourceApp;
  final String domain;
  final String finalUrl;
  final List<String> redirects;
  final bool domainMatch;
  final String detectionType; // 'DECEPTIVE_HYPERLINK', 'VERIFIED_MATCH', 'VISIBLE_URL_ONLY', 'QR_CODE_HYPERLINK'
  final String riskLevel; // 'LOW', 'SUSPICIOUS', 'HIGH', 'MALICIOUS', 'UNKNOWN'
  final String reason;

  HyperlinkResult({
    required this.visibleText,
    required this.actualUrl,
    required this.sourceApp,
    required this.domain,
    required this.finalUrl,
    required this.redirects,
    required this.domainMatch,
    required this.detectionType,
    required this.riskLevel,
    required this.reason,
  });

  factory HyperlinkResult.fromJson(Map<String, dynamic> json) {
    return HyperlinkResult(
      visibleText: json['visibleText'] ?? '',
      actualUrl: json['actualUrl'] ?? '',
      sourceApp: json['sourceApp'] ?? 'Unknown App',
      domain: json['domain'] ?? '',
      finalUrl: json['finalUrl'] ?? '',
      redirects: List<String>.from(json['redirects'] ?? []),
      domainMatch: json['domainMatch'] ?? false,
      detectionType: json['detectionType'] ?? 'VISIBLE_URL_ONLY',
      riskLevel: json['riskLevel'] ?? 'UNKNOWN',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'visibleText': visibleText,
        'actualUrl': actualUrl,
        'sourceApp': sourceApp,
        'domain': domain,
        'finalUrl': finalUrl,
        'redirects': redirects,
        'domainMatch': domainMatch,
        'detectionType': detectionType,
        'riskLevel': riskLevel,
        'reason': reason,
      };
}
