import 'package:http/http.dart' as http;
import '../models/url_result.dart';

class UrlExtractor {
  static final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/[^\s<>"{}|\\^`]+|[a-zA-Z0-9.-]+\.(?:com|net|org|io|xyz|info|co|in|gov|edu|me|app|dev|tech|live|online|shop|top|site|club|vip|icu|fun)[^\s<>"{}|\\^`]*|\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)',
    caseSensitive: false,
  );

  static List<String> extractUrls(String text) {
    final matches = _urlRegExp.allMatches(text);
    final urls = <String>[];
    for (final match in matches) {
      String url = match.group(0) ?? '';
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      if (!urls.contains(url)) {
        urls.add(url);
      }
    }
    return urls;
  }

  static Future<UrlResult> parseAndExpandUrl(String rawInputUrl) async {
    String cleanUrl = rawInputUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    Uri uri;
    try {
      uri = Uri.parse(cleanUrl);
    } catch (_) {
      uri = Uri.parse('https://$cleanUrl');
    }

    final redirectChain = <String>[cleanUrl];
    String expandedUrl = cleanUrl;
    bool isShortened = _checkIsShortener(uri.host);

    if (isShortened) {
      try {
        final client = http.Client();
        final response = await client
            .head(uri)
            .timeout(const Duration(seconds: 4));
        if (response.headers['location'] != null) {
          expandedUrl = response.headers['location']!;
          redirectChain.add(expandedUrl);
        }
      } catch (_) {}
    }

    final finalUri = Uri.tryParse(expandedUrl) ?? uri;

    final hostParts = finalUri.host.split('.');
    String domain = finalUri.host;
    String subdomain = '';
    if (hostParts.length > 2) {
      domain = hostParts.sublist(hostParts.length - 2).join('.');
      subdomain = hostParts.sublist(0, hostParts.length - 2).join('.');
    }

    final isIpBased = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(finalUri.host);
    final hasPunycode = finalUri.host.toLowerCase().contains('xn--');

    return UrlResult(
      rawUrl: rawInputUrl,
      scheme: finalUri.scheme,
      domain: domain,
      subdomain: subdomain,
      port: finalUri.port,
      path: finalUri.path,
      query: finalUri.query,
      fragment: finalUri.fragment,
      expandedUrl: expandedUrl,
      redirectChain: redirectChain,
      isShortened: isShortened,
      isIpBased: isIpBased,
      hasPunycode: hasPunycode,
    );
  }

  static bool _checkIsShortener(String host) {
    final shorteners = [
      'bit.ly',
      'tinyurl.com',
      't.co',
      'goo.gl',
      'is.gd',
      'buff.ly',
      'ow.ly',
      'trycloudflare.com',
      'ngrok.io',
      'serveo.net',
      'loca.lt'
    ];
    return shorteners.any((s) => host.toLowerCase().contains(s));
  }
}
