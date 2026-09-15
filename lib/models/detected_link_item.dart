class DetectedLinkItem {
  final String text;
  final String url;
  final String source; // "accessibility" or "ocr"
  final bool clickable;
  final bool domainMatch;
  final String detectionType;
  final String warning;
  final int riskScore;
  final String riskLevel; // "SAFE", "LOW RISK", "SUSPICIOUS", "DANGEROUS"

  DetectedLinkItem({
    required this.text,
    required this.url,
    required this.source,
    required this.clickable,
    required this.domainMatch,
    required this.detectionType,
    required this.warning,
    required this.riskScore,
    required this.riskLevel,
  });

  factory DetectedLinkItem.fromJson(Map<String, dynamic> json) {
    return DetectedLinkItem(
      text: json['text'] ?? '',
      url: json['url'] ?? '',
      source: json['source'] ?? 'accessibility',
      clickable: json['clickable'] ?? true,
      domainMatch: json['domainMatch'] ?? true,
      detectionType: json['detectionType'] ?? 'VISIBLE_TEXT_URL',
      warning: json['warning'] ?? '',
      riskScore: json['riskScore'] ?? 5,
      riskLevel: json['riskLevel'] ?? 'SAFE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'url': url,
      'source': source,
      'clickable': clickable,
      'domainMatch': domainMatch,
      'detectionType': detectionType,
      'warning': warning,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
    };
  }
}
