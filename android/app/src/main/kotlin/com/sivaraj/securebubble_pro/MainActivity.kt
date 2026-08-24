package com.sivaraj.securebubble_pro

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "nukezero/service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "startBubble" -> {
                    val intent = Intent(
                        this,
                        BubbleService::class.java
                    )

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }

                    result.success(true)
                }

                "stopBubble" -> {
                    val intent = Intent(
                        this,
                        BubbleService::class.java
                    )

                    stopService(intent)

                    result.success(true)
                }

                "scanHyperlink" -> {
                    val service = SecureBubbleAccessibilityService.instance
                    if (service != null) {
                        val hyperlinkJson = service.extractHyperlinkInfo()
                        result.success(hyperlinkJson)
                    } else {
                        val fallbackJson = """
                            {
                                "visibleText": "No visible text",
                                "actualUrl": "Not available",
                                "sourceApp": "Accessibility Service Disabled",
                                "domain": "Not available",
                                "finalUrl": "Not available",
                                "redirects": [],
                                "domainMatch": false,
                                "detectionType": "VISIBLE_URL_ONLY",
                                "riskLevel": "SUSPICIOUS",
                                "reason": "This application does not expose the hyperlink destination through its UI."
                            }
                        """.trimIndent()
                        result.success(fallbackJson)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}