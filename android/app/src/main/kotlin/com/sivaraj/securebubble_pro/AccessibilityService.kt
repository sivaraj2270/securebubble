package com.sivaraj.securebubble_pro

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class AccessibilityService : android.accessibilityservice.AccessibilityService() {

    companion object {
        var instance: AccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {
            val rootNode = rootInActiveWindow ?: return
            val textBuilder = StringBuilder()
            extractNodeText(rootNode, textBuilder)
            val fullText = textBuilder.toString().trim()
            if (fullText.isNotEmpty()) {
                ScreenTextHolder.text = fullText
                Log.d("SecureBubble", "Captured Screen Text: $fullText")
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
                                val bitmap = Bitmap.wrapHardwareBuffer(hardwareBuffer, colorSpace)
                                    ?.copy(Bitmap.Config.ARGB_8888, true)
                                hardwareBuffer.close()
                                onBitmapCaptured(bitmap)
                            } catch (e: Exception) {
                                e.printStackTrace()
                                onBitmapCaptured(null)
                            }
                        }

                        override fun onFailure(errorCode: Int) {
                            Log.e("SecureBubble", "takeScreenshot failed: $errorCode")
                            onBitmapCaptured(null)
                        }
                    }
                )
            } catch (e: Exception) {
                e.printStackTrace()
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