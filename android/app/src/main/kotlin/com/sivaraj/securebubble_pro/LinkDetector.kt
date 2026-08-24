package com.sivaraj.securebubble_pro

class LinkDetector {

    fun extractLinks(text: String): List<String> {
        if (text.isBlank()) return emptyList()

        val results = mutableListOf<String>()

        // Preprocess: Replace soft hyphens, linebreaks, and internal space breaks inside URLs
        val normalizedText = normalizeScreenText(text)

        // 1. HTTP / HTTPS / UPI Scheme URLs (handles chatgpt.com, youtu.be, youtube.com, docs.google.com, etc.)
        val schemeRegex = Regex("(?i)\\b(https?|upi)://[^\\s<>\"]+", RegexOption.IGNORE_CASE)
        for (match in schemeRegex.findAll(normalizedText)) {
            val clean = sanitizeUrl(match.value)
            if (clean.isNotEmpty() && !results.contains(clean)) {
                results.add(clean)
            }
        }

        // 2. www. links
        val wwwRegex = Regex("(?i)\\bwww\\.[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+(/[^\\s<>\"]*)?", RegexOption.IGNORE_CASE)
        for (match in wwwRegex.findAll(normalizedText)) {
            val clean = sanitizeUrl(match.value)
            if (clean.isNotEmpty() && !results.contains(clean)) {
                results.add(clean)
            }
        }

        // 3. Shortened links & raw domain names (chatgpt.com, github.com, youtu.be, google.com, swiggy.com, trycloudflare.com, etc.)
        val domainRegex = Regex(
            "(?i)\\b[a-zA-Z0-9-]+\\.(trycloudflare\\.com|ngrok-free\\.app|ngrok\\.io|serveo\\.net|loca\\.lt|pagekite\\.me|chatgpt\\.com|github\\.com|google\\.com|youtube\\.com|zomato\\.com|swiggy\\.com|com|in|org|net|xyz|top|io|app|dev|co|me|site|online|tech|info|biz|icu|be|gov|edu|ca|uk|us|de|fr)(/[^\\s<>\"]*)?",
            RegexOption.IGNORE_CASE
        )
        for (match in domainRegex.findAll(normalizedText)) {
            val clean = sanitizeUrl(match.value)
            if (clean.isNotEmpty() && !results.contains(clean)) {
                results.add(clean)
            }
        }

        return results
    }

    private fun normalizeScreenText(raw: String): String {
        // Fix line wrapping in chat messages: "https://chatgpt.com/\nshare/xyz" -> "https://chatgpt.com/share/xyz"
        var text = raw.replace("\r\n", "\n")
        text = text.replace(Regex("(https?://[^\\s]+)\\n+([^\\s]+)"), "$1$2")
        text = text.replace(Regex("(?i)https?:\\s+//"), "https://")
        text = text.replace(Regex("(?i)http:\\s+//"), "http://")
        return text
    }

    private fun sanitizeUrl(raw: String): String {
        var clean = raw.trim()
        val trailingNoise = charArrayOf('.', ',', ')', '(', '"', '\'', ']', '[', '>', '<', '}', '{', ';', ':', '!')
        clean = clean.trimEnd(*trailingNoise)
        return clean
    }
}