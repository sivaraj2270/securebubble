import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/detected_content_item.dart';
import '../models/dual_url_scan_result.dart';
import 'native_service.dart';

class ScannedItemVerification {
  final DetectedContentItem item;
  final DualUrlScanResult? dualScanResult;
  final String status;

  ScannedItemVerification({
    required this.item,
    this.dualScanResult,
    required this.status,
  });
}

class CombinedScreenScanReport {
  final String packageName;
  final int totalNodesScanned;
  final int uniqueUrlsFound;
  final int highRiskCount;
  final List<ScannedItemVerification> verifications;
  final DateTime timestamp;

  CombinedScreenScanReport({
    required this.packageName,
    required this.totalNodesScanned,
    required this.uniqueUrlsFound,
    required this.highRiskCount,
    required this.verifications,
    required this.timestamp,
  });
}

class ScreenScanPipeline {
  final String backendBaseUrl;

  ScreenScanPipeline({this.backendBaseUrl = 'http://10.0.2.2:8000'});

  Future<CombinedScreenScanReport?> executeFullCurrentScreenScan() async {
    final nativeReport = await NativeService.scanCurrentScreen();
    if (nativeReport == null || nativeReport.items.isEmpty) {
      return null;
    }

    final String packageName = nativeReport.packageName;
    final List<DetectedContentItem> items = nativeReport.items;

    // Deduplicate URLs
    final Map<String, DetectedContentItem> uniqueItemsMap = {};
    for (var item in items) {
      if (item.url.isNotEmpty && !uniqueItemsMap.containsKey(item.url)) {
        uniqueItemsMap[item.url] = item;
      }
    }

    final List<ScannedItemVerification> verifications = [];
    int highRiskCount = 0;

    for (var entry in uniqueItemsMap.entries) {
      final url = entry.key;
      final item = entry.value;

      try {
        final response = await http
            .post(
              Uri.parse('$backendBaseUrl/api/v1/scan/url'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'url': url}),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final jsonMap = jsonDecode(response.body);
          final dualResult = DualUrlScanResult.fromJson(jsonMap);
          if (dualResult.securebubble.riskScore >= 61) {
            highRiskCount++;
          }
          verifications.add(ScannedItemVerification(
            item: item,
            dualScanResult: dualResult,
            status: 'verified',
          ));
        } else {
          verifications.add(ScannedItemVerification(
            item: item,
            dualScanResult: null,
            status: 'error',
          ));
        }
      } catch (e) {
        verifications.add(ScannedItemVerification(
          item: item,
          dualScanResult: null,
          status: 'failed',
        ));
      }
    }

    return CombinedScreenScanReport(
      packageName: packageName,
      totalNodesScanned: items.length,
      uniqueUrlsFound: uniqueItemsMap.length,
      highRiskCount: highRiskCount,
      verifications: verifications,
      timestamp: DateTime.now(),
    );
  }
}
