class VirusTotalResult {
  final String status;
  final int malicious;
  final int suspicious;
  final int harmless;
  final int undetected;
  final int totalEngines;
  final String classification;

  VirusTotalResult({
    required this.status,
    required this.malicious,
    required this.suspicious,
    required this.harmless,
    required this.undetected,
    required this.totalEngines,
    required this.classification,
  });

  factory VirusTotalResult.fromJson(Map<String, dynamic> json) {
    return VirusTotalResult(
      status: json['status'] ?? 'unknown',
      malicious: (json['malicious'] as num?)?.toInt() ?? 0,
      suspicious: (json['suspicious'] as num?)?.toInt() ?? 0,
      harmless: (json['harmless'] as num?)?.toInt() ?? 0,
      undetected: (json['undetected'] as num?)?.toInt() ?? 0,
      totalEngines: (json['total_engines'] as num?)?.toInt() ?? 0,
      classification: json['classification'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'malicious': malicious,
        'suspicious': suspicious,
        'harmless': harmless,
        'undetected': undetected,
        'total_engines': totalEngines,
        'classification': classification,
      };
}

class GoogleWebRiskResult {
  final String status;
  final List<String> threatTypes;
  final String classification;

  GoogleWebRiskResult({
    required this.status,
    required this.threatTypes,
    required this.classification,
  });

  factory GoogleWebRiskResult.fromJson(Map<String, dynamic> json) {
    return GoogleWebRiskResult(
      status: json['status'] ?? 'unknown',
      threatTypes: (json['threat_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      classification: json['classification'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'threat_types': threatTypes,
        'classification': classification,
      };
}

class ComparisonResult {
  final bool agreement;
  final String status;
  final String summary;

  ComparisonResult({
    required this.agreement,
    required this.status,
    required this.summary,
  });

  factory ComparisonResult.fromJson(Map<String, dynamic> json) {
    return ComparisonResult(
      agreement: json['agreement'] == true,
      status: json['status'] ?? 'INSUFFICIENT_DATA',
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'agreement': agreement,
        'status': status,
        'summary': summary,
      };
}

class SecureBubbleResult {
  final int riskScore;
  final String classification;
  final String confidence;
  final String reason;
  final List<String> contributingSignals;

  SecureBubbleResult({
    required this.riskScore,
    required this.classification,
    required this.confidence,
    required this.reason,
    required this.contributingSignals,
  });

  factory SecureBubbleResult.fromJson(Map<String, dynamic> json) {
    return SecureBubbleResult(
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      classification: json['classification'] ?? 'SAFE',
      confidence: json['confidence'] ?? 'medium',
      reason: json['reason'] ?? '',
      contributingSignals: (json['contributing_signals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'risk_score': riskScore,
        'classification': classification,
        'confidence': confidence,
        'reason': reason,
        'contributing_signals': contributingSignals,
      };
}

class DualUrlScanResult {
  final String scanId;
  final String url;
  final String domain;
  final String timestamp;
  final VirusTotalResult virustotal;
  final GoogleWebRiskResult googleWebRisk;
  final ComparisonResult comparison;
  final SecureBubbleResult securebubble;

  DualUrlScanResult({
    required this.scanId,
    required this.url,
    required this.domain,
    required this.timestamp,
    required this.virustotal,
    required this.googleWebRisk,
    required this.comparison,
    required this.securebubble,
  });

  factory DualUrlScanResult.fromJson(Map<String, dynamic> json) {
    return DualUrlScanResult(
      scanId: json['scan_id'] ?? '',
      url: json['url'] ?? '',
      domain: json['domain'] ?? '',
      timestamp: json['timestamp'] ?? '',
      virustotal: VirusTotalResult.fromJson(
          json['virustotal'] as Map<String, dynamic>? ?? {}),
      googleWebRisk: GoogleWebRiskResult.fromJson(
          json['google_web_risk'] as Map<String, dynamic>? ?? {}),
      comparison: ComparisonResult.fromJson(
          json['comparison'] as Map<String, dynamic>? ?? {}),
      securebubble: SecureBubbleResult.fromJson(
          json['securebubble'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'url': url,
        'domain': domain,
        'timestamp': timestamp,
        'virustotal': virustotal.toJson(),
        'google_web_risk': googleWebRisk.toJson(),
        'comparison': comparison.toJson(),
        'securebubble': securebubble.toJson(),
      };
}
