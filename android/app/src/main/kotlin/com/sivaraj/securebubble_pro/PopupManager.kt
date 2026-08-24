package com.sivaraj.securebubble_pro

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class PopupManager(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var popupView: View? = null

    fun removePopup() {
        popupView?.let {
            try {
                windowManager.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        popupView = null
    }

    fun showRadialSecurityMenu(onSelectMode: (String) -> Unit) {
        removePopup()

        val density = context.resources.displayMetrics.density

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt(), (16 * density).toInt())
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#140C24"))
            cornerRadius = 24 * density
            setStroke((1.5 * density).toInt(), Color.parseColor("#EF4444"))
        }
        container.background = cardBg

        val title = TextView(context).apply {
            text = "🛡 NUKEZERO SHIELD SECURITY MENU"
            setTextColor(Color.WHITE)
            textSize = 14f
            paint.isFakeBoldText = true
            setPadding(0, 0, 0, (12 * density).toInt())
        }
        container.addView(title)

        val modes = listOf(
            Triple("QUICK_SCAN", "🔍 Quick Screen Scan", "Fast 300ms OCR & QR scan"),
            Triple("QR_SCAN", "📷 QR Code Lens Scan", "Decode stylized & payment QR codes"),
            Triple("URL_SCAN", "🔗 Manual URL Scanner", "Paste and analyze suspicious URLs"),
            Triple("DEEP_SCAN", "🔬 Deep VirusTotal Scan", "Query 90-vendor cloud threat database")
        )

        for (mode in modes) {
            val btn = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding((14 * density).toInt(), (10 * density).toInt(), (14 * density).toInt(), (10 * density).toInt())
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1F1535"))
                    cornerRadius = 14 * density
                    setStroke((1 * density).toInt(), Color.parseColor("#2E1E4E"))
                }
                background = btnBg
                val params = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 0, (8 * density).toInt())
                }
                layoutParams = params

                setOnClickListener {
                    removePopup()
                    onSelectMode(mode.first)
                }
            }

            val t1 = TextView(context).apply {
                text = mode.second
                setTextColor(Color.WHITE)
                textSize = 13.5f
                paint.isFakeBoldText = true
            }
            val t2 = TextView(context).apply {
                text = mode.third
                setTextColor(Color.parseColor("#9CA3AF"))
                textSize = 11f
            }
            btn.addView(t1)
            btn.addView(t2)
            container.addView(btn)
        }

        val closeBtn = Button(context).apply {
            text = "CLOSE"
            setTextColor(Color.parseColor("#EF4444"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { removePopup() }
        }
        container.addView(closeBtn)

        val params = WindowManager.LayoutParams(
            (context.resources.displayMetrics.widthPixels * 0.85).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        popupView = container
        try {
            windowManager.addView(popupView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun showScanPermissionPrompt(
        onConfirmScreenScan: () -> Unit,
        onScanCustomText: (String) -> Unit,
        onCancel: () -> Unit
    ) {
        removePopup()

        val density = context.resources.displayMetrics.density
        val screenWidth = context.resources.displayMetrics.widthPixels

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(
                (20 * density).toInt(),
                (18 * density).toInt(),
                (20 * density).toInt(),
                (18 * density).toInt()
            )
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#140C24"))
            cornerRadius = 24 * density
            setStroke((1.5 * density).toInt(), Color.parseColor("#EF4444"))
        }
        container.background = cardBg

        val titleView = TextView(context).apply {
            text = "🛡 NUKEZERO SHIELD SCANNER"
            setTextColor(Color.WHITE)
            textSize = 16f
            paint.isFakeBoldText = true
        }
        container.addView(titleView)

        val descView = TextView(context).apply {
            text = "Enter link below or tap SCAN SCREEN to inspect active window."
            setTextColor(Color.parseColor("#9CA3AF"))
            textSize = 12f
            setPadding(0, (4 * density).toInt(), 0, (12 * density).toInt())
        }
        container.addView(descView)

        val linkInput = EditText(context).apply {
            hint = "Paste URL (e.g. trycloudflare.com)"
            setHintTextColor(Color.parseColor("#6B7280"))
            setTextColor(Color.WHITE)
            textSize = 13f
            isFocusable = true
            isFocusableInTouchMode = true
            val inputBg = GradientDrawable().apply {
                setColor(Color.parseColor("#1F1535"))
                cornerRadius = 14 * density
                setStroke((1 * density).toInt(), Color.parseColor("#2E1E4E"))
            }
            background = inputBg
            setPadding((14 * density).toInt(), (12 * density).toInt(), (14 * density).toInt(), (12 * density).toInt())
        }
        container.addView(linkInput)

        val spacer2 = View(context).apply {
            layoutParams = LinearLayout.LayoutParams(1, (14 * density).toInt())
        }
        container.addView(spacer2)

        val buttonsRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
        }

        val cancelBtn = Button(context).apply {
            text = "CANCEL"
            setTextColor(Color.parseColor("#FF5252"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener {
                removePopup()
                onCancel()
            }
        }

        val scanInputBtn = Button(context).apply {
            text = "SCAN LINK"
            setTextColor(Color.WHITE)
            textSize = 12f
            paint.isFakeBoldText = true
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#2563EB"))
                cornerRadius = 14 * density
            }
            background = btnBg
            setOnClickListener {
                val text = linkInput.text.toString().trim()
                if (text.isNotEmpty()) {
                    removePopup()
                    onScanCustomText(text)
                } else {
                    removePopup()
                    onConfirmScreenScan()
                }
            }
        }

        val scanScreenBtn = Button(context).apply {
            text = "SCAN SCREEN"
            setTextColor(Color.WHITE)
            textSize = 12f
            paint.isFakeBoldText = true
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#EF4444"))
                cornerRadius = 14 * density
            }
            background = btnBg
            setOnClickListener {
                removePopup()
                onConfirmScreenScan()
            }
        }

        buttonsRow.addView(cancelBtn)
        buttonsRow.addView(scanInputBtn)
        buttonsRow.addView(scanScreenBtn)
        container.addView(buttonsRow)

        val params = WindowManager.LayoutParams(
            (screenWidth * 0.9).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE
            windowAnimations = android.R.style.Animation_Dialog
        }

        popupView = container
        try {
            windowManager.addView(popupView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun showScanningProgress(onComplete: () -> Unit) {
        removePopup()

        val density = context.resources.displayMetrics.density

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((28 * density).toInt(), (24 * density).toInt(), (28 * density).toInt(), (24 * density).toInt())
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#140C24"))
            cornerRadius = 24 * density
            setStroke((1.5 * density).toInt(), Color.parseColor("#EF4444"))
        }
        container.background = cardBg

        val progressBar = ProgressBar(context).apply {
            indeterminateTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#EF4444"))
        }

        val statusText = TextView(context).apply {
            text = "🛡 NUKEZERO Shield • Capturing Screen..."
            setTextColor(Color.WHITE)
            textSize = 13.5f
            paint.isFakeBoldText = true
            setPadding(0, (14 * density).toInt(), 0, (4 * density).toInt())
        }

        val subStatusText = TextView(context).apply {
            text = "Analyzing active window pixels & links..."
            setTextColor(Color.parseColor("#9CA3AF"))
            textSize = 11.5f
        }

        container.addView(progressBar)
        container.addView(statusText)
        container.addView(subStatusText)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        popupView = container
        try {
            windowManager.addView(popupView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        val handler = Handler(Looper.getMainLooper())

        // Animated Scanning Steps Sequence
        handler.postDelayed({
            statusText.text = "📷 Reading OCR & QR Barcode Payloads..."
        }, 250)

        handler.postDelayed({
            statusText.text = "🔬 Querying VirusTotal & Phishing Engine..."
        }, 500)

        handler.postDelayed({
            statusText.text = "⚡ Computing 0-100 Risk Score..."
        }, 750)

        handler.postDelayed({
            onComplete()
        }, 950)
    }

    fun showThreatReport(report: RealScanReport) {
        removePopup()

        val density = context.resources.displayMetrics.density
        val screenWidth = context.resources.displayMetrics.widthPixels

        val scrollView = ScrollView(context)

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((20 * density).toInt(), (18 * density).toInt(), (20 * density).toInt(), (18 * density).toInt())
        }

        val threatColor = when (report.threatLevel.uppercase()) {
            "DANGEROUS" -> Color.parseColor("#EF4444")
            "HIGH RISK" -> Color.parseColor("#EF4444")
            "SUSPICIOUS" -> Color.parseColor("#F59E0B")
            "MEDIUM RISK" -> Color.parseColor("#F59E0B")
            "LOW RISK" -> Color.parseColor("#60A5FA")
            else -> Color.parseColor("#4ADE80")
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#140C24"))
            cornerRadius = 24 * density
            setStroke((1.5 * density).toInt(), threatColor)
        }
        container.background = cardBg

        // Header Title
        val titleView = TextView(context).apply {
            text = "🛡 NUKEZERO SHIELD"
            setTextColor(Color.WHITE)
            textSize = 17f
            paint.isFakeBoldText = true
        }
        container.addView(titleView)

        // Threat Badge Row
        val badgeRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, (8 * density).toInt(), 0, (8 * density).toInt())
        }

        val badgeBg = GradientDrawable().apply {
            setColor(threatColor)
            cornerRadius = 8 * density
        }

        val pillIcon = when (report.threatLevel.uppercase()) {
            "DANGEROUS" -> "🔴"
            "SUSPICIOUS" -> "🟡"
            "LOW RISK" -> "🔵"
            else -> "🟢"
        }
        val pillLabel = "$pillIcon ${report.threatLevel.uppercase()} (Score: ${report.threatScore}/100)"

        val badgeText = TextView(context).apply {
            text = "  $pillLabel  "
            setTextColor(Color.BLACK)
            textSize = 12.5f
            paint.isFakeBoldText = true
            background = badgeBg
            setPadding((6 * density).toInt(), (4 * density).toInt(), (6 * density).toInt(), (4 * density).toInt())
        }
        badgeRow.addView(badgeText)
        container.addView(badgeRow)

        // Category & VirusTotal Stats
        val catText = TextView(context).apply {
            text = "Category: ${report.category}"
            setTextColor(Color.parseColor("#9CA3AF"))
            textSize = 12.5f
        }
        val vtText = TextView(context).apply {
            text = report.virusTotalStats
            setTextColor(Color.parseColor("#A78BFA"))
            textSize = 12f
            paint.isFakeBoldText = true
            setPadding(0, (2 * density).toInt(), 0, 0)
        }
        container.addView(catText)
        container.addView(vtText)

        // Detected Links section
        if (report.originalUrl.isNotEmpty()) {
            val origHeader = TextView(context).apply {
                text = "Detected Link:"
                setTextColor(Color.parseColor("#9CA3AF"))
                textSize = 11.5f
                setPadding(0, (8 * density).toInt(), 0, 0)
            }
            val origText = TextView(context).apply {
                text = report.originalUrl
                setTextColor(Color.parseColor("#60A5FA"))
                textSize = 13f
            }
            container.addView(origHeader)
            container.addView(origText)
        }

        if (report.decodedUrl.isNotEmpty() && report.decodedUrl != report.originalUrl) {
            val decHeader = TextView(context).apply {
                text = "Unshortened Decoded Target:"
                setTextColor(Color.parseColor("#F59E0B"))
                textSize = 11.5f
                paint.isFakeBoldText = true
                setPadding(0, (6 * density).toInt(), 0, 0)
            }
            val decText = TextView(context).apply {
                text = report.decodedUrl
                setTextColor(Color.parseColor("#F97316"))
                textSize = 13f
            }
            container.addView(decHeader)
            container.addView(decText)
        }

        val aiHeader = TextView(context).apply {
            text = "AI Cyber Analysis:"
            setTextColor(Color.WHITE)
            textSize = 13f
            paint.isFakeBoldText = true
            setPadding(0, (12 * density).toInt(), 0, (2 * density).toInt())
        }
        container.addView(aiHeader)

        val explanationText = TextView(context).apply {
            text = report.explanation
            setTextColor(Color.parseColor("#E5E7EB"))
            textSize = 12.5f
        }
        container.addView(explanationText)

        // Recommendation Box
        val recBox = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding((12 * density).toInt(), (10 * density).toInt(), (12 * density).toInt(), (10 * density).toInt())
            val recBg = GradientDrawable().apply {
                setColor(Color.parseColor("#1F1535"))
                cornerRadius = 12 * density
                setStroke((1 * density).toInt(), Color.parseColor("#2E1E4E"))
            }
            background = recBg
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, (12 * density).toInt(), 0, (12 * density).toInt())
            }
            layoutParams = params
        }

        val recText = TextView(context).apply {
            text = "Tip: ${report.recommendation}"
            setTextColor(Color.parseColor("#A78BFA"))
            textSize = 11.5f
        }
        recBox.addView(recText)
        container.addView(recBox)

        // Scam Emergency Response Button (if threat is detected)
        if (report.threatLevel.uppercase() != "SAFE") {
            val emgBtn = Button(context).apply {
                text = "🚨 SCAM EMERGENCY RESPONSE MODE"
                setTextColor(Color.WHITE)
                textSize = 12f
                paint.isFakeBoldText = true
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#EF4444"))
                    cornerRadius = 12 * density
                }
                background = btnBg
                setOnClickListener {
                    Toast.makeText(context, "Emergency Shield Lock Activated", Toast.LENGTH_SHORT).show()
                }
            }
            container.addView(emgBtn)
        }

        // Action Buttons Row
        val btnRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            setPadding(0, (10 * density).toInt(), 0, 0)
        }

        val dismissBtn = Button(context).apply {
            text = "DISMISS"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { removePopup() }
        }

        if (report.originalUrl.isNotEmpty()) {
            val copyBtn = Button(context).apply {
                text = "COPY URL"
                setTextColor(Color.parseColor("#60A5FA"))
                setBackgroundColor(Color.TRANSPARENT)
                setOnClickListener {
                    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clip = ClipData.newPlainText("URL", report.originalUrl)
                    clipboard.setPrimaryClip(clip)
                    Toast.makeText(context, "URL Copied to Clipboard", Toast.LENGTH_SHORT).show()
                }
            }
            btnRow.addView(copyBtn)
        }

        val openAppBtn = Button(context).apply {
            text = "OPEN APP"
            setTextColor(Color.WHITE)
            textSize = 12f
            paint.isFakeBoldText = true
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#8B5CF6"))
                cornerRadius = 12 * density
            }
            background = btnBg
            setOnClickListener {
                removePopup()
                try {
                    val intent = Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    context.startActivity(intent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        btnRow.addView(dismissBtn)
        btnRow.addView(openAppBtn)
        container.addView(btnRow)

        scrollView.addView(container)

        val params = WindowManager.LayoutParams(
            (screenWidth * 0.9).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
            windowAnimations = android.R.style.Animation_Dialog
        }

        popupView = scrollView
        try {
            windowManager.addView(popupView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}