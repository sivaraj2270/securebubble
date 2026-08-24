import 'dart:math';

class TyposquattingResult {
  final bool isTyposquatting;
  final String matchedBrand;
  final String officialDomain;
  final double similarityScore;

  TyposquattingResult({
    required this.isTyposquatting,
    required this.matchedBrand,
    required this.officialDomain,
    required this.similarityScore,
  });
}

class TyposquattingDetector {
  static const Map<String, String> _knownBrandDomains = {
    'Google': 'google.com',
    'Microsoft': 'microsoft.com',
    'Facebook': 'facebook.com',
    'PayPal': 'paypal.com',
    'Swiggy': 'swiggy.com',
    'Zomato': 'zomato.com',
    'SBI Bank': 'sbi.co.in',
    'HDFC Bank': 'hdfcbank.com',
    'ICICI Bank': 'icicibank.com',
    'Amazon': 'amazon.com',
    'Apple': 'apple.com',
    'Netflix': 'netflix.com',
    'Telegram': 'telegram.org',
    'WhatsApp': 'whatsapp.com',
  };

  static TyposquattingResult analyze(String domain) {
    final cleanDomain = domain.toLowerCase().trim();
    if (cleanDomain.isEmpty) {
      return TyposquattingResult(
        isTyposquatting: false,
        matchedBrand: '',
        officialDomain: '',
        similarityScore: 0.0,
      );
    }

    // Standardize character substitutions (0 -> o, 1 -> l/i, 3 -> e, 5 -> s, @ -> a)
    final normalizedInput = cleanDomain
        .replaceAll('0', 'o')
        .replaceAll('1', 'l')
        .replaceAll('3', 'e')
        .replaceAll('5', 's')
        .replaceAll('@', 'a');

    for (final entry in _knownBrandDomains.entries) {
      final brandName = entry.key;
      final officialDomain = entry.value;

      if (cleanDomain == officialDomain) {
        return TyposquattingResult(
          isTyposquatting: false,
          matchedBrand: brandName,
          officialDomain: officialDomain,
          similarityScore: 1.0,
        );
      }

      // Check distance against official domain name
      final dist = _levenshteinDistance(normalizedInput, officialDomain);
      final maxLength = max(normalizedInput.length, officialDomain.length);
      final similarity = 1.0 - (dist / maxLength);

      if (similarity >= 0.75 && similarity < 1.0) {
        return TyposquattingResult(
          isTyposquatting: true,
          matchedBrand: brandName,
          officialDomain: officialDomain,
          similarityScore: similarity,
        );
      }
    }

    return TyposquattingResult(
      isTyposquatting: false,
      matchedBrand: '',
      officialDomain: '',
      similarityScore: 0.0,
    );
  }

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
