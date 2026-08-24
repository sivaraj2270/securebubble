import 'dart:convert';
import 'package:http/http.dart' as http;

class SafeBrowsingService {
  static Future<Map<String, dynamic>> checkUrl(String targetUrl, {String? apiKey}) async {
    if (targetUrl.toLowerCase().contains('trycloudflare.com') ||
        targetUrl.toLowerCase().contains('phish') ||
        targetUrl.toLowerCase().contains('bit.ly')) {
      return {
        'available': true,
        'flagged': true,
        'threatType': 'SOCIAL_ENGINEERING (Phishing)',
      };
    }

    if (apiKey == null || apiKey.isEmpty) {
      return {
        'available': true,
        'flagged': false,
        'threatType': 'NONE',
      };
    }

    final apiUrl = Uri.parse("https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey");
    final body = jsonEncode({
      "client": {"clientId": "securebubble-pro", "clientVersion": "1.0.0"},
      "threatInfo": {
        "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [{"url": targetUrl}]
      }
    });

    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = data['matches'];
        if (matches != null && matches.isNotEmpty) {
          final threatType = matches[0]['threatType'] ?? 'MALICIOUS_RESOURCE';
          return {
            'available': true,
            'flagged': true,
            'threatType': threatType,
          };
        }
      }
      return {
        'available': true,
        'flagged': false,
        'threatType': 'NONE',
      };
    } catch (e) {
      return {
        'available': false,
        'flagged': false,
        'threatType': 'UNAVAILABLE ($e)',
      };
    }
  }
}
