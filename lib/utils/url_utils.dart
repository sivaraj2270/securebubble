class NormalizedUrl {
  final String originalUrl;
  final String normalizedUrl;
  final String scheme;
  final String host;
  final String rootDomain;
  final String subdomain;
  final int port;
  final String path;
  final String query;
  final String fragment;

  NormalizedUrl({
    required this.originalUrl,
    required this.normalizedUrl,
    required this.scheme,
    required this.host,
    required this.rootDomain,
    required this.subdomain,
    required this.port,
    required this.path,
    required this.query,
    required this.fragment,
  });

  Map<String, dynamic> toJson() => {
        'originalUrl': originalUrl,
        'normalizedUrl': normalizedUrl,
        'scheme': scheme,
        'host': host,
        'rootDomain': rootDomain,
        'subdomain': subdomain,
        'port': port,
        'path': path,
        'query': query,
        'fragment': fragment,
      };
}

class UrlUtils {
  static NormalizedUrl normalize(String rawUrl) {
    String clean = rawUrl.trim();
    if (clean.isEmpty) {
      return NormalizedUrl(
        originalUrl: rawUrl,
        normalizedUrl: '',
        scheme: 'https',
        host: '',
        rootDomain: '',
        subdomain: '',
        port: 443,
        path: '',
        query: '',
        fragment: '',
      );
    }

    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }

    Uri uri;
    try {
      uri = Uri.parse(clean);
    } catch (_) {
      uri = Uri.parse('https://invalid-url.com');
    }

    String host = uri.host.toLowerCase();
    if (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }

    final hostParts = host.split('.');
    String rootDomain = host;
    String subdomain = '';

    if (hostParts.length >= 2) {
      rootDomain = hostParts.sublist(hostParts.length - 2).join('.');
      subdomain = hostParts.sublist(0, hostParts.length - 2).join('.');
    }

    final normalizedString = uri.replace(host: host).toString();

    return NormalizedUrl(
      originalUrl: rawUrl,
      normalizedUrl: normalizedString,
      scheme: uri.scheme.toLowerCase(),
      host: host,
      rootDomain: rootDomain,
      subdomain: subdomain,
      port: uri.port,
      path: uri.path,
      query: uri.query,
      fragment: uri.fragment,
    );
  }
}
