package com.sivaraj.securebubble_pro

class AIAnalyzer {

    fun analyze(url: String): Pair<Boolean, String> {

        val suspiciousWords = listOf(
            "login",
            "verify",
            "secure",
            "account",
            "bank",
            "update",
            "password",
            "signin",
            "wallet",
            "gift",
            "bonus",
            "free",
            "otp"
        )

        for (word in suspiciousWords) {

            if (url.lowercase().contains(word)) {

                return Pair(
                    false,
                    "Suspicious keyword detected : $word"
                )

            }

        }

        return Pair(
            true,
            "No suspicious keyword detected"
        )

    }

}