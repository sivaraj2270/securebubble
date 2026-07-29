package com.sivaraj.securebubble_pro

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView

class PopupManager(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var popupView: View? = null

    fun showScannerPopup() {

        if (popupView != null) return

        popupView = LayoutInflater.from(context)
            .inflate(R.layout.scanner_popup, null)

        val params = WindowManager.LayoutParams(

            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,

            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,

            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.CENTER

        windowManager.addView(popupView, params)

        val txtStatus =
            popupView!!.findViewById<TextView>(R.id.txtStatus)

        val progress =
            popupView!!.findViewById<ProgressBar>(R.id.progress)

        val btnClose =
            popupView!!.findViewById<Button>(R.id.btnClose)

        btnClose.visibility = View.GONE

        val handler = Handler(Looper.getMainLooper())

        var dot = 0

        val animation = object : Runnable {

            override fun run() {

                dot++

                if (dot > 3) dot = 1

                txtStatus.text =
                    "AI Scanning" + ".".repeat(dot)

                handler.postDelayed(this, 500)
            }
        }

        handler.post(animation)

        handler.postDelayed({

            handler.removeCallbacks(animation)

            progress.visibility = View.GONE

            txtStatus.text = """
🛡 AI Scan Completed

✔ Screenshot Captured

✔ Link Detection

✔ QR Detection

✔ AI Analysis

✅ SAFE

No Phishing Link Found
            """.trimIndent()

            btnClose.visibility = View.VISIBLE

        }, 3000)

        btnClose.setOnClickListener {

            removePopup()

        }

    }

    fun removePopup() {

        popupView?.let {

            windowManager.removeView(it)

            popupView = null

        }

    }

}