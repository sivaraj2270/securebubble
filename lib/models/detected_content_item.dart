class NodeBounds {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const NodeBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory NodeBounds.fromJson(Map<String, dynamic> json) {
    return NodeBounds(
      left: json['left'] ?? 0,
      top: json['top'] ?? 0,
      right: json['right'] ?? 0,
      bottom: json['bottom'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };
}

class DetectedContentItem {
  final String url;
  final String packageName;
  final String visibleText;
  final NodeBounds bounds;
  final int riskScore;
  final String classification; // SAFE, SUSPICIOUS, HIGH_RISK, DANGEROUS
  final String source; // ACCESSIBILITY, QR_SCREEN_CAPTURE
  final String associatedChat;
  final String detectionType;
  final String warning;

  DetectedContentItem({
    required this.url,
    required this.packageName,
    required this.visibleText,
    required this.bounds,
    this.riskScore = 0,
    this.classification = "SAFE",
    required this.source,
    this.associatedChat = "",
    this.detectionType = "VISIBLE_TEXT_URL",
    this.warning = "",
  });

  factory DetectedContentItem.fromJson(Map<String, dynamic> json) {
    final boundsJson = json['bounds'] as Map<String, dynamic>? ?? {};
    final score = json['riskScore'] as int? ?? 0;
    
    String calcClassification = json['classification'] ?? "SAFE";
    if (score >= 80) {
      calcClassification = "DANGEROUS";
    } else if (score >= 60) {
      calcClassification = "HIGH_RISK";
    } else if (score >= 35) {
      calcClassification = "SUSPICIOUS";
    }

    return DetectedContentItem(
      url: json['url'] ?? "",
      packageName: json['packageName'] ?? "",
      visibleText: json['text'] ?? json['visibleText'] ?? "",
      bounds: NodeBounds.fromJson(boundsJson),
      riskScore: score,
      classification: calcClassification,
      source: json['source'] ?? "ACCESSIBILITY",
      associatedChat: json['associatedChat'] ?? "",
      detectionType: json['detectionType'] ?? "VISIBLE_TEXT_URL",
      warning: json['warning'] ?? "",
    );
  }
}

class ScreenScanReportModel {
  final String packageName;
  final String scanTimestamp;
  final List<DetectedContentItem> items;
  final int totalUrls;
  final int totalQrs;
  final int safeCount;
  final int suspiciousCount;
  final int dangerousCount;

  ScreenScanReportModel({
    required this.packageName,
    required this.scanTimestamp,
    required this.items,
    required this.totalUrls,
    required this.totalQrs,
    required this.safeCount,
    required this.suspiciousCount,
    required this.dangerousCount,
  });

  factory ScreenScanReportModel.fromItems({
    required String packageName,
    required List<DetectedContentItem> items,
  }) {
    int safe = 0;
    int susp = 0;
    int dang = 0;
    int qrs = 0;
    int urls = 0;

    for (final item in items) {
      if (item.source.contains("QR")) {
        qrs++;
      } else {
        urls++;
      }

      if (item.riskScore >= 80 || item.classification == "DANGEROUS") {
        dang++;
      } else if (item.riskScore >= 35 || item.classification == "SUSPICIOUS" || item.classification == "HIGH_RISK") {
        susp++;
      } else {
        safe++;
      }
    }

    return ScreenScanReportModel(
      packageName: packageName,
      scanTimestamp: DateTime.now().toIso8601String(),
      items: items,
      totalUrls: urls,
      totalQrs: qrs,
      safeCount: safe,
      suspiciousCount: susp,
      dangerousCount: dang,
    );
  }
}
