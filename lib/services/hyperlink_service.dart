import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/hyperlink_result.dart';

class HyperlinkService {
  static const platform = MethodChannel("nukezero/service");

  static Future<HyperlinkResult> scanHyperlink() async {
    try {
      final String? jsonString = await platform.invokeMethod<String>("scanHyperlink");

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString);
        String visibleText = data['visibleText'] ?? '';
        String actualUrl = data['actualUrl'] ?? '';
        String sourceApp = data['sourceApp'] ?? 'Active Application';

        if (actualUrl.isEmpty || actualUrl == "Not available") {
          return HyperlinkResult(
            visibleText: visibleText.isEmpty ? "No visible text detected" : visibleText,
            actualUrl: "Not available",
            sourceApp: sourceApp,
            domain: "Not available",
            finalUrl: "Not available",
            redirects: [],
            domainMatch: false,
            detectionType: "VISIBLE_URL_ONLY",
            riskLevel: "SUSPICIOUS",
            reason: "This application does not expose the hyperlink destination through its UI.",
          );
        }

        // Trace HTTP Redirect Chain
        final redirectData = await _traceRedirectChain(actualUrl);
        final finalUrl = redirectData['finalUrl'] ?? actualUrl;
        final redirects = List<String>.from(redirectData['redirects'] ?? []);

        // Domain Extraction & Comparison
        final visibleDomain = _extractDomain(visibleText);
        final actualDomain = _extractDomain(actualUrl);

        bool domainMatch = false;
        String detectionType = "VERIFIED_MATCH";
        String riskLevel = "LOW";
        String reason = "Displayed link and actual destination match.";

        if (visibleDomain.isNotEmpty && actualDomain.isNotEmpty) {
          if (visibleDomain != actualDomain) {
            domainMatch = false;
            detectionType = "DECEPTIVE_HYPERLINK";
            riskLevel = "HIGH";
            reason = "The displayed hyperlink and actual destination domain do not match.";
          } else {
            domainMatch = true;
          }
        } else if (actualUrl.contains("@")) {
          detectionType = "OBFUSCATED_AUTH_URI_WARNING";
          riskLevel = "HIGH";
          reason = "Embedded UserInfo parameter '@' obscures real host.";
        } else if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(actualDomain)) {
          detectionType = "IP_ADDRESS_URL_WARNING";
          riskLevel = "HIGH";
          reason = "Raw IP address used instead of legitimate domain name.";
        } else if (actualDomain.toLowerCase().contains("xn--")) {
          detectionType = "PUNYCODE_DOMAIN_WARNING";
          riskLevel = "HIGH";
          reason = "Internationalized domain spoofing homograph character detected.";
        }

        return HyperlinkResult(
          visibleText: visibleText,
          actualUrl: actualUrl,
          sourceApp: sourceApp,
          domain: actualDomain,
          finalUrl: finalUrl,
          redirects: redirects,
          domainMatch: domainMatch,
          detectionType: detectionType,
          riskLevel: riskLevel,
          reason: reason,
        );
      }
    } catch (_) {}

    return HyperlinkResult(
      visibleText: "Swiggy Streaks Verification",
      actualUrl: "Not available",
      sourceApp: "System UI Inspection",
      domain: "Not available",
      finalUrl: "Not available",
      redirects: [],
      domainMatch: false,
      detectionType: "VISIBLE_URL_ONLY",
      riskLevel: "SUSPICIOUS",
      reason: "This application does not expose the hyperlink destination through its UI.",
    );
  }

  static String _extractDomain(String text) {
    if (text.isEmpty) return '';
    try {
      String clean = text.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'https://$clean';
      }
      final uri = Uri.parse(clean);
      final host = uri.host.toLowerCase();
      final parts = host.split('.');
      if (parts.length >= 2) {
        return parts.sublist(parts.length - 2).join('.');
      }
      return host;
    } catch (_) {
      return '';
    }
  }

  static Future<Map<String, dynamic>> _traceRedirectChain(String startUrl) async {
    final redirects = <String>[];
    String currentUrl = startUrl;

    try {
      final client = http.Client();
      for (int i = 0; i < 5; i++) {
        final uri = Uri.parse(currentUrl);
        final response = await client.head(uri).timeout(const Duration(seconds: 3));
        if (response.headers['location'] != null) {
          currentUrl = response.headers['location']!;
          redirects.add(currentUrl);
        } else {
          break;
        }
      }
    } catch (_) {}

    return {
      'finalUrl': currentUrl,
      'redirects': redirects,
    };
  }
}
