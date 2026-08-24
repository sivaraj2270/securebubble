package com.sivaraj.securebubble_pro

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "nukezero_channel"
        const val CHANNEL_NAME = "NUKEZERO Shield Service"
        const val NOTIFICATION_ID = 1001
    }

    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "NUKEZERO Shield Floating Protection Service"
            }

            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    fun createNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }

        return builder
            .setContentTitle("NUKEZERO Shield")
            .setContentText("Autonomous Floating Protection Active")
            .setSmallIcon(R.drawable.ic_nukezero_shield)
            .setOngoing(true)
            .build()
    }
}