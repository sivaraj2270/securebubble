package com.sivaraj.securebubble_pro

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView

class PopupManager(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var popupView: View? = null

    fun showScanningProgress(onComplete: () -> Unit) {
        removePopup()

        val density = context.resources.displayMetrics.density

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((24 * density).toInt(), (20 * density).toInt(), (24 * density).toInt(), (20 * density).toInt())
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#121824"))
            cornerRadius = 16 * density
            setStroke((1.5 * density).toInt(), Color.parseColor("#00E676"))
        }
        container.background = cardBg

        val progressBar = ProgressBar(context).apply {
            indeterminateTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#00E676"))
        }

        val statusText = TextView(context).apply {
            text = "Decoding URL & Querying VirusTotal..."
            setTextColor(Color.WHITE)
            textSize = 14.5f
            paint.isFakeBoldText = true
            setPadding(0, (12 * density).toInt(), 0, 0)
        }

        container.addView(progressBar)
        container.addView(statusText)

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

        Handler(Looper.getMainLooper()).postDelayed({
            onComplete()
        }, 1200)
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
            "SAFE" -> Color.parseColor("#00E676")
            "LOW RISK" -> Color.parseColor("#00B0FF")
            "MEDIUM RISK" -> Color.parseColor("#FFD600")
            "HIGH RISK" -> Color.parseColor("#FF6D00")
            "DANGEROUS" -> Color.parseColor("#FF1744")
            else -> Color.parseColor("#00E676")
        }

        val cardBg = GradientDrawable().apply {
            setColor(Color.parseColor("#121824"))
            cornerRadius = 20 * density
            setStroke((1.5 * density).toInt(), threatColor)
        }
        container.background = cardBg

        // Header Title
        val titleView = TextView(context).apply {
            text = "SecureBubble AI Threat Report"
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
            cornerRadius = 6 * density
        }

        val badgeText = TextView(context).apply {
            text = "  ${report.threatLevel} (Score: ${report.threatScore}%)  "
            setTextColor(Color.BLACK)
            textSize = 12.5f
            paint.isFakeBoldText = true
            background = badgeBg
            setPadding((6 * density).toInt(), (3 * density).toInt(), (6 * density).toInt(), (3 * density).toInt())
        }
        badgeRow.addView(badgeText)
        container.addView(badgeRow)

        // Category & VirusTotal Stats
        val catText = TextView(context).apply {
            text = "Category: ${report.category}"
            setTextColor(Color.parseColor("#7A8B9E"))
            textSize = 12.5f
        }
        val vtText = TextView(context).apply {
            text = report.virusTotalStats
            setTextColor(Color.parseColor("#00E676"))
            textSize = 12f
            paint.isFakeBoldText = true
            setPadding(0, (2 * density).toInt(), 0, 0)
        }
        container.addView(catText)
        container.addView(vtText)

        // Detected Links section (Original vs Decoded)
        if (report.originalUrl.isNotEmpty()) {
            val origHeader = TextView(context).apply {
                text = "Original Link:"
                setTextColor(Color.parseColor("#7A8B9E"))
                textSize = 11.5f
                setPadding(0, (8 * density).toInt(), 0, 0)
            }
            val origText = TextView(context).apply {
                text = report.originalUrl
                setTextColor(Color.parseColor("#00B0FF"))
                textSize = 13f
            }
            container.addView(origHeader)
            container.addView(origText)
        }

        if (report.decodedUrl.isNotEmpty() && report.decodedUrl != report.originalUrl) {
            val decHeader = TextView(context).apply {
                text = "Unshortened Decoded Target:"
                setTextColor(Color.parseColor("#FFD600"))
                textSize = 11.5f
                paint.isFakeBoldText = true
                setPadding(0, (6 * density).toInt(), 0, 0)
            }
            val decText = TextView(context).apply {
                text = report.decodedUrl
                setTextColor(Color.parseColor("#FF6D00"))
                textSize = 13f
                paint.isFakeBoldText = true
            }
            container.addView(decHeader)
            container.addView(decText)
        }

        // Explanation
        val explHeader = TextView(context).apply {
            text = "AI Cyber Analysis:"
            setTextColor(Color.parseColor("#7A8B9E"))
            textSize = 11.5f
            setPadding(0, (10 * density).toInt(), 0, (2 * density).toInt())
        }
        val explText = TextView(context).apply {
            text = report.explanation
            setTextColor(Color.WHITE)
            textSize = 12.5f
            setPadding(0, 0, 0, (8 * density).toInt())
        }
        container.addView(explHeader)
        container.addView(explText)

        // Recommendation Box
        val recBox = TextView(context).apply {
            text = "Tip: ${report.recommendation}"
            setTextColor(Color.parseColor("#00E676"))
            textSize = 12f
            paint.isFakeBoldText = true
            val recBg = GradientDrawable().apply {
                setColor(Color.parseColor("#1C2638"))
                cornerRadius = 8 * density
            }
            background = recBg
            setPadding((10 * density).toInt(), (8 * density).toInt(), (10 * density).toInt(), (8 * density).toInt())
        }
        container.addView(recBox)

        // Buttons
        val buttonsRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            setPadding(0, (12 * density).toInt(), 0, 0)
        }

        val closeBtn = Button(context).apply {
            text = "Dismiss"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { removePopup() }
        }

        val openAppBtn = Button(context).apply {
            text = "Open App"
            setTextColor(Color.BLACK)
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#00E676"))
                cornerRadius = 10 * density
            }
            background = btnBg
            setOnClickListener {
                removePopup()
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                    context.startActivity(launchIntent)
                }
            }
        }

        buttonsRow.addView(closeBtn)
        buttonsRow.addView(openAppBtn)
        container.addView(buttonsRow)

        scrollView.addView(container)

        val params = WindowManager.LayoutParams(
            (screenWidth * 0.9).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
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

    fun removePopup() {
        popupView?.let {
            try {
                windowManager.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            popupView = null
        }
    }
}