package com.sivaraj.securebubble_pro

import android.app.Notification
import android.app.Service
import android.content.Intent
import android.os.IBinder

class MediaProjectionService : Service() {

    private lateinit var notificationHelper: NotificationHelper

    override fun onCreate() {
        super.onCreate()

        notificationHelper = NotificationHelper(this)
        notificationHelper.createNotificationChannel()

        startForeground(
            NotificationHelper.NOTIFICATION_ID + 1,
            notificationHelper.createNotification()
        )
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        // அடுத்த Step-ல் Screen Capture logic சேர்ப்போம்

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}