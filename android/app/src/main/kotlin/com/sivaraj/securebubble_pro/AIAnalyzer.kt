package com.sivaraj.securebubble_pro

data class ThreatResult(
    val threatLevel: String, // "SAFE", "MEDIUM RISK", "HIGH RISK", "DANGEROUS"
    val score: Int,
    val category: String,
    val detectedUrl: String,
    val explanation: String,
    val recommendation: String
)

class AIAnalyzer {

    fun analyzeContent(text: String, urls: List<String>): ThreatResult {
        val lowerText = text.lowercase()
        val primaryUrl = if (urls.isNotEmpty()) urls.first() else ""

        // 1. Phishing & Link Shortener Check
        if (urls.any { u -> 
            val lu = u.lowercase()
            lu.contains("bit.ly") || lu.contains("tinyurl.com") || lu.contains("t.co") || 
            lu.contains("is.gd") || lu.contains("goo.gl") || lu.contains("ip-") || 
            (lu.startsWith("http://") && !lu.contains("localhost"))
        }) {
            return ThreatResult(
                threatLevel = "HIGH RISK",
                score = 85,
                category = "Phishing Link",
                detectedUrl = primaryUrl,
                explanation = "A suspicious link shortener or unencrypted URL was detected. Shortened URLs conceal the real destination domain.",
                recommendation = "Do not click this link or verify the origin before opening."
            )
        }

        // 2. Brand Spoofing & Credential Harvesting
        if (urls.any { u ->
            val lu = u.lowercase()
            lu.contains("login") || lu.contains("verify") || lu.contains("secure") || 
            lu.contains("account") || lu.contains("bank") || lu.contains("update") || 
            lu.contains("password") || lu.contains("signin") || lu.contains("wallet") ||
            lu.contains("paypal") || lu.contains("sbi") || lu.contains("hdfc")
        } || lowerText.contains("verify your account") || lowerText.contains("reset password") || lowerText.contains("enter otp")) {
            return ThreatResult(
                threatLevel = "DANGEROUS",
                score = 95,
                category = "Credential Harvesting",
                detectedUrl = primaryUrl,
                explanation = "The screen text contains credential phishing keywords or spoofed login forms requesting sensitive passwords or OTPs.",
                recommendation = "NEVER enter your password, PIN, or OTP on this form."
            )
        }

        // 3. Delivery / SMS / Lottery Scam
        if (lowerText.contains("delivery failed") || lowerText.contains("customs fee") || 
            lowerText.contains("unclaimed package") || lowerText.contains("lottery winner") || 
            lowerText.contains("claim prize") || lowerText.contains("crypto double")) {
            return ThreatResult(
                threatLevel = "HIGH RISK",
                score = 78,
                category = "Scam Message",
                detectedUrl = primaryUrl,
                explanation = "Message matches fraudulent parcel delivery or prize lottery scams designed to trick users into paying fees.",
                recommendation = "Do not pay any fees or provide personal information."
            )
        }

        // 4. General Links Present
        if (urls.isNotEmpty()) {
            return ThreatResult(
                threatLevel = "MEDIUM RISK",
                score = 45,
                category = "External Link Detected",
                detectedUrl = primaryUrl,
                explanation = "External web address detected on screen: $primaryUrl. Exercise personal caution.",
                recommendation = "Verify the domain name carefully in your browser address bar."
            )
        }

        // 5. Clean / Safe
        return ThreatResult(
            threatLevel = "SAFE",
            score = 5,
            category = "Clean Screen",
            detectedUrl = "",
            explanation = "No phishing links, brand spoofing, or fraudulent scam markers were detected on the screen.",
            recommendation = "No threat detected. Regular safety vigilance is recommended."
        )
    }
}