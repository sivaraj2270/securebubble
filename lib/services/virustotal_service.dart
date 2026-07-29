import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_keys.dart';

class VirusTotalService {

  Future<String?> scanUrl(String url) async {

    final response = await http.post(
      Uri.parse("https://www.virustotal.com/api/v3/urls"),

      headers: {
        "x-apikey": ApiKeys.virusTotalApiKey,
      },

      body: {
        "url": url,
      },
    );

    if (response.statusCode == 200) {

      final json = jsonDecode(response.body);

      return json["data"]["id"];

    }

    return null;
  }
  Future<Map<String, dynamic>?> getAnalysis(String analysisId) async {

    final response = await http.get(
      Uri.parse(
        "https://www.virustotal.com/api/v3/analyses/$analysisId",
      ),
      headers: {
        "x-apikey": ApiKeys.virusTotalApiKey,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
  bool isMalicious(Map<String, dynamic> result) {

    final stats = result["data"]["attributes"]["stats"];

    final malicious = stats["malicious"] ?? 0;
    final suspicious = stats["suspicious"] ?? 0;

    return malicious > 0 || suspicious > 0;
  }

}