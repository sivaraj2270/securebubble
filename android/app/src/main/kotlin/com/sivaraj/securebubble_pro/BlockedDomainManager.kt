package com.sivaraj.securebubble_pro

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.net.URI

data class BlockedDomainInfo(
    val domain: String,
    val reason: String,
    val riskScore: Int,
    val source: String, // "USER_BLOCKED", "AI_BLOCKED", "THREAT_INTELLIGENCE_BLOCKED"
    val blockedAt: String
)

class BlockedDomainManager(private val context: Context) {

    companion object {
        private const val PREFS_NAME = "securebubble_blocked_domains_v1"
        private const val KEY_DOMAINS = "blocked_domains_json"

        @Volatile
        private var instance: BlockedDomainManager? = null

        fun getInstance(context: Context): BlockedDomainManager {
            return instance ?: synchronized(this) {
                instance ?: BlockedDomainManager(context.applicationContext).also { instance = it }
            }
        }

        fun normalizeDomain(input: String): String {
            if (input.isBlank()) return ""
            return try {
                var clean = input.trim().lowercase()
                if (!clean.startsWith("http://") && !clean.startsWith("https://")) {
                    clean = "https://$clean"
                }
                val uri = URI(clean)
                var host = uri.host ?: ""
                if (host.startsWith("www.")) {
                    host = host.substring(4)
                }
                val parts = host.split(".")
                if (parts.size >= 2) {
                    parts.takeLast(2).joinToString(".")
                } else host
            } catch (e: Exception) {
                input.trim().lowercase()
                    .replace(Regex("^(https?://)?(www\\.)?"), "")
                    .split("/")[0]
                    .split("?")[0]
            }
        }
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    @Synchronized
    fun addDomain(rawDomainOrUrl: String, reason: String = "Possible Phishing", riskScore: Int = 94, source: String = "USER_BLOCKED"): Boolean {
        val domain = normalizeDomain(rawDomainOrUrl)
        if (domain.isBlank()) return false

        val currentList = getBlockedDomainsList().toMutableList()
        if (currentList.none { it.domain.equals(domain, ignoreCase = true) }) {
            val newItem = BlockedDomainInfo(
                domain = domain,
                reason = reason,
                riskScore = riskScore,
                source = source,
                blockedAt = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.US).format(java.util.Date())
            )
            currentList.add(newItem)
            saveList(currentList)
            return true
        }
        return false
    }

    @Synchronized
    fun removeDomain(rawDomainOrUrl: String): Boolean {
        val domain = normalizeDomain(rawDomainOrUrl)
        if (domain.isBlank()) return false

        val currentList = getBlockedDomainsList().toMutableList()
        val removed = currentList.removeAll { it.domain.equals(domain, ignoreCase = true) }
        if (removed) {
            saveList(currentList)
        }
        return removed
    }

    fun isBlocked(rawDomainOrUrl: String): Boolean {
        if (rawDomainOrUrl.isBlank()) return false
        val targetHost = extractHostName(rawDomainOrUrl)
        if (targetHost.isBlank()) return false

        val blockedList = getBlockedDomainsList()

        for (item in blockedList) {
            val blockedDomain = item.domain.lowercase()
            // Exact match or subdomain match (e.g. www.fakebank.com or login.fakebank.com matches fakebank.com)
            if (targetHost == blockedDomain || targetHost.endsWith(".$blockedDomain")) {
                return true
            }
        }
        return false
    }

    fun getBlockedDomainDetails(rawDomainOrUrl: String): BlockedDomainInfo? {
        val targetHost = extractHostName(rawDomainOrUrl)
        val blockedList = getBlockedDomainsList()
        for (item in blockedList) {
            val blockedDomain = item.domain.lowercase()
            if (targetHost == blockedDomain || targetHost.endsWith(".$blockedDomain")) {
                return item
            }
        }
        return null
    }

    fun getBlockedDomainsList(): List<BlockedDomainInfo> {
        val jsonStr = prefs.getString(KEY_DOMAINS, null) ?: return emptyList()
        val result = mutableListOf<BlockedDomainInfo>()
        try {
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                result.add(
                    BlockedDomainInfo(
                        domain = obj.getString("domain"),
                        reason = obj.optString("reason", "User Blocked"),
                        riskScore = obj.optInt("riskScore", 94),
                        source = obj.optString("source", "USER_BLOCKED"),
                        blockedAt = obj.optString("blockedAt", "")
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    @Synchronized
    fun clearBlockedDomains() {
        prefs.edit().remove(KEY_DOMAINS).apply()
    }

    private fun saveList(list: List<BlockedDomainInfo>) {
        val array = JSONArray()
        for (item in list) {
            val obj = JSONObject()
            obj.put("domain", item.domain)
            obj.put("reason", item.reason)
            obj.put("riskScore", item.riskScore)
            obj.put("source", item.source)
            obj.put("blockedAt", item.blockedAt)
            array.put(obj)
        }
        prefs.edit().putString(KEY_DOMAINS, array.toString()).apply()
    }

    private fun extractHostName(input: String): String {
        return try {
            var clean = input.trim().lowercase()
            if (!clean.startsWith("http://") && !clean.startsWith("https://")) {
                clean = "https://$clean"
            }
            val uri = URI(clean)
            var host = uri.host ?: ""
            if (host.startsWith("www.")) {
                host = host.substring(4)
            }
            host
        } catch (e: Exception) {
            input.trim().lowercase()
                .replace(Regex("^(https?://)?(www\\.)?"), "")
                .split("/")[0]
                .split("?")[0]
        }
    }
}
