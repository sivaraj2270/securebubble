package com.sivaraj.securebubble_pro

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.text.style.ClickableSpan
import android.text.style.URLSpan
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject

class SecureBubbleAccessibilityService : AccessibilityService() {

    companion object {
        var instance: SecureBubbleAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("SecureBubble", "SecureBubbleAccessibilityService Connected!")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {
            val rootNode = rootInActiveWindow ?: return
            val textBuilder = StringBuilder()
            extractNodeText(rootNode, textBuilder)
            val fullText = textBuilder.toString().trim()
            if (fullText.isNotEmpty()) {
                ScreenTextHolder.text = fullText
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getCurrentWindowText(): String {
        return try {
            val rootNode = rootInActiveWindow ?: return ""
            val textBuilder = StringBuilder()
            extractNodeText(rootNode, textBuilder)
            textBuilder.toString().trim()
        } catch (e: Exception) {
            ""
        }
    }

    fun getAllScreenLinks(): List<String> {
        val found = mutableListOf<String>()
        try {
            val rootNode = rootInActiveWindow ?: return emptyList()

            fun traverse(node: AccessibilityNodeInfo?) {
                if (node == null) return

                val rawText = node.text
                if (rawText != null) {
                    if (rawText is android.text.Spanned) {
                        val spans = rawText.getSpans(0, rawText.length, URLSpan::class.java)
                        for (span in spans) {
                            val url = span.url
                            if (!url.isNullOrBlank() && !found.contains(url)) {
                                found.add(url)
                            }
                        }
                    }
                    val str = rawText.toString().trim()
                    if (str.isNotBlank() && (str.contains("http://") || str.contains("https://") || str.contains("www.") || str.contains(".com") || str.contains(".in") || str.contains(".org") || str.contains("chatgpt"))) {
                        if (!found.contains(str)) found.add(str)
                    }
                }

                val desc = node.contentDescription?.toString()?.trim()
                if (!desc.isNullOrBlank() && (desc.contains("http://") || desc.contains("https://") || desc.contains("www."))) {
                    if (!found.contains(desc)) found.add(desc)
                }

                for (i in 0 until node.childCount) {
                    traverse(node.getChild(i))
                }
            }

            traverse(rootNode)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return found
    }

    private fun extractNodeText(node: AccessibilityNodeInfo?, builder: StringBuilder) {
        if (node == null) return
        node.text?.let {
            if (it.isNotEmpty()) {
                builder.append(it).append(" ")
            }
        }
        node.contentDescription?.let {
            if (it.isNotEmpty()) {
                builder.append(it).append(" ")
            }
        }
        for (i in 0 until node.childCount) {
            extractNodeText(node.getChild(i), builder)
        }
    }

    fun extractHyperlinkInfo(): String {
        try {
            val rootNode = rootInActiveWindow ?: return createFallbackJson("Screen content unaccessible", "Not available")
            val packageName = rootNode.packageName?.toString() ?: "Active App"

            var visibleText = ""
            var actualUrl = "Not available"

            fun searchNodeForLinks(node: AccessibilityNodeInfo?) {
                if (node == null) return

                val rawText = node.text
                if (rawText != null) {
                    if (rawText is android.text.Spanned) {
                        val spans = rawText.getSpans(0, rawText.length, URLSpan::class.java)
                        if (spans.isNotEmpty()) {
                            visibleText = rawText.toString()
                            actualUrl = spans[0].url
                            return
                        }
                    }

                    val strText = rawText.toString()
                    if (strText.contains("http://") || strText.contains("https://") || strText.contains("www.")) {
                        if (visibleText.isEmpty()) visibleText = strText
                    }
                }

                val desc = node.contentDescription?.toString()
                if (desc != null && (desc.contains("http://") || desc.contains("https://"))) {
                    if (actualUrl == "Not available") actualUrl = desc
                }

                for (i in 0 until node.childCount) {
                    searchNodeForLinks(node.getChild(i))
                    if (actualUrl != "Not available") return
                }
            }

            searchNodeForLinks(rootNode)

            if (visibleText.isEmpty() && ScreenTextHolder.text.isNotEmpty()) {
                visibleText = ScreenTextHolder.text
            }

            val resultJson = JSONObject()
            resultJson.put("visibleText", if (visibleText.isEmpty()) "No visible URL text detected" else visibleText)
            resultJson.put("actualUrl", actualUrl)
            resultJson.put("sourceApp", packageName)
            resultJson.put("domain", "")
            resultJson.put("finalUrl", actualUrl)
            resultJson.put("redirects", JSONArray())

            if (actualUrl == "Not available") {
                resultJson.put("domainMatch", false)
                resultJson.put("detectionType", "VISIBLE_URL_ONLY")
                resultJson.put("riskLevel", "SUSPICIOUS")
                resultJson.put("reason", "This application does not expose the hyperlink destination through its UI.")
            } else {
                resultJson.put("domainMatch", true)
                resultJson.put("detectionType", "HYPERLINK_EXPOSED")
                resultJson.put("riskLevel", "LOW")
                resultJson.put("reason", "Hyperlink destination extracted successfully.")
            }

            return resultJson.toString()
        } catch (e: Exception) {
            return createFallbackJson("Error inspecting UI nodes: ${e.message}", "Not available")
        }
    }

    private fun createFallbackJson(visible: String, actual: String): String {
        val json = JSONObject()
        json.put("visibleText", visible)
        json.put("actualUrl", actual)
        json.put("sourceApp", "System UI Inspection")
        json.put("domain", "Not available")
        json.put("finalUrl", "Not available")
        json.put("redirects", JSONArray())
        json.put("domainMatch", false)
        json.put("detectionType", "VISIBLE_URL_ONLY")
        json.put("riskLevel", "SUSPICIOUS")
        json.put("reason", "This application does not expose the hyperlink destination through its UI.")
        return json.toString()
    }

    fun captureScreen(onBitmapCaptured: (Bitmap?) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                takeScreenshot(
                    Display.DEFAULT_DISPLAY,
                    mainExecutor,
                    object : TakeScreenshotCallback {
                        override fun onSuccess(screenshot: ScreenshotResult) {
                            try {
                                val hardwareBuffer = screenshot.hardwareBuffer
                                val colorSpace = screenshot.colorSpace
                                val hwBitmap = Bitmap.wrapHardwareBuffer(hardwareBuffer, colorSpace)
                                if (hwBitmap != null) {
                                    val swBitmap = Bitmap.createBitmap(hwBitmap.width, hwBitmap.height, Bitmap.Config.ARGB_8888)
                                    val canvas = Canvas(swBitmap)
                                    canvas.drawBitmap(hwBitmap, 0f, 0f, null)
                                    hwBitmap.recycle()
                                    hardwareBuffer.close()
                                    Log.d("SecureBubble", "Screen Captured Successfully via Canvas: ${swBitmap.width}x${swBitmap.height}")
                                    onBitmapCaptured(swBitmap)
                                } else {
                                    hardwareBuffer.close()
                                    onBitmapCaptured(null)
                                }
                            } catch (e: Exception) {
                                Log.e("SecureBubble", "HardwareBuffer Canvas conversion error", e)
                                onBitmapCaptured(null)
                            }
                        }

                        override fun onFailure(errorCode: Int) {
                            Log.e("SecureBubble", "takeScreenshot failed with errorCode: $errorCode")
                            onBitmapCaptured(null)
                        }
                    }
                )
            } catch (e: Exception) {
                Log.e("SecureBubble", "takeScreenshot invocation error", e)
                onBitmapCaptured(null)
            }
        } else {
            onBitmapCaptured(null)
        }
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onInterrupt() {}
}
