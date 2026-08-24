class ScamDetectorResult {
  final String scamType;
  final List<String> indicators;
  final String confidence;

  ScamDetectorResult({
    required this.scamType,
    required this.indicators,
    required this.confidence,
  });
}

class ScamDetector {
  static ScamDetectorResult analyzeText(String text) {
    final lower = text.toLowerCase();
    final indicators = <String>[];
    String scamType = "None Detected";
    String confidence = "Low";

    if (lower.contains('bank') || lower.contains('account suspended') || lower.contains('sbi') || lower.contains('hdfc') || lower.contains('kyc')) {
      scamType = "Banking Phishing";
      indicators.add("• Account threat or KYC update demand");
      if (lower.contains('http') || lower.contains('verify') || lower.contains('otp')) {
        indicators.add("• Embedded login or OTP verification request");
        confidence = "High";
      } else {
        confidence = "Medium";
      }
    } else if (lower.contains('won') || lower.contains('lottery') || lower.contains('prize') || lower.contains('claim reward')) {
      scamType = "Prize / Reward Scam";
      indicators.add("• Unsolicited prize claim solicitation");
      indicators.add("• Urgency to claim reward funds");
      confidence = "High";
    } else if (lower.contains('package') || lower.contains('delivery failed') || lower.contains('courier') || lower.contains('address update')) {
      scamType = "Delivery / Courier Phishing";
      indicators.add("• Fake delivery fee or address verification demand");
      confidence = "High";
    } else if (lower.contains('otp') || lower.contains('verification code') || lower.contains('do not share')) {
      scamType = "Credential / OTP Interception";
      indicators.add("• Direct request for sensitive security OTP code");
      confidence = "High";
    } else if (lower.contains('job') || lower.contains('work from home') || lower.contains('daily income') || lower.contains('telegram')) {
      scamType = "Employment / Task Scam";
      indicators.add("• High yield work-from-home lure");
      confidence = "Medium";
    }

    return ScamDetectorResult(
      scamType: scamType,
      indicators: indicators,
      confidence: confidence,
    );
  }
}
