package com.sivaraj.securebubble_pro

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "securebubble/service"
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

                    startService(intent)

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

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}