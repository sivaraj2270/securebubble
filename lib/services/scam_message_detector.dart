class ScamMessageResult {
  final String category; // Bank Scam, Delivery Scam, Job Scam, Investment Scam, Account Takeover, Safe Message
  final int scamProbabilityPercentage;
  final List<String> indicators;
  final String recommendation;

  ScamMessageResult({
    required this.category,
    required this.scamProbabilityPercentage,
    required this.indicators,
    required this.recommendation,
  });
}

class ScamMessageDetector {
  static ScamMessageResult analyzeMessage(String text) {
    final lower = text.toLowerCase();
    final indicators = <String>[];
    int score = 0;
    String category = "Clean Message";

    // 1. Bank Scam & Account Block Threats
    if (lower.contains("account blocked") || lower.contains("kyc expired") || lower.contains("deactivated today") || lower.contains("sbi netbanking")) {
      score += 45;
      category = "Bank Account Scam";
      indicators.add("Threat of immediate bank account block / KYC expiration.");
    }

    // 2. Delivery Scam (FedEx, India Post, DHL)
    if (lower.contains("package delivery failed") || lower.contains("address incomplete") || lower.contains("customs fee") || lower.contains("india post")) {
      score += 40;
      category = "Parcel Delivery Scam";
      indicators.add("Fake package delivery exception requesting link click.");
    }

    // 3. High Pay / Work From Home Job Scam
    if (lower.contains("earn 5000 daily") || lower.contains("part time telegram job") || lower.contains("youtube like video job") || lower.contains("daily payout")) {
      score += 45;
      category = "Job / Prepaid Task Scam";
      indicators.add("Unrealistic income promise for simple online tasks.");
    }

    // 4. Urgency & OTP Harvesting
    if (lower.contains("immediately") || lower.contains("within 24 hours") || lower.contains("share otp") || lower.contains("enter pin")) {
      score += 30;
      indicators.add("High-urgency pressure tactic combined with credential/OTP request.");
    }

    // 5. Crypto / Investment Scam
    if (lower.contains("guaranteed 100% profit") || lower.contains("crypto trading signal") || lower.contains("double your investment")) {
      score += 50;
      category = "Investment Scam";
      indicators.add("Guaranteed high-return financial investment scheme.");
    }

    score = score.clamp(0, 99);

    if (indicators.isEmpty) {
      indicators.add("No social engineering or scam triggers detected in text.");
    }

    String rec = "Message appears normal. Maintain standard awareness.";
    if (score >= 60) {
      rec = "⚠️ HIGH SCAM RISK: Do not click embedded links or send money/OTPs.";
    } else if (score >= 30) {
      rec = "ℹ️ Exercise caution. Verify claims through official customer care numbers.";
    }

    return ScamMessageResult(
      category: category,
      scamProbabilityPercentage: score,
      indicators: indicators,
      recommendation: rec,
    );
  }
}
