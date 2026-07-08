package com.sivaraj.securebubble_pro

import android.app.Service
import android.content.Intent
import android.os.IBinder

class BubbleService : Service() {

    private lateinit var notificationHelper: NotificationHelper
    private lateinit var bubbleManager: BubbleManager

    override fun onCreate() {
        super.onCreate()

        notificationHelper = NotificationHelper(this)

        notificationHelper.createNotificationChannel()

        startForeground(
            NotificationHelper.NOTIFICATION_ID,
            notificationHelper.createNotification()
        )

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
        super.onDestroy()

        bubbleManager.removeBubble()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}