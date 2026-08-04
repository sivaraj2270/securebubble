package com.sivaraj.securebubble_pro

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

class BubbleService : Service() {

    private lateinit var bubbleManager: BubbleManager

    override fun onCreate() {
        super.onCreate()

        val notificationHelper = NotificationHelper(this)
        notificationHelper.createNotificationChannel()
        val notification = notificationHelper.createNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NotificationHelper.NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NotificationHelper.NOTIFICATION_ID, notification)
        }

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
        if (::bubbleManager.isInitialized) {
            bubbleManager.removeBubble()
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}