import 'package:http/http.dart' as http;

class RedirectStep {
  final String url;
  final int statusCode;
  final String domain;

  RedirectStep({
    required this.url,
    required this.statusCode,
    required this.domain,
  });
}

class RedirectAnalysisResult {
  final String originalUrl;
  final String finalDestination;
  final List<RedirectStep> steps;
  final int totalRedirects;
  final bool hasCrossDomainJumps;
  final bool usesShortener;
  final bool isHttpsDowngraded;
  final String riskCategory;

  RedirectAnalysisResult({
    required this.originalUrl,
    required this.finalDestination,
    required this.steps,
    required this.totalRedirects,
    required this.hasCrossDomainJumps,
    required this.usesShortener,
    required this.isHttpsDowngraded,
    required this.riskCategory,
  });
}

class RedirectAnalyzer {
  static final List<String> _knownShorteners = [
    'bit.ly', 'tinyurl.com', 't.co', 'is.gd', 'buff.ly', 'ow.ly',
    'rb.gy', 'cutt.ly', 'shorturl.at', 'git.io', 'v.gd', 'qr.ae'
  ];

  static Future<RedirectAnalysisResult> analyzeRedirectChain(String startUrl) async {
    final steps = <RedirectStep>[];
    String currentUrl = startUrl.trim();
    if (!currentUrl.startsWith('http://') && !currentUrl.startsWith('https://')) {
      currentUrl = 'https://$currentUrl';
    }

    final initialDomain = _extractDomain(currentUrl);
    bool crossDomain = false;
    bool shortenerUsed = _isShortener(currentUrl);
    bool httpsDowngraded = false;
    final client = http.Client();

    try {
      for (int i = 0; i < 7; i++) {
        final uri = Uri.parse(currentUrl);
        steps.add(RedirectStep(
          url: currentUrl,
          statusCode: 200,
          domain: uri.host.toLowerCase(),
        ));

        final response = await client.head(uri).timeout(const Duration(seconds: 3));
        final statusCode = response.statusCode;
        
        if (statusCode >= 300 && statusCode < 400 && response.headers['location'] != null) {
          String nextUrl = response.headers['location']!;
          if (nextUrl.startsWith('/')) {
            nextUrl = '${uri.scheme}://${uri.host}$nextUrl';
          }

          final nextUri = Uri.parse(nextUrl);
          if (_isShortener(nextUrl)) shortenerUsed = true;
          if (uri.scheme == 'https' && nextUri.scheme == 'http') httpsDowngraded = true;
          if (_extractDomain(nextUrl) != initialDomain) crossDomain = true;

          currentUrl = nextUrl;
        } else {
          break;
        }
      }
    } catch (_) {
      // Return accumulated steps if connection fails or times out
    } finally {
      client.close();
    }

    final totalCount = steps.length - 1;
    String riskCategory = "Clean Direct Link";
    if (totalCount > 3 || (crossDomain && shortenerUsed)) {
      riskCategory = "High-Risk Obfuscated Redirect Chain";
    } else if (crossDomain || shortenerUsed) {
      riskCategory = "Cross-Domain Redirect Observed";
    }

    return RedirectAnalysisResult(
      originalUrl: startUrl,
      finalDestination: currentUrl,
      steps: steps,
      totalRedirects: totalCount > 0 ? totalCount : 0,
      hasCrossDomainJumps: crossDomain,
      usesShortener: shortenerUsed,
      isHttpsDowngraded: httpsDowngraded,
      riskCategory: riskCategory,
    );
  }

  static bool _isShortener(String url) {
    final lower = url.toLowerCase();
    return _knownShorteners.any((s) => lower.contains(s));
  }

  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
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
}
