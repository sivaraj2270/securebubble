class UrlResult {
  final String rawUrl;
  final String scheme;
  final String domain;
  final String subdomain;
  final int port;
  final String path;
  final String query;
  final String fragment;
  final String expandedUrl;
  final List<String> redirectChain;
  final bool isShortened;
  final bool isIpBased;
  final bool hasPunycode;

  UrlResult({
    required this.rawUrl,
    required this.scheme,
    required this.domain,
    required this.subdomain,
    required this.port,
    required this.path,
    required this.query,
    required this.fragment,
    required this.expandedUrl,
    required this.redirectChain,
    required this.isShortened,
    required this.isIpBased,
    required this.hasPunycode,
  });

  Map<String, dynamic> toJson() => {
        'rawUrl': rawUrl,
        'scheme': scheme,
        'domain': domain,
        'subdomain': subdomain,
        'port': port,
        'path': path,
        'query': query,
        'fragment': fragment,
        'expandedUrl': expandedUrl,
        'redirectChain': redirectChain,
        'isShortened': isShortened,
        'isIpBased': isIpBased,
        'hasPunycode': hasPunycode,
      };
}
