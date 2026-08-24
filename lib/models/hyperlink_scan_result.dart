class HyperlinkScanResult {
  final String visibleText;
  final String actualUrl;
  final String normalizedUrl;
  final String finalUrl;
  final String sourceApp;
  final String visibleDomain;
  final String actualDomain;
  final bool domainMatch;
  final bool https;
  final bool ipBased;
  final bool punycode;
  final bool typosquatting;
  final bool obfuscated;
  final bool shortened;
  final bool redirectDetected;
  final String detectionType;
  final String riskLevel; // 'SAFE', 'SUSPICIOUS', 'MALICIOUS', 'UNKNOWN'
  final double confidence; // Calculated 0.0 to 1.0
  final List<String> reasons;

  HyperlinkScanResult({
    required this.visibleText,
    required this.actualUrl,
    required this.normalizedUrl,
    required this.finalUrl,
    required this.sourceApp,
    required this.visibleDomain,
    required this.actualDomain,
    required this.domainMatch,
    required this.https,
    required this.ipBased,
    required this.punycode,
    required this.typosquatting,
    required this.obfuscated,
    required this.shortened,
    required this.redirectDetected,
    required this.detectionType,
    required this.riskLevel,
    required this.confidence,
    required this.reasons,
  });

  factory HyperlinkScanResult.fromJson(Map<String, dynamic> json) {
    return HyperlinkScanResult(
      visibleText: json['visibleText'] ?? '',
      actualUrl: json['actualUrl'] ?? '',
      normalizedUrl: json['normalizedUrl'] ?? '',
      finalUrl: json['finalUrl'] ?? '',
      sourceApp: json['sourceApp'] ?? 'Unknown App',
      visibleDomain: json['visibleDomain'] ?? '',
      actualDomain: json['actualDomain'] ?? '',
      domainMatch: json['domainMatch'] ?? false,
      https: json['https'] ?? true,
      ipBased: json['ipBased'] ?? false,
      punycode: json['punycode'] ?? false,
      typosquatting: json['typosquatting'] ?? false,
      obfuscated: json['obfuscated'] ?? false,
      shortened: json['shortened'] ?? false,
      redirectDetected: json['redirectDetected'] ?? false,
      detectionType: json['detectionType'] ?? 'VISIBLE_URL_ONLY',
      riskLevel: json['riskLevel'] ?? 'UNKNOWN',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reasons: List<String>.from(json['reasons'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'visibleText': visibleText,
        'actualUrl': actualUrl,
        'normalizedUrl': normalizedUrl,
        'finalUrl': finalUrl,
        'sourceApp': sourceApp,
        'visibleDomain': visibleDomain,
        'actualDomain': actualDomain,
        'domainMatch': domainMatch,
        'https': https,
        'ipBased': ipBased,
        'punycode': punycode,
        'typosquatting': typosquatting,
        'obfuscated': obfuscated,
        'shortened': shortened,
        'redirectDetected': redirectDetected,
        'detectionType': detectionType,
        'riskLevel': riskLevel,
        'confidence': confidence,
        'reasons': reasons,
      };
}
