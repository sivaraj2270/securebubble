import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dual_url_scan_result.dart';

class QrScanVerificationResult {
  final String qrPayload;
  final String extractedUrl;
  final bool isUrlPayload;
  final DualUrlScanResult? dualScanResult;
  final String status;

  QrScanVerificationResult({
    required this.qrPayload,
    required this.extractedUrl,
    required this.isUrlPayload,
    this.dualScanResult,
    required this.status,
  });
}

class QrScanPipeline {
  final String backendBaseUrl;

  QrScanPipeline({this.backendBaseUrl = 'http://10.0.2.2:8000'});

  String extractUrlFromQrPayload(String rawPayload) {
    final trimmed = rawPayload.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Check for embedded url parameters in payment/deep links (e.g. upi://pay?url=...)
    try {
      final uri = Uri.parse(trimmed);
      if (uri.queryParameters.containsKey('url')) {
        return uri.queryParameters['url']!;
      }
    } catch (_) {}

    return '';
  }

  Future<QrScanVerificationResult> processQrPayload(String rawPayload) async {
    final String url = extractUrlFromQrPayload(rawPayload);
    final bool isUrl = url.isNotEmpty;

    if (!isUrl) {
      return QrScanVerificationResult(
        qrPayload: rawPayload,
        extractedUrl: '',
        isUrlPayload: false,
        dualScanResult: null,
        status: 'non_url_payload',
      );
    }

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
        return QrScanVerificationResult(
          qrPayload: rawPayload,
          extractedUrl: url,
          isUrlPayload: true,
          dualScanResult: dualResult,
          status: 'verified',
        );
      } else {
        return QrScanVerificationResult(
          qrPayload: rawPayload,
          extractedUrl: url,
          isUrlPayload: true,
          dualScanResult: null,
          status: 'server_error',
        );
      }
    } catch (e) {
      return QrScanVerificationResult(
        qrPayload: rawPayload,
        extractedUrl: url,
        isUrlPayload: true,
        dualScanResult: null,
        status: 'network_failure',
      );
    }
  }
}
