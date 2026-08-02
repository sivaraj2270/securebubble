package com.sivaraj.securebubble_pro

import java.net.HttpURLConnection
import java.net.URL
import java.net.URLDecoder
import java.nio.charset.StandardCharsets

object URLDecoderHelper {

    fun unshortenUrl(urlStr: String): String {
        var currentUrl = urlStr.trim()
        if (!currentUrl.startsWith("http://") && !currentUrl.startsWith("https://")) {
            currentUrl = "https://$currentUrl"
        }

        try {
            var connCount = 0
            while (connCount < 5) {
                val url = URL(currentUrl)
                val conn = url.openConnection() as HttpURLConnection
                conn.instanceFollowRedirects = false
                conn.connectTimeout = 3000
                conn.readTimeout = 3000
                conn.requestMethod = "HEAD"
                conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

                val responseCode = conn.responseCode
                if (responseCode in 300..399) {
                    val location = conn.getHeaderField("Location") ?: break
                    val nextUrl = if (location.startsWith("http")) {
                        location
                    } else {
                        val base = URL(currentUrl)
                        URL(base, location).toString()
                    }
                    if (nextUrl == currentUrl) break
                    currentUrl = nextUrl
                    connCount++
                } else {
                    break
                }
            }
        } catch (e: Exception) {
            // Keep current resolved URL on connection error
        }

        try {
            return URLDecoder.decode(currentUrl, StandardCharsets.UTF_8.name())
        } catch (e: Exception) {
            return currentUrl
        }
    }
}
