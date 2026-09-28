package com.sivaraj.securebubble_pro

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_PRIMARY = "nukezero/service"
        const val CHANNEL_SECURITY = "securebubble/security"
        private const val REQUEST_CODE_VPN = 1009
    }

    private var pendingVpnResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val blocklistManager = BlockedDomainManager.getInstance(this)

        val channelHandler = MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {

                "startBubble" -> {
                    // Check if SYSTEM_ALERT_WINDOW permission is granted
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        Toast.makeText(this, "Please grant Overlay Permission for SecureBubble", Toast.LENGTH_LONG).show()
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(false)
                        return@MethodCallHandler
                    }

                    try {
                        val intent = Intent(this, BubbleService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Toast.makeText(this, "Error starting overlay service: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
                        result.success(false)
                    }
                }

                "stopBubble" -> {
                    try {
                        val intent = Intent(this, BubbleService::class.java)
                        stopService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.success(false)
                    }
                }

                "scanHyperlink", "startScreenScan" -> {
                    val service = SecureBubbleAccessibilityService.instance
                    if (service != null) {
                        val structuredJson = service.performFullStructuredScreenScan()
                        result.success(structuredJson)
                    } else {
                        val fallbackJson = """
                            {
                                "success": false,
                                "error": "Accessibility Service Disabled",
                                "items": []
                            }
                        """.trimIndent()
                        result.success(fallbackJson)
                    }
                }

                "requestVpnPermission" -> {
                    val prepareIntent = VpnService.prepare(this)
                    if (prepareIntent != null) {
                        pendingVpnResult = result
                        startActivityForResult(prepareIntent, REQUEST_CODE_VPN)
                    } else {
                        result.success(true)
                    }
                }

                "startVpn" -> {
                    val prepareIntent = VpnService.prepare(this)
                    if (prepareIntent != null) {
                        pendingVpnResult = result
                        startActivityForResult(prepareIntent, REQUEST_CODE_VPN)
                    } else {
                        val intent = Intent(this, SecureBubbleVpnService::class.java).apply {
                            action = SecureBubbleVpnService.ACTION_START_VPN
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                }

                "stopVpn" -> {
                    val intent = Intent(this, SecureBubbleVpnService::class.java).apply {
                        action = SecureBubbleVpnService.ACTION_STOP_VPN
                    }
                    startService(intent)
                    result.success(true)
                }

                "isVpnRunning" -> {
                    result.success(SecureBubbleVpnService.isRunning)
                }

                "addBlockedDomain" -> {
                    val domain = call.argument<String>("domain") ?: ""
                    val reason = call.argument<String>("reason") ?: "Possible Phishing"
                    val riskScore = call.argument<Int>("riskScore") ?: 94
                    val source = call.argument<String>("source") ?: "USER_BLOCKED"

                    val success = blocklistManager.addDomain(domain, reason, riskScore, source)
                    result.success(success)
                }

                "removeBlockedDomain" -> {
                    val domain = call.argument<String>("domain") ?: ""
                    val success = blocklistManager.removeDomain(domain)
                    result.success(success)
                }

                "isDomainBlocked" -> {
                    val domain = call.argument<String>("domain") ?: ""
                    val blocked = blocklistManager.isBlocked(domain)
                    result.success(blocked)
                }

                "getBlockedDomains" -> {
                    val list = blocklistManager.getBlockedDomainsList()
                    val array = JSONArray()
                    for (item in list) {
                        val obj = JSONObject()
                        obj.put("domain", item.domain)
                        obj.put("reason", item.reason)
                        obj.put("riskScore", item.riskScore)
                        obj.put("source", item.source)
                        obj.put("blockedAt", item.blockedAt)
                        array.put(obj)
                    }
                    result.success(array.toString())
                }

                "clearBlockedDomains" -> {
                    blocklistManager.clearBlockedDomains()
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PRIMARY).setMethodCallHandler(channelHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SECURITY).setMethodCallHandler(channelHandler)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_VPN) {
            if (resultCode == Activity.RESULT_OK) {
                val intent = Intent(this, SecureBubbleVpnService::class.java).apply {
                    action = SecureBubbleVpnService.ACTION_START_VPN
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                pendingVpnResult?.success(true)
            } else {
                pendingVpnResult?.success(false)
            }
            pendingVpnResult = null
        }
    }
}