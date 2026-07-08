package com.sivaraj.securebubble_pro

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager

class BubbleManager(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var bubbleView: View? = null

    fun showBubble() {

        if (bubbleView != null) return

        bubbleView = LayoutInflater.from(context)
            .inflate(R.layout.bubble_layout, null)

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

        params.gravity = Gravity.TOP or Gravity.START

        params.x = 0
        params.y = 300

        windowManager.addView(
            bubbleView,
            params
        )
    }

    fun removeBubble() {

        bubbleView?.let {

            windowManager.removeView(it)

            bubbleView = null

        }

    }

}