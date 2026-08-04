package com.sivaraj.securebubble_pro

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper

object ScreenCaptureManager {

    private var mediaProjection: MediaProjection? = null

    fun initMediaProjection(context: Context, resultCode: Int, data: Intent) {
        val projectionManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, data)
    }

    fun hasProjectionPermission(): Boolean = mediaProjection != null

    fun captureScreenBitmap(context: Context, onCaptured: (Bitmap?) -> Unit) {
        val proj = mediaProjection
        if (proj == null) {
            onCaptured(null)
            return
        }

        try {
            val metrics = context.resources.displayMetrics
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            val imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            var virtualDisplay: VirtualDisplay? = null

            val handler = Handler(Looper.getMainLooper())

            imageReader.setOnImageAvailableListener({ reader ->
                try {
                    val image = reader.acquireNextImage()
                    if (image != null) {
                        val planes = image.planes
                        val buffer = planes[0].buffer
                        val pixelStride = planes[0].pixelStride
                        val rowStride = planes[0].rowStride
                        val rowPadding = rowStride - pixelStride * width

                        val bitmap = Bitmap.createBitmap(width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888)
                        bitmap.copyPixelsFromBuffer(buffer)
                        image.close()
                        virtualDisplay?.release()
                        imageReader.close()

                        onCaptured(bitmap)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    virtualDisplay?.release()
                    imageReader.close()
                    onCaptured(null)
                }
            }, handler)

            virtualDisplay = proj.createVirtualDisplay(
                "SecureBubbleCapture",
                width,
                height,
                density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader.surface,
                null,
                handler
            )

            // Safety timeout in case frame is delayed
            handler.postDelayed({
                try {
                    virtualDisplay?.release()
                    imageReader.close()
                } catch (e: Exception) {
                    // Ignore release error on timeout
                }
            }, 1000)

        } catch (e: Exception) {
            e.printStackTrace()
            onCaptured(null)
        }
    }
}
