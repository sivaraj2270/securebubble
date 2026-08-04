package com.sivaraj.securebubble_pro

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

class MediaProjectionHelperActivity : Activity() {

    companion object {
        fun requestPermission(context: Context) {
            val intent = Intent(context, MediaProjectionHelperActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), 1001)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 1001 && resultCode == RESULT_OK && data != null) {
            try {
                ScreenCaptureManager.initMediaProjection(applicationContext, resultCode, data)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        finish()
    }
}
