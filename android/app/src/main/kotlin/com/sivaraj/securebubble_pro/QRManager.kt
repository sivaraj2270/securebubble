package com.sivaraj.securebubble_pro

import android.graphics.Bitmap
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.LuminanceSource
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader

class QRManager {

    fun scanQr(
        bitmap: Bitmap,
        onSuccess: (List<String>) -> Unit,
        onFailure: (Exception) -> Unit
    ) {
        val payloads = mutableListOf<String>()

        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(
                Barcode.FORMAT_QR_CODE,
                Barcode.FORMAT_DATA_MATRIX,
                Barcode.FORMAT_AZTEC,
                Barcode.FORMAT_ALL_FORMATS
            )
            .enableAllPotentialBarcodes()
            .build()

        val image = InputImage.fromBitmap(bitmap, 0)
        val scanner = BarcodeScanning.getClient(options)

        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                for (barcode in barcodes) {
                    val rawValue = barcode.rawValue
                    if (!rawValue.isNullOrEmpty() && !payloads.contains(rawValue)) {
                        payloads.add(rawValue)
                    }
                    if (barcode.valueType == Barcode.TYPE_URL && barcode.url != null) {
                        barcode.url?.url?.let { urlStr ->
                            if (!payloads.contains(urlStr)) {
                                payloads.add(urlStr)
                            }
                        }
                    }
                }

                // If ML Kit found barcodes, return them immediately
                if (payloads.isNotEmpty()) {
                    onSuccess(payloads)
                } else {
                    // Fallback to ZXing + Center Crop decoding for stylized / logo-centered QR codes
                    decodeWithZXing(bitmap, payloads)
                    onSuccess(payloads)
                }
            }
            .addOnFailureListener {
                decodeWithZXing(bitmap, payloads)
                onSuccess(payloads)
            }
    }

    private fun decodeWithZXing(bitmap: Bitmap, payloads: MutableList<String>) {
        try {
            val hints = mutableMapOf<DecodeHintType, Any>()
            hints[DecodeHintType.TRY_HARDER] = true
            hints[DecodeHintType.POSSIBLE_FORMATS] = listOf(com.google.zxing.BarcodeFormat.QR_CODE)

            // Try 1: Decode Full Bitmap via ZXing HybridBinarizer
            decodeBitmapZXing(bitmap, hints, payloads)

            // Try 2: Decode Center Region Crop (where QR codes with logos usually appear in chat apps)
            if (payloads.isEmpty() && bitmap.width > 200 && bitmap.height > 200) {
                val cropWidth = (bitmap.width * 0.7).toInt()
                val cropHeight = (bitmap.height * 0.7).toInt()
                val startX = (bitmap.width - cropWidth) / 2
                val startY = (bitmap.height - cropHeight) / 2

                val croppedBitmap = Bitmap.createBitmap(bitmap, startX, startY, cropWidth, cropHeight)
                decodeBitmapZXing(croppedBitmap, hints, payloads)
                croppedBitmap.recycle()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun decodeBitmapZXing(
        bitmap: Bitmap,
        hints: Map<DecodeHintType, Any>,
        payloads: MutableList<String>
    ) {
        try {
            val intArray = IntArray(bitmap.width * bitmap.height)
            bitmap.getPixels(intArray, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)

            val source: LuminanceSource = RGBLuminanceSource(bitmap.width, bitmap.height, intArray)
            val binaryBitmap = BinaryBitmap(HybridBinarizer(source))

            val reader = QRCodeReader()
            val result = reader.decode(binaryBitmap, hints)
            if (result != null && !result.text.isNullOrEmpty()) {
                if (!payloads.contains(result.text)) {
                    payloads.add(result.text)
                }
            }
        } catch (e: Exception) {
            // ZXing NotFoundException when no QR code found on this frame
        }
    }
}
