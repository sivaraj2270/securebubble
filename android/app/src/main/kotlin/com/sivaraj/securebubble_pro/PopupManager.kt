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
        progressRunnable?.let { progressHandler?.removeCallbacks(it) }
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

    private var progressHandler: Handler? = null
    private var progressRunnable: Runnable? = null

    fun showScanningProgress() {
        removePopup()

        val density = context.resources.displayMetrics.density

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((32 * density).toInt(), (28 * density).toInt(), (32 * density).toInt(), (28 * density).toInt())
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#0F172A"))
            cornerRadius = 24 * density
            setStroke((1.5 * density).toInt(), Color.parseColor("#2563EB"))
        }
        container.background = cardBg

        val progressBar = ProgressBar(context).apply {
            indeterminateTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#38BDF8"))
        }

        val headerText = TextView(context).apply {
            text = "🛡 SecureBubble AI Threat Engine"
            setTextColor(Color.WHITE)
            textSize = 15f
            paint.isFakeBoldText = true
            setPadding(0, (14 * density).toInt(), 0, (4 * density).toInt())
        }

        val statusText = TextView(context).apply {
            text = "📸 Capturing screen pixels & UI text..."
            setTextColor(Color.parseColor("#38BDF8"))
            textSize = 13f
            paint.isFakeBoldText = true
            setPadding(0, 0, 0, (4 * density).toInt())
        }

        val timerText = TextView(context).apply {
            text = "Scanning in progress... (01s / 15s)"
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 11.5f
        }

        container.addView(progressBar)
        container.addView(headerText)
        container.addView(statusText)
        container.addView(timerText)

        val params = WindowManager.LayoutParams(
            (context.resources.displayMetrics.widthPixels * 0.85).toInt(),
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

        // Fast 5-7s Stage Progress & Timer Handler
        var elapsedSec = 1
        progressHandler = Handler(Looper.getMainLooper())
        progressRunnable = object : Runnable {
            override fun run() {
                elapsedSec++
                if (elapsedSec <= 6) {
                    timerText.text = "Scanning in progress... (${String.format("%02d", elapsedSec)}s / 06s)"
                    when (elapsedSec) {
                        2 -> statusText.text = "🔍 Extracting hyperlinks & decoding QR codes..."
                        4 -> statusText.text = "🌐 Querying Threat Engines & VirusTotal..."
                        5 -> statusText.text = "⚡ Evaluating Risk Score & safety report..."
                    }
                    progressHandler?.postDelayed(this, 1000)
                }
            }
        }
        progressHandler?.postDelayed(progressRunnable!!, 1000)
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

        val threatColor = when {
            report.threatScore >= 80 || report.threatLevel.uppercase() == "DANGEROUS" -> Color.parseColor("#EF4444")
            report.threatScore >= 50 || report.threatLevel.uppercase() == "SUSPICIOUS" -> Color.parseColor("#F59E0B")
            report.threatScore >= 20 || report.threatLevel.uppercase() == "LOW RISK" -> Color.parseColor("#60A5FA")
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

        val pillIcon = when {
            report.threatScore >= 80 -> "🔴"
            report.threatScore >= 50 -> "🟡"
            report.threatScore >= 20 -> "🔵"
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

        // BLOCK DOMAIN Option (shown for Risk Score >= 80 or any Threat)
        if (report.threatScore >= 80 || report.threatLevel.uppercase() != "SAFE") {
            val blockBtn = Button(context).apply {
                text = "🚫 BLOCK THIS DOMAIN PERMANENTLY"
                setTextColor(Color.WHITE)
                textSize = 12.5f
                paint.isFakeBoldText = true
                val btnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#EF4444"))
                    cornerRadius = 12 * density
                }
                background = btnBg
                setOnClickListener {
                    val targetUrl = if (report.originalUrl.isNotEmpty()) report.originalUrl else report.decodedUrl
                    val domain = BlockedDomainManager.normalizeDomain(targetUrl)
                    if (domain.isNotEmpty()) {
                        BlockedDomainManager.getInstance(context).addDomain(
                            domain,
                            "User Blocked via SecureBubble Overlay Report",
                            report.threatScore,
                            "USER_BLOCKED"
                        )
                        Toast.makeText(context, "🚫 Domain $domain added to Blocklist", Toast.LENGTH_LONG).show()
                    }
                    removePopup()
                }
            }
            container.addView(blockBtn)
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