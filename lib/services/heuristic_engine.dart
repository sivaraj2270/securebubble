import '../models/url_result.dart';

class HeuristicEngine {
  static List<String> evaluate(UrlResult urlResult, String text) {
    final findings = <String>[];
    final lowerText = text.toLowerCase();
    final lowerUrl = urlResult.expandedUrl.toLowerCase();

    if (urlResult.isIpBased) {
      findings.add("⚠️ IP address used instead of legitimate domain name");
    }

    if (urlResult.subdomain.split('.').length > 2) {
      findings.add("⚠️ Excessive subdomain depth detected");
    }

    final suspiciousTlds = ['.xyz', '.top', '.icu', '.vip', '.tk', '.ml', '.fun', '.site', '.cf', '.gq', '.club'];
    if (suspiciousTlds.any((tld) => urlResult.domain.toLowerCase().endsWith(tld))) {
      findings.add("⚠️ High-risk TLD extension observed");
    }

    if (urlResult.hasPunycode) {
      findings.add("⚠️ Punycode / Homograph domain encoding detected");
    }

    if (urlResult.isShortened) {
      findings.add("⚠️ Concealed shortened redirect URL");
    }

    if (lowerUrl.length > 75) {
      findings.add("⚠️ Abnormally long URL query parameter length");
    }

    final loginKeywords = ['login', 'signin', 'verify', 'account', 'banking', 'secure', 'auth', 'update-password', 'otp'];
    if (loginKeywords.any((kw) => lowerUrl.contains(kw) || lowerText.contains(kw))) {
      findings.add("⚠️ Credential / Authentication keyword detected");
    }

    final urgencyKeywords = ['urgent', 'suspended', 'immediately', 'within 24 hours', 'blocked', 'action required', 'unauthorized access'];
    if (urgencyKeywords.any((kw) => lowerText.contains(kw))) {
      findings.add("⚠️ High urgency manipulation language detected");
    }

    return findings;
  }
}
