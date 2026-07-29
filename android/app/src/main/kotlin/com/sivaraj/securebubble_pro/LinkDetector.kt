package com.sivaraj.securebubble_pro

class LinkDetector {

    fun extractLinks(text: String): List<String> {

        val regex = Regex(
            "(https?://[^\\s]+|www\\.[^\\s]+)"
        )

        return regex.findAll(text)
            .map { it.value }
            .toList()
    }

}