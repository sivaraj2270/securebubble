package com.sivaraj.securebubble_pro

import android.app.Service
import android.content.Intent
import android.os.IBinder

class BubbleService : Service() {

    private lateinit var bubbleManager: BubbleManager

    override fun onCreate() {
        super.onCreate()

        bubbleManager = BubbleManager(this)
        bubbleManager.showBubble()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        bubbleManager.removeBubble()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}