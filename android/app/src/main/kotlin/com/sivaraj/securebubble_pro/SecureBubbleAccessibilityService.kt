package com.sivaraj.securebubble_pro

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
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

    private var lastScanTime = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {
            val eventType = event?.eventType ?: return
            // Only process relevant window state/content events with an 800ms debounce filter
            if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
                eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
                return
            }

            val currentTime = System.currentTimeMillis()
            if (currentTime - lastScanTime < 800) {
                return
            }
            lastScanTime = currentTime

            val rootNode = rootInActiveWindow ?: return
            val textBuilder = StringBuilder()
            extractNodeText(rootNode, textBuilder)
            rootNode.recycle()

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

    fun performFullStructuredScreenScan(): String {
        val response = JSONObject()
        val itemsArray = JSONArray()

        try {
            val rootNode = rootInActiveWindow
            if (rootNode == null) {
                response.put("success", false)
                response.put("error", "Active window content unaccessible")
                response.put("items", itemsArray)
                return response.toString()
            }

            val pkgName = rootNode.packageName?.toString() ?: ""
            response.put("packageName", pkgName)

            val processedUrls = mutableSetOf<String>()

            fun traverseNode(node: AccessibilityNodeInfo?) {
                if (node == null) return

                val isClickable = node.isClickable
                val rawText = node.text

                // Get exact screen bounds for node overlay positioning
                val rect = android.graphics.Rect()
                node.getBoundsInScreen(rect)
                val boundsObj = JSONObject().apply {
                    put("left", rect.left)
                    put("top", rect.top)
                    put("right", rect.right)
                    put("bottom", rect.bottom)
                }

                // Parent sender/chat header text lookup
                var senderText = ""
                var parentNode = node.parent
                for (p in 0 until 3) {
                    if (parentNode == null) break
                    val pText = parentNode.text?.toString()?.trim()
                    if (!pText.isNullOrBlank() && pText != rawText?.toString()?.trim() && !pText.startsWith("http")) {
                        senderText = pText
                        break
                    }
                    parentNode = parentNode.parent
                }

                // 1. Inspect Spanned URLSpans (actual href destinations)
                if (rawText != null && rawText is android.text.Spanned) {
                    val spans = rawText.getSpans(0, rawText.length, URLSpan::class.java)
                    for (span in spans) {
                        val actualDestination = span.url
                        val visibleTextStr = rawText.toString().trim()

                        if (!actualDestination.isNullOrBlank() && !processedUrls.contains(actualDestination)) {
                            processedUrls.add(actualDestination)

                            val itemObj = JSONObject()
                            itemObj.put("text", visibleTextStr.ifEmpty { actualDestination })
                            itemObj.put("url", actualDestination)
                            itemObj.put("source", "accessibility")
                            itemObj.put("clickable", isClickable)
                            itemObj.put("packageName", pkgName)
                            itemObj.put("bounds", boundsObj)
                            itemObj.put("associatedChat", senderText)

                            // Detect Disguised Link Mismatch
                            val visibleDomain = extractDomain(visibleTextStr)
                            val actualDomain = extractDomain(actualDestination)

                            if (visibleDomain.isNotEmpty() && actualDomain.isNotEmpty() && visibleDomain != actualDomain) {
                                itemObj.put("domainMatch", false)
                                itemObj.put("detectionType", "DECEPTIVE_HYPERLINK")
                                itemObj.put("warning", "⚠️ Link mismatch detected! Visible text claims '$visibleDomain' but actual destination is '$actualDomain'.")
                            } else {
                                itemObj.put("domainMatch", true)
                                itemObj.put("detectionType", "HYPERLINK_EXPOSED")
                                itemObj.put("warning", "")
                            }

                            itemsArray.put(itemObj)
                        }
                    }
                }

                // 2. Inspect Plain Node Text & Content Description for URLs
                val nodeTextStr = rawText?.toString()?.trim() ?: ""
                val descStr = node.contentDescription?.toString()?.trim() ?: ""

                for (targetStr in listOf(nodeTextStr, descStr)) {
                    if (targetStr.isNotBlank()) {
                        val urlRegex = Regex("(?i)\\b(https?://|www\\.)[^\\s<>\"]+", RegexOption.IGNORE_CASE)
                        for (match in urlRegex.findAll(targetStr)) {
                            var cleanUrl = match.value.trim().trimEnd('.', ',', ')', '(', '"', '\'')
                            if (cleanUrl.startsWith("www.", ignoreCase = true)) {
                                cleanUrl = "https://$cleanUrl"
                            }

                            if (!processedUrls.contains(cleanUrl)) {
                                processedUrls.add(cleanUrl)

                                val itemObj = JSONObject()
                                itemObj.put("text", targetStr)
                                itemObj.put("url", cleanUrl)
                                itemObj.put("source", "accessibility")
                                itemObj.put("clickable", isClickable)
                                itemObj.put("packageName", pkgName)
                                itemObj.put("bounds", boundsObj)
                                itemObj.put("associatedChat", senderText)
                                itemObj.put("domainMatch", true)
                                itemObj.put("detectionType", "VISIBLE_TEXT_URL")
                                itemObj.put("warning", "")

                                itemsArray.put(itemObj)
                            }
                        }
                    }
                }

                for (i in 0 until node.childCount) {
                    val child = node.getChild(i)
                    if (child != null) {
                        traverseNode(child)
                        try {
                            child.recycle()
                        } catch (_: Exception) {}
                    }
                }
            }

            traverseNode(rootNode)

            response.put("success", true)
            response.put("items", itemsArray)
            return response.toString()

        } catch (e: Exception) {
            response.put("success", false)
            response.put("error", e.message)
            response.put("items", itemsArray)
            return response.toString()
        }
    }

    private fun extractDomain(input: String): String {
        return try {
            var clean = input.trim().lowercase()
            if (!clean.startsWith("http://") && !clean.startsWith("https://")) {
                clean = "https://$clean"
            }
            val uri = java.net.URI(clean)
            val host = uri.host ?: ""
            val parts = host.split(".")
            if (parts.size >= 2) {
                parts.subList(parts.size - 2, parts.size).joinToString(".")
            } else host
        } catch (_: Exception) {
            ""
        }
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
            val child = node.getChild(i)
            if (child != null) {
                extractNodeText(child, builder)
                try {
                    child.recycle()
                } catch (_: Exception) {}
            }
        }
    }

    fun extractHyperlinkInfo(): String {
        return performFullStructuredScreenScan()
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
