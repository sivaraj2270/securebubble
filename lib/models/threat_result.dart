class ThreatResult {
  final int vtMalicious;
  final int vtSuspicious;
  final int vtHarmless;
  final int vtUndetected;
  final bool vtAvailable;
  final String vtErrorMessage;

  final bool safeBrowsingFlagged;
  final String safeBrowsingThreatType;
  final bool safeBrowsingAvailable;

  final bool urlScanFlagged;
  final int urlScanScore;
  final String urlScanScreenshotUrl;
  final bool urlScanAvailable;

  final List<String> heuristicFindings;

  ThreatResult({
    required this.vtMalicious,
    required this.vtSuspicious,
    required this.vtHarmless,
    required this.vtUndetected,
    required this.vtAvailable,
    required this.vtErrorMessage,
    required this.safeBrowsingFlagged,
    required this.safeBrowsingThreatType,
    required this.safeBrowsingAvailable,
    required this.urlScanFlagged,
    required this.urlScanScore,
    required this.urlScanScreenshotUrl,
    required this.urlScanAvailable,
    required this.heuristicFindings,
  });

  Map<String, dynamic> toJson() => {
        'vtMalicious': vtMalicious,
        'vtSuspicious': vtSuspicious,
        'vtHarmless': vtHarmless,
        'vtUndetected': vtUndetected,
        'vtAvailable': vtAvailable,
        'vtErrorMessage': vtErrorMessage,
        'safeBrowsingFlagged': safeBrowsingFlagged,
        'safeBrowsingThreatType': safeBrowsingThreatType,
        'safeBrowsingAvailable': safeBrowsingAvailable,
        'urlScanFlagged': urlScanFlagged,
        'urlScanScore': urlScanScore,
        'urlScanScreenshotUrl': urlScanScreenshotUrl,
        'urlScanAvailable': urlScanAvailable,
        'heuristicFindings': heuristicFindings,
      };
}
