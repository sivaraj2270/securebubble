class PhishingLanguageResult {
  final bool isPhishingLanguage;
  final int scoreContribution;
  final List<String> detectedTriggers;
  final String primaryCategory;

  PhishingLanguageResult({
    required this.isPhishingLanguage,
    required this.scoreContribution,
    required this.detectedTriggers,
    required this.primaryCategory,
  });
}

class PhishingLanguageAnalyzer {
  static PhishingLanguageResult analyze(String text) {
    if (text.trim().isEmpty) {
      return PhishingLanguageResult(
        isPhishingLanguage: false,
        scoreContribution: 0,
        detectedTriggers: [],
        primaryCategory: 'None',
      );
    }

    final lower = text.toLowerCase();
    final triggers = <String>[];
    int score = 0;
    String category = 'General Text';

    // 1. Urgency Triggers
    if (lower.contains('immediately') ||
        lower.contains('urgent') ||
        lower.contains('within 24 hours') ||
        lower.contains('action required') ||
        lower.contains('expire soon')) {
      triggers.add("High Urgency Manipulation Language");
      score += 15;
      category = 'Urgency Scams';
    }

    // 2. Account Suspension & Threats
    if (lower.contains('suspended') ||
        lower.contains('blocked') ||
        lower.contains('kyc expired') ||
        lower.contains('account locked') ||
        lower.contains('unauthorized activity')) {
      triggers.add("Fake Account Suspension Threat");
      score += 20;
      category = 'Banking & Account Takeover';
    }

    // 3. Fake Prize / Lottery Scams
    if (lower.contains('congratulations') ||
        lower.contains('winner') ||
        lower.contains('claim prize') ||
        lower.contains('free gift') ||
        lower.contains('lottery winner')) {
      triggers.add("Fake Prize / Reward Scam Language");
      score += 20;
      category = 'Prize & Gift Scam';
    }

    // 4. Credential & OTP Harvesting Requests
    if (lower.contains('verify otp') ||
        lower.contains('enter password') ||
        lower.contains('confirm login') ||
        lower.contains('update credentials') ||
        lower.contains('enter upi pin')) {
      triggers.add("Credential or OTP Harvesting Trigger");
      score += 25;
      category = 'Credential Harvesting';
    }

    // 5. Fake Bill / Payment Demands
    if (lower.contains('electricity bill unpaid') ||
        lower.contains('challan pending') ||
        lower.contains('fine unpaid') ||
        lower.contains('pay now to avoid disconnect')) {
      triggers.add("Fake Utility Bill / Fine Scam Trigger");
      score += 20;
      category = 'Utility & Payment Fraud';
    }

    return PhishingLanguageResult(
      isPhishingLanguage: triggers.isNotEmpty,
      scoreContribution: score.clamp(0, 40),
      detectedTriggers: triggers,
      primaryCategory: category,
    );
  }
}
