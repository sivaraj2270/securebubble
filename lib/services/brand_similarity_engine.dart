import 'dart:math';

class BrandMatchResult {
  final bool isImpersonating;
  final String matchedBrand;
  final double similarityPercentage;
  final String explanation;
  final int riskScore;

  BrandMatchResult({
    required this.isImpersonating,
    required this.matchedBrand,
    required this.similarityPercentage,
    required this.explanation,
    required this.riskScore,
  });
}

class BrandSimilarityEngine {
  static final List<String> _targetBrands = [
    'paypal', 'microsoft', 'google', 'swiggy', 'zomato', 'amazon',
    'apple', 'netflix', 'facebook', 'instagram', 'whatsapp', 'telegram',
    'bankofamerica', 'chase', 'wellsfargo', 'hdfcbank', 'icicibank',
    'statebankofindia', 'paytm', 'phonepe', 'binance', 'coinbase', 'zerodha'
  ];

  static BrandMatchResult evaluateBrandImpersonation(String domain) {
    final cleanHost = domain.toLowerCase().replaceAll(RegExp(r'^(https?://)?(www\.)?'), '').split('/')[0];
    final mainPart = cleanHost.split('.')[0].replaceAll(RegExp(r'[^a-z0-9]'), '');

    // 1. Direct Exact Match (Legitimate)
    if (_targetBrands.contains(mainPart)) {
      return BrandMatchResult(
        isImpersonating: false,
        matchedBrand: mainPart,
        similarityPercentage: 100.0,
        explanation: "Domain directly matches verified target brand $mainPart.",
        riskScore: 0,
      );
    }

    // 2. Character Substitution & Levenshtein Distance Matching
    final normalizedMain = mainPart
        .replaceAll('0', 'o')
        .replaceAll('1', 'l')
        .replaceAll('vv', 'w')
        .replaceAll('rn', 'm');

    for (final brand in _targetBrands) {
      if (normalizedMain == brand && mainPart != brand) {
        return BrandMatchResult(
          isImpersonating: true,
          matchedBrand: brand,
          similarityPercentage: 95.0,
          explanation: "Character substitution typosquatting detected targeting brand '$brand' (e.g. '$mainPart').",
          riskScore: 50,
        );
      }

      final dist = _levenshteinDistance(mainPart, brand);
      final maxLen = max(mainPart.length, brand.length);
      final similarity = (1.0 - (dist / maxLen)) * 100.0;

      if (dist > 0 && dist <= 2 && mainPart.length >= 4 && similarity >= 75.0) {
        return BrandMatchResult(
          isImpersonating: true,
          matchedBrand: brand,
          similarityPercentage: similarity,
          explanation: "Domain '$mainPart' has ${similarity.toStringAsFixed(1)}% visual similarity to protected brand '$brand'.",
          riskScore: 40,
        );
      }
    }

    return BrandMatchResult(
      isImpersonating: false,
      matchedBrand: "None",
      similarityPercentage: 0.0,
      explanation: "No brand impersonation patterns detected.",
      riskScore: 0,
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
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
