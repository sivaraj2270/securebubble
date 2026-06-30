package com.sivaraj.securebubble_pro

import android.app.Service
import android.content.Intent
import android.os.IBinder

class BubbleService : Service() {

    private lateinit var notificationHelper: NotificationHelper

    override fun onCreate() {
        super.onCreate()

        notificationHelper = NotificationHelper(this)

        notificationHelper.createNotificationChannel()

        startForeground(
            NotificationHelper.NOTIFICATION_ID,
            notificationHelper.createNotification()
        )

        // Bubble உருவாக்கும் Code அடுத்த Step-ல் வரும்
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

        // Bubble Remove Code அடுத்த Step-ல் வரும்
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}