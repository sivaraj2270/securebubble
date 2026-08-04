package com.sivaraj.securebubble_pro

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

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
