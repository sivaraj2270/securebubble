class HomographResult {
  final bool isHomograph;
  final bool isPunycode;
  final bool isMixedScript;
  final String normalizedDomain;
  final String warningMessage;
  final int riskScore;

  HomographResult({
    required this.isHomograph,
    required this.isPunycode,
    required this.isMixedScript,
    required this.normalizedDomain,
    required this.warningMessage,
    required this.riskScore,
  });
}

class HomographDetector {
  static final Map<int, String> _confusablesMap = {
    0x0430: 'a', // Cyrillic small letter a
    0x0441: 'c', // Cyrillic small letter es
    0x0435: 'e', // Cyrillic small letter ie
    0x043E: 'o', // Cyrillic small letter o
    0x0440: 'p', // Cyrillic small letter er
    0x0445: 'x', // Cyrillic small letter ha
    0x0443: 'y', // Cyrillic small letter u
    0x03B1: 'a', // Greek small letter alpha
    0x03BF: 'o', // Greek small letter omicron
    0x0456: 'i', // Cyrillic small letter byelorussian-ukrainian i
  };

  static HomographResult analyzeDomain(String domain) {
    final clean = domain.trim().toLowerCase();
    bool punycode = clean.startsWith("xn--") || clean.contains(".xn--");
    bool homograph = false;
    bool mixedScript = false;

    final buffer = StringBuffer();
    int nonLatinCount = 0;
    int latinCount = 0;

    for (final char in clean.runes) {
      if (_confusablesMap.containsKey(char)) {
        homograph = true;
        nonLatinCount++;
        buffer.write(_confusablesMap[char]);
      } else {
        if ((char >= 0x0041 && char <= 0x005A) || (char >= 0x0061 && char <= 0x007A)) {
          latinCount++;
        } else if (char > 0x007F && char != 0x002E && char != 0x002D) {
          nonLatinCount++;
        }
        buffer.writeCharCode(char);
      }
    }

    if (latinCount > 0 && nonLatinCount > 0) {
      mixedScript = true;
    }

    int score = 0;
    String warning = "Domain uses standard character encoding.";

    if (punycode) {
      score += 45;
      warning = "CRITICAL: Punycode encoded domain (xn--) detected. High risk of visual spoofing.";
    } else if (homograph || mixedScript) {
      score += 55;
      warning = "WARNING: Lookalike Cyrillic/Greek homograph characters detected in domain name.";
    }

    return HomographResult(
      isHomograph: homograph,
      isPunycode: punycode,
      isMixedScript: mixedScript,
      normalizedDomain: buffer.toString(),
      warningMessage: warning,
      riskScore: score,
    );
  }
}
