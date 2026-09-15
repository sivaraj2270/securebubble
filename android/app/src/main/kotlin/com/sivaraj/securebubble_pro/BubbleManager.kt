package com.sivaraj.securebubble_pro

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import kotlin.math.abs

class BubbleManager(private val context: Context) {

    private lateinit var popupManager: PopupManager
    private val ocrManager = OCRManager()
    private val qrManager = QRManager()
    private val threatScanner = RealThreatScanner()
    private val linkDetector = LinkDetector()

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var bubbleView: View? = null
    private var params: WindowManager.LayoutParams? = null

    private val handler = Handler(Looper.getMainLooper())
    private var isLongPressed = false
    private var longPressRunnable: Runnable? = null

    @SuppressLint("ClickableViewAccessibility")
    fun showBubble() {

        popupManager = PopupManager(context)

        if (bubbleView != null) return

        bubbleView = LayoutInflater.from(context)
            .inflate(R.layout.bubble_layout, null)

        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,

            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,

            PixelFormat.TRANSLUCENT
        )

        params?.gravity = Gravity.TOP or Gravity.START
        params?.x = 0
        params?.y = 350

        try {
            windowManager.addView(bubbleView, params)
        } catch (e: Exception) {
            e.printStackTrace()
            return
        }

        Toast.makeText(
            context,
            "NUKEZERO Shield Active • Tap Bubble to Scan Screen",
            Toast.LENGTH_LONG
        ).show()

        bubbleView?.setOnTouchListener(object : View.OnTouchListener {

            private var initialX = 0
            private var initialY = 0

            private var initialTouchX = 0f
            private var initialTouchY = 0f

            override fun onTouch(v: View?, event: MotionEvent): Boolean {

                when (event.action) {

                    MotionEvent.ACTION_DOWN -> {

                        initialX = params!!.x
                        initialY = params!!.y

                        initialTouchX = event.rawX
                        initialTouchY = event.rawY

                        isLongPressed = false

                        // Start 450ms long press timer
                        longPressRunnable = Runnable {
                            isLongPressed = true
                            v?.performHapticFeedback(android.view.HapticFeedbackConstants.LONG_PRESS)
                            showRadialSecurityModeMenu()
                        }
                        handler.postDelayed(longPressRunnable!!, 450)

                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {

                        val dx = abs(event.rawX - initialTouchX)
                        val dy = abs(event.rawY - initialTouchY)

                        // If user moved more than 15px, cancel long press
                        if (dx > 15 || dy > 15) {
                            longPressRunnable?.let { handler.removeCallbacks(it) }
                        }

                        params!!.x =
                            initialX + (event.rawX - initialTouchX).toInt()

                        params!!.y =
                            initialY + (event.rawY - initialTouchY).toInt()

                        try {
                            windowManager.updateViewLayout(
                                bubbleView,
                                params
                            )
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }

                        return true
                    }

                    MotionEvent.ACTION_UP -> {

                        longPressRunnable?.let { handler.removeCallbacks(it) }

                        val dx = abs(event.rawX - initialTouchX)
                        val dy = abs(event.rawY - initialTouchY)

                        // Single tap click on floating bubble -> Directly scan current screen
                        if (!isLongPressed && dx < 15 && dy < 15) {
                            executeScreenScan(linkDetector, threatScanner)
                        }

                        snapToEdge()

                        return true
                    }
                }

                return false
            }

        })

    }

    private fun showRadialSecurityModeMenu() {
        popupManager.showRadialSecurityMenu { selectedMode ->
            when (selectedMode) {
                "QUICK_SCAN" -> {
                    Toast.makeText(context, "🔍 Quick Scan Activated", Toast.LENGTH_SHORT).show()
                    executeScreenScan(linkDetector, threatScanner)
                }
                "QR_SCAN" -> {
                    Toast.makeText(context, "📷 QR Code Lens Scan", Toast.LENGTH_SHORT).show()
                    executeScreenScan(linkDetector, threatScanner)
                }
                "URL_SCAN" -> {
                    showNormalScanPrompt()
                }
                "SCREENSHOT" -> {
                    Toast.makeText(context, "📄 Full Pixel Screenshot Capture", Toast.LENGTH_SHORT).show()
                    executeScreenScan(linkDetector, threatScanner)
                }
                "AI_SCAN" -> {
                    Toast.makeText(context, "🤖 AI Threat Score Calculation", Toast.LENGTH_SHORT).show()
                    executeScreenScan(linkDetector, threatScanner)
                }
                "DEEP_SCAN" -> {
                    Toast.makeText(context, "🔬 Deep VirusTotal 90-Engine Scan", Toast.LENGTH_SHORT).show()
                    executeScreenScan(linkDetector, threatScanner)
                }
            }
        }
    }

    private fun showNormalScanPrompt() {
        popupManager.showScanPermissionPrompt(
            onConfirmScreenScan = {
                executeScreenScan(linkDetector, threatScanner)
            },
            onScanCustomText = { customText ->
                popupManager.showScanningProgress()
                runScanThread(customText, linkDetector, threatScanner)
            },
            onCancel = {
                Toast.makeText(context, "Scan Canceled", Toast.LENGTH_SHORT).show()
            }
        )
    }

    private fun executeScreenScan(linkDetector: LinkDetector, threatScanner: RealThreatScanner) {
        // Step 1: Immediately display the 10-15s animated scanning overlay card
        popupManager.showScanningProgress()

        // Clear stale cached text from previous scans
        ScreenTextHolder.text = ""

        val accService = SecureBubbleAccessibilityService.instance
        if (accService == null) {
            popupManager.removePopup()
            Toast.makeText(
                context,
                "Please enable NUKEZERO Shield under Accessibility -> Installed Apps",
                Toast.LENGTH_LONG
            ).show()
            try {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            return
        }

        // Fetch all screen links from accessibility tree
        val allNodeLinks = accService.getAllScreenLinks().joinToString(" ")

        accService.captureScreen { bitmap: Bitmap? ->
            if (bitmap != null) {
                qrManager.scanQr(
                    bitmap,
                    onSuccess = { qrPayloads ->
                        ocrManager.readText(
                            bitmap,
                            onSuccess = { ocrText ->
                                val qrText = qrPayloads.joinToString(" ")
                                val combined = "$qrText $ocrText $allNodeLinks".trim()
                                runScanThread(combined, linkDetector, threatScanner)
                            },
                            onFailure = {
                                val qrText = qrPayloads.joinToString(" ")
                                val combined = "$qrText $allNodeLinks".trim()
                                runScanThread(combined, linkDetector, threatScanner)
                            }
                        )
                    },
                    onFailure = {
                        ocrManager.readText(
                            bitmap,
                            onSuccess = { ocrText ->
                                val combined = "$ocrText $allNodeLinks".trim()
                                runScanThread(combined, linkDetector, threatScanner)
                            },
                            onFailure = {
                                fallbackScan(allNodeLinks, linkDetector, threatScanner)
                            }
                        )
                    }
                )
            } else {
                fallbackScan(allNodeLinks, linkDetector, threatScanner)
            }
        }
    }

    private fun fallbackScan(allNodeLinks: String, linkDetector: LinkDetector, threatScanner: RealThreatScanner) {
        val text = allNodeLinks.ifEmpty { ScreenTextHolder.text }
        runScanThread(text, linkDetector, threatScanner)
    }

    private fun runScanThread(rawText: String, linkDetector: LinkDetector, threatScanner: RealThreatScanner) {
        Thread {
            val links = linkDetector.extractLinks(rawText)
            val report = threatScanner.performRealScan(rawText, links)

            Handler(Looper.getMainLooper()).post {
                popupManager.showThreatReport(report)
            }
        }.start()
    }

    private fun snapToEdge() {

        if (bubbleView == null || params == null) return

        val displayWidth =
            context.resources.displayMetrics.widthPixels

        val bubbleWidth =
            bubbleView!!.width

        if (params!!.x >= displayWidth / 2) {

            params!!.x = displayWidth - bubbleWidth

        } else {

            params!!.x = 0

        }

        try {

            windowManager.updateViewLayout(
                bubbleView,
                params
            )

        } catch (e: Exception) {

            e.printStackTrace()

        }

    }

    fun removeBubble() {

        popupManager.removePopup()

        bubbleView?.let {

            try {

                windowManager.removeView(it)

            } catch (e: Exception) {

                e.printStackTrace()

            }

        }

        bubbleView = null
        params = null

    }

}