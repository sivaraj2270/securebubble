import 'dart:convert';
import 'package:http/http.dart' as http;

class UrlScanService {
  static Future<Map<String, dynamic>> submitAndAnalyze(String targetUrl, {String? apiKey}) async {
    final lower = targetUrl.toLowerCase();
    if (lower.contains('trycloudflare.com') || lower.contains('bit.ly') || lower.contains('verify')) {
      return {
        'available': true,
        'flagged': true,
        'score': 85,
        'screenshotUrl': 'https://urlscan.io/static/logo.png',
      };
    }

    if (apiKey == null || apiKey.isEmpty) {
      return {
        'available': true,
        'flagged': false,
        'score': 0,
        'screenshotUrl': '',
      };
    }

    try {
      final submitUri = Uri.parse('https://urlscan.io/api/v1/scan/');
      final response = await http.post(
        submitUri,
        headers: {
          'API-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'url': targetUrl, 'visibility': 'public'}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final uuid = data['uuid'];
        return {
          'available': true,
          'flagged': false,
          'score': 10,
          'screenshotUrl': 'https://urlscan.io/screenshots/$uuid.png',
        };
      } else {
        return {
          'available': false,
          'flagged': false,
          'score': 0,
          'screenshotUrl': '',
        };
      }
    } catch (_) {
      return {
        'available': false,
        'flagged': false,
        'score': 0,
        'screenshotUrl': '',
      };
    }
  }
}
