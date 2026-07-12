package com.sivaraj.securebubble_pro

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import kotlin.math.abs

class BubbleManager(private val context: Context) {

    private lateinit var popupManager: PopupManager

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private var bubbleView: View? = null
    private var params: WindowManager.LayoutParams? = null

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
            "Bubble Started",
            Toast.LENGTH_SHORT
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

                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {

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

                        val dx = abs(event.rawX - initialTouchX)
                        val dy = abs(event.rawY - initialTouchY)

                        // Click
                        if (dx < 15 && dy < 15) {

                            popupManager.showScannerPopup()

                        }

                        snapToEdge()

                        return true
                    }
                }

                return false
            }

        })

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