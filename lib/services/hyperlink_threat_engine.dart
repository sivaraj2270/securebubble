import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/hyperlink_scan_result.dart';
import '../utils/url_utils.dart';
import 'typosquatting_detector.dart';

class HyperlinkThreatEngine {
  static const platform = MethodChannel("securebubble/service");

  static Future<HyperlinkScanResult> analyzeCurrentScreen() async {
    try {
      final String? jsonString = await platform.invokeMethod<String>("scanHyperlink");

      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString);
        final visibleText = (data['visibleText'] ?? '').toString();
        final actualUrl = (data['actualUrl'] ?? '').toString();
        final sourceApp = (data['sourceApp'] ?? 'Active Application').toString();

        if (actualUrl.isEmpty || actualUrl == "Not available" || actualUrl == "ACTUAL_URL_NOT_EXPOSED") {
          return HyperlinkScanResult(
            visibleText: visibleText.isEmpty ? "No visible text detected" : visibleText,
            actualUrl: "ACTUAL_URL_NOT_EXPOSED",
            normalizedUrl: "ACTUAL_URL_NOT_EXPOSED",
            finalUrl: "ACTUAL_URL_NOT_EXPOSED",
            sourceApp: sourceApp,
            visibleDomain: UrlUtils.normalize(visibleText).rootDomain,
            actualDomain: "NOT_EXPOSED",
            domainMatch: false,
            https: false,
            ipBased: false,
            punycode: false,
            typosquatting: false,
            obfuscated: false,
            shortened: false,
            redirectDetected: false,
            detectionType: "ACTUAL_URL_NOT_EXPOSED",
            riskLevel: "UNKNOWN",
            confidence: 0.50,
            reasons: const ["The current application does not expose the hyperlink destination through its UI/accessibility interface."],
          );
        }

        return await analyzeUrls(visibleText: visibleText, actualUrl: actualUrl, sourceApp: sourceApp);
      }
    } catch (_) {}

    return HyperlinkScanResult(
      visibleText: "Swiggy Streaks Verification",
      actualUrl: "ACTUAL_URL_NOT_EXPOSED",
      normalizedUrl: "ACTUAL_URL_NOT_EXPOSED",
      finalUrl: "ACTUAL_URL_NOT_EXPOSED",
      sourceApp: "System UI Inspection",
      visibleDomain: "swiggy.com",
      actualDomain: "NOT_EXPOSED",
      domainMatch: false,
      https: false,
      ipBased: false,
      punycode: false,
      typosquatting: false,
      obfuscated: false,
      shortened: false,
      redirectDetected: false,
      detectionType: "ACTUAL_URL_NOT_EXPOSED",
      riskLevel: "UNKNOWN",
      confidence: 0.50,
      reasons: const ["The current application does not expose the hyperlink destination through its UI/accessibility interface."],
    );
  }

  static Future<HyperlinkScanResult> analyzeUrls({
    required String visibleText,
    required String actualUrl,
    String sourceApp = "Unknown App",
  }) async {
    final normVisible = UrlUtils.normalize(visibleText);
    final normActual = UrlUtils.normalize(actualUrl);

    final visibleDomain = normVisible.rootDomain;
    final actualDomain = normActual.rootDomain;
    final isHttps = normActual.scheme == 'https';

    // Trace HTTP Redirects
    final redirectData = await _traceRedirectChain(normActual.normalizedUrl);
    final finalUrl = redirectData['finalUrl'] ?? normActual.normalizedUrl;
    final redirects = List<String>.from(redirectData['redirects'] ?? []);
    final normFinal = UrlUtils.normalize(finalUrl);
    final finalDomain = normFinal.rootDomain;
    final redirectDetected = redirects.isNotEmpty || (actualDomain != finalDomain);

    // Indicator checks
    final isIpBased = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(normActual.host);
    final isPunycode = normActual.host.contains('xn--');
    final isShortened = _isShortenerDomain(normActual.host);

    // Typosquatting Analysis
    final typosquatResult = TyposquattingDetector.analyze(normActual.host);
    final isTyposquatting = typosquatResult.isTyposquatting;

    // URL Obfuscation (percent encoding %6c, UserInfo @)
    final isObfuscated = actualUrl.contains('%') || actualUrl.contains('@');

    // Phishing keyword indicators
    final lowerUrl = normActual.normalizedUrl.toLowerCase();
    final lowerText = visibleText.toLowerCase();
    final containsPhishKw = _containsPhishingKeywords(lowerUrl) || _containsPhishingKeywords(lowerText);

    // Domain match logic
    bool domainMatch = false;
    if (visibleDomain.isNotEmpty && actualDomain.isNotEmpty) {
      domainMatch = (visibleDomain == actualDomain);
    }

    final reasons = <String>[];
    double riskScore = 0.0; // 0.0 to 1.0

    // Threat scoring & reason generation
    if (visibleDomain.isNotEmpty && actualDomain.isNotEmpty && !domainMatch) {
      riskScore += 0.45;
      reasons.add("Visible domain ($visibleDomain) does not match actual destination domain ($actualDomain).");
    }

    if (isPunycode) {
      riskScore += 0.35;
      reasons.add("Internationalized domain spoofing homograph character detected (Punycode: ${normActual.host}).");
    }

    if (isTyposquatting) {
      riskScore += 0.30;
      reasons.add("Domain ${normActual.host} visually resembles trusted brand ${typosquatResult.matchedBrand}.");
    }

    if (isIpBased) {
      riskScore += 0.25;
      reasons.add("Raw IP address used instead of legitimate domain name (${normActual.host}).");
    }

    if (isObfuscated) {
      riskScore += 0.20;
      reasons.add("URL contains percent-encoding or UserInfo obfuscation.");
    }

    if (redirectDetected) {
      riskScore += 0.20;
      reasons.add("URL redirects to a different final domain ($finalDomain).");
    }

    if (!isHttps) {
      riskScore += 0.15;
      reasons.add("Link uses unencrypted HTTP protocol instead of HTTPS.");
    }

    if (isShortened) {
      riskScore += 0.15;
      reasons.add("URL uses a link-shortening service.");
    }

    if (containsPhishKw) {
      riskScore += 0.15;
      reasons.add("Contains sensitive authentication keywords (login, verify, account, password).");
    }

    // Determine Detection Type
    String detectionType = "VERIFIED_MATCH";
    if (!domainMatch && visibleDomain.isNotEmpty && actualDomain.isNotEmpty) {
      detectionType = "DECEPTIVE_HYPERLINK";
    } else if (isPunycode) {
      detectionType = "PUNYCODE_WARNING";
    } else if (isTyposquatting) {
      detectionType = "TYPOSQUATTING_WARNING";
    } else if (isIpBased) {
      detectionType = "IP_BASED_URL";
    } else if (redirectDetected) {
      detectionType = "REDIRECT_DOMAIN_CHANGE";
    } else if (isObfuscated) {
      detectionType = "URL_OBFUSCATION";
    } else if (isShortened) {
      detectionType = "SHORTENED_URL";
    } else if (!isHttps) {
      detectionType = "INSECURE_HTTP";
    }

    // Assign Risk Level
    String riskLevel = "SAFE";
    if (riskScore >= 0.60) {
      riskLevel = "MALICIOUS";
    } else if (riskScore >= 0.30) {
      riskLevel = "SUSPICIOUS";
    } else if (riskScore > 0.0) {
      riskLevel = "SUSPICIOUS";
    }

    double confidence = (0.75 + (reasons.length * 0.05)).clamp(0.70, 0.99);

    if (reasons.isEmpty) {
      reasons.add("Visible hyperlink and actual destination domain match verified.");
    }

    return HyperlinkScanResult(
      visibleText: visibleText,
      actualUrl: actualUrl,
      normalizedUrl: normActual.normalizedUrl,
      finalUrl: finalUrl,
      sourceApp: sourceApp,
      visibleDomain: visibleDomain,
      actualDomain: actualDomain,
      domainMatch: domainMatch,
      https: isHttps,
      ipBased: isIpBased,
      punycode: isPunycode,
      typosquatting: isTyposquatting,
      obfuscated: isObfuscated,
      shortened: isShortened,
      redirectDetected: redirectDetected,
      detectionType: detectionType,
      riskLevel: riskLevel,
      confidence: confidence,
      reasons: reasons,
    );
  }

  static bool _isShortenerDomain(String host) {
    final lower = host.toLowerCase();
    return lower.contains('bit.ly') ||
        lower.contains('tinyurl.com') ||
        lower.contains('t.co') ||
        lower.contains('is.gd') ||
        lower.contains('buff.ly') ||
        lower.contains('ow.ly') ||
        lower.contains('trycloudflare.com');
  }

  static bool _containsPhishingKeywords(String text) {
    final kwList = [
      'login',
      'verify',
      'account',
      'password',
      'security',
      'payment',
      'banking',
      'wallet',
      'reset',
      'authentication',
      'kyc',
      'suspended'
    ];
    for (final kw in kwList) {
      if (text.contains(kw)) return true;
    }
    return false;
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
