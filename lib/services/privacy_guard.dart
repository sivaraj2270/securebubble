class PrivacyGuard {
  static List<String> scanForSensitiveData(String text) {
    final alerts = <String>[];

    final emailRegExp = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b');
    if (emailRegExp.hasMatch(text)) {
      alerts.add("🔐 PRIVACY ALERT: Email address detected on screen. Avoid sharing publicly.");
    }

    final phoneRegExp = RegExp(r'\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b');
    if (phoneRegExp.hasMatch(text)) {
      alerts.add("🔐 PRIVACY ALERT: Personal phone number detected on screen.");
    }

    final otpRegExp = RegExp(r'\b(?:OTP|code|verification)\s*(?:is|:)?\s*(\d{4,8})\b', caseSensitive: false);
    if (otpRegExp.hasMatch(text)) {
      alerts.add("🚨 CRITICAL PRIVACY ALERT: OTP / One-Time Passcode detected on screen. Never reveal OTPs to third parties!");
    }

    final apiKeyRegExp = RegExp(r'\b(AIzaSy[A-Za-z0-9_-]{33}|[a-f0-9]{32,64}|Bearer\s+[A-Za-z0-9._-]{20,})\b');
    if (apiKeyRegExp.hasMatch(text)) {
      alerts.add("🔐 PRIVACY ALERT: API Key / Secret Access Token detected on screen.");
    }

    final cardRegExp = RegExp(r'\b(?:\d[ -]*?){13,16}\b');
    if (cardRegExp.hasMatch(text) && !text.contains('http')) {
      alerts.add("🔐 PRIVACY ALERT: Payment card number pattern detected on screen.");
    }

    return alerts;
  }
}
