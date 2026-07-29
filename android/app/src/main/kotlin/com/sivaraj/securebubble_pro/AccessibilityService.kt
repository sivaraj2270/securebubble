package com.sivaraj.securebubble_pro

import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AccessibilityService :
    android.accessibilityservice.AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {

        val text = event?.text?.joinToString(" ")

        if (!text.isNullOrEmpty()) {

            Log.d("SecureBubble", text)

        }

    }

    override fun onInterrupt() {
    }
}