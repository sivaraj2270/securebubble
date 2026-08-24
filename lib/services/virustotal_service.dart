import 'dart:convert';
import 'package:http/http.dart' as http;

class VirusTotalService {
  static const String _defaultApiKey = "d87a41aa6e2b6a95f5764d2d416b9b32c69bc364177d54407b8b8ae8e48a1d7f";

  static Future<Map<String, dynamic>> checkUrlReputation(String targetUrl, {String? apiKey}) async {
    final key = apiKey ?? _defaultApiKey;
    final urlId = base64Url.encode(utf8.encode(targetUrl)).replaceAll('=', '');
    final apiUrl = Uri.parse("https://www.virustotal.com/api/v3/urls/$urlId");

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "x-apikey": key,
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['data']['attributes']['last_analysis_stats'] ?? {};
        return {
          'available': true,
          'malicious': stats['malicious'] ?? 0,
          'suspicious': stats['suspicious'] ?? 0,
          'harmless': stats['harmless'] ?? 0,
          'undetected': stats['undetected'] ?? 0,
          'errorMessage': '',
        };
      } else if (response.statusCode == 404) {
        return {
          'available': true,
          'malicious': 0,
          'suspicious': 0,
          'harmless': 1,
          'undetected': 0,
          'errorMessage': 'URL not previously scanned in VirusTotal database',
        };
      } else {
        return {
          'available': false,
          'malicious': 0,
          'suspicious': 0,
          'harmless': 0,
          'undetected': 0,
          'errorMessage': 'VirusTotal API Error (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'available': false,
        'malicious': 0,
        'suspicious': 0,
        'harmless': 0,
        'undetected': 0,
        'errorMessage': 'VirusTotal Connection Timeout ($e)',
      };
    }
  }
}