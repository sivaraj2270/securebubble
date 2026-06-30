package com.sivaraj.securebubble_pro

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "securebubble/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // Native Test
                "showToast" -> {

                    Toast.makeText(
                        this,
                        "SecureBubble Native Connected ✅",
                        Toast.LENGTH_SHORT
                    ).show()

                    result.success(true)
                }

                // Overlay Permission
                "requestOverlayPermission" -> {

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

                        if (!Settings.canDrawOverlays(this)) {

                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )

                            startActivity(intent)

                        } else {

                            Toast.makeText(
                                this,
                                "Overlay Permission Already Granted",
                                Toast.LENGTH_SHORT
                            ).show()
                        }
                    }

                    result.success(true)
                }

                // Start Floating Bubble
                "startBubbleService" -> {

                    val intent = Intent(this, BubbleService::class.java)

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }

                    Toast.makeText(
                        this,
                        "Starting Bubble...",
                        Toast.LENGTH_SHORT
                    ).show()

                    result.success(true)
                }

                // Stop Bubble
                "stopBubbleService" -> {

                    val intent = Intent(this, BubbleService::class.java)
                    stopService(intent)

                    Toast.makeText(
                        this,
                        "Bubble Stopped",
                        Toast.LENGTH_SHORT
                    ).show()

                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}