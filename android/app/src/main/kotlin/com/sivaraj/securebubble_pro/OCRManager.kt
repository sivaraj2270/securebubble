package com.sivaraj.securebubble_pro

import android.graphics.Bitmap
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Canvas
import android.graphics.Paint
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class OCRManager {

    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    fun readText(
        bitmap: Bitmap,
        onSuccess: (String) -> Unit,
        onFailure: (Exception) -> Unit
    ) {
        val imageOriginal = InputImage.fromBitmap(bitmap, 0)

        recognizer.process(imageOriginal)
            .addOnSuccessListener { visionText ->
                val primaryText = visionText.text
                if (primaryText.isNotBlank()) {
                    onSuccess(primaryText)
                } else {
                    // Try high-contrast grayscale bitmap for dark mode app screens
                    try {
                        val enhancedBitmap = createHighContrastBitmap(bitmap)
                        val imageEnhanced = InputImage.fromBitmap(enhancedBitmap, 0)
                        recognizer.process(imageEnhanced)
                            .addOnSuccessListener { text2 ->
                                onSuccess(text2.text)
                                enhancedBitmap.recycle()
                            }
                            .addOnFailureListener { e ->
                                onFailure(e)
                                enhancedBitmap.recycle()
                            }
                    } catch (e: Exception) {
                        onSuccess(primaryText)
                    }
                }
            }
            .addOnFailureListener { e ->
                onFailure(e)
            }
    }

    private fun createHighContrastBitmap(src: Bitmap): Bitmap {
        val width = src.width
        val height = src.height
        val dest = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

        val canvas = Canvas(dest)
        val paint = Paint()

        val cm = ColorMatrix()
        cm.setSaturation(0f)

        // Increase contrast
        val scale = 1.6f
        val translate = (-0.5f * scale + 0.5f) * 255f
        val contrastMatrix = floatArrayOf(
            scale, 0f, 0f, 0f, translate,
            0f, scale, 0f, 0f, translate,
            0f, 0f, scale, 0f, translate,
            0f, 0f, 0f, 1f, 0f
        )
        cm.postConcat(ColorMatrix(contrastMatrix))

        paint.colorFilter = ColorMatrixColorFilter(cm)
        canvas.drawBitmap(src, 0f, 0f, paint)

        return dest
    }
}