package com.sivaraj.securebubble_pro

import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer

class SecureBubbleVpnService : VpnService(), Runnable {

    companion object {
        const val TAG = "SecureBubbleVpn"
        const val ACTION_START_VPN = "com.sivaraj.securebubble_pro.START_VPN"
        const val ACTION_STOP_VPN = "com.sivaraj.securebubble_pro.STOP_VPN"

        @Volatile
        var isRunning = false
            private set
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnThread: Thread? = null
    private lateinit var blocklistManager: BlockedDomainManager

    override fun onCreate() {
        super.onCreate()
        blocklistManager = BlockedDomainManager.getInstance(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_STOP_VPN) {
            stopVpn()
            return START_NOT_STICKY
        }

        startForegroundVpnService()

        if (!isRunning) {
            isRunning = true
            vpnThread = Thread(this, "SecureBubbleVpnThread").apply { start() }
        }

        return START_STICKY
    }

    private fun startForegroundVpnService() {
        val notificationHelper = NotificationHelper(this)
        notificationHelper.createNotificationChannel()
        val notification = notificationHelper.createNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        1002,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                } else {
                    startForeground(
                        1002,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "startForeground with type failed: ${e.message}", e)
                try {
                    startForeground(1002, notification)
                } catch (ex: Exception) {
                    Log.e(TAG, "Fallback startForeground failed: ${ex.message}", ex)
                }
            }
        } else {
            startForeground(1002, notification)
        }
    }

    override fun run() {
        try {
            val builder = Builder()
            builder.setSession("NUKEZERO Shield Local Firewall")
                .addAddress("10.1.10.1", 24)
                .addDnsServer("10.1.10.1")
                .addRoute("10.1.10.1", 32)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false)
            }

            vpnInterface = builder.establish()
            if (vpnInterface == null) {
                Log.e(TAG, "VPN Interface establishment failed.")
                isRunning = false
                return
            }

            Log.i(TAG, "VPN Firewall Started successfully.")

            val tunnelInput = FileInputStream(vpnInterface!!.fileDescriptor)
            val tunnelOutput = FileOutputStream(vpnInterface!!.fileDescriptor)
            val packetBuffer = ByteBuffer.allocate(32767)

            val upstreamSocket = DatagramSocket()
            protect(upstreamSocket)
            upstreamSocket.soTimeout = 2500

            while (isRunning && !Thread.currentThread().isInterrupted) {
                packetBuffer.clear()
                val readLength = tunnelInput.read(packetBuffer.array())
                if (readLength > 0) {
                    packetBuffer.limit(readLength)
                    processPacket(packetBuffer, readLength, tunnelOutput, upstreamSocket)
                }
            }

            upstreamSocket.close()
        } catch (e: Exception) {
            Log.e(TAG, "VPN loop exception: ${e.message}", e)
        } finally {
            cleanupVpn()
        }
    }

    private fun processPacket(
        buffer: ByteBuffer,
        length: Int,
        output: FileOutputStream,
        upstreamSocket: DatagramSocket
    ) {
        try {
            // Check IP Version (must be IPv4 = 4)
            val versionAndIhl = buffer.get(0).toInt() and 0xFF
            val version = versionAndIhl shr 4
            if (version != 4) return

            val ihl = (versionAndIhl and 0x0F) * 4
            val protocol = buffer.get(9).toInt() and 0xFF

            // Process UDP packets (protocol = 17)
            if (protocol == 17) {
                val srcPort = ((buffer.get(ihl).toInt() and 0xFF) shl 8) or (buffer.get(ihl + 1).toInt() and 0xFF)
                val destPort = ((buffer.get(ihl + 2).toInt() and 0xFF) shl 8) or (buffer.get(ihl + 3).toInt() and 0xFF)

                // DNS Query on port 53
                if (destPort == 53) {
                    val udpPayloadOffset = ihl + 8
                    val domainName = parseDnsQueryDomain(buffer, udpPayloadOffset, length)

                    if (domainName.isNotEmpty()) {
                        Log.d(TAG, "DNS Query detected: $domainName")

                        if (blocklistManager.isBlocked(domainName)) {
                            Log.w(TAG, "🚫 SECUREBUBBLE FIREWALL BLOCKED DOMAIN: $domainName")
                            // Respond with NXDOMAIN / Blocked IP to prevent resolution
                            val blockedResponse = createBlockedDnsResponse(buffer, length, udpPayloadOffset)
                            if (blockedResponse != null) {
                                output.write(blockedResponse)
                            }
                            return
                        }
                    }

                    // Forward allowed DNS query upstream to 8.8.8.8
                    forwardDnsUpstream(buffer, length, udpPayloadOffset, srcPort, output, upstreamSocket)
                }
            }
        } catch (e: Exception) {
            // Ignore corrupted packets
        }
    }

    private fun parseDnsQueryDomain(buffer: ByteBuffer, dnsOffset: Int, totalLength: Int): String {
        try {
            var pos = dnsOffset + 12 // Skip DNS Header (12 bytes)
            if (pos >= totalLength) return ""

            val domainParts = mutableListOf<String>()
            while (pos < totalLength) {
                val len = buffer.get(pos).toInt() and 0xFF
                if (len == 0) break
                pos++
                if (pos + len > totalLength) break

                val partBytes = ByteArray(len)
                for (i in 0 until len) {
                    partBytes[i] = buffer.get(pos + i)
                }
                domainParts.add(String(partBytes, Charsets.US_ASCII))
                pos += len
            }
            return domainParts.joinToString(".")
        } catch (e: Exception) {
            return ""
        }
    }

    private fun forwardDnsUpstream(
        packet: ByteBuffer,
        length: Int,
        dnsOffset: Int,
        srcPort: Int,
        output: FileOutputStream,
        upstreamSocket: DatagramSocket
    ) {
        try {
            val dnsPayloadSize = length - dnsOffset
            val dnsPayload = ByteArray(dnsPayloadSize)
            packet.position(dnsOffset)
            packet.get(dnsPayload, 0, dnsPayloadSize)

            val upstreamAddr = InetAddress.getByName("8.8.8.8")
            val sendPacket = DatagramPacket(dnsPayload, dnsPayloadSize, upstreamAddr, 53)
            upstreamSocket.send(sendPacket)

            val recvBuffer = ByteArray(2048)
            val recvPacket = DatagramPacket(recvBuffer, recvBuffer.size)
            upstreamSocket.receive(recvPacket)

            // Write DNS response back
            val responseDnsData = recvPacket.data.copyOf(recvPacket.length)
            val ipUdpHeader = createUdpIpHeader(
                srcIp = byteArrayOf(10, 1, 10, 1),
                destIp = byteArrayOf(packet.get(12), packet.get(13), packet.get(14), packet.get(15)),
                srcPort = 53,
                destPort = srcPort,
                payloadLength = responseDnsData.size
            )

            val fullPacket = ByteArray(ipUdpHeader.size + responseDnsData.size)
            System.arraycopy(ipUdpHeader, 0, fullPacket, 0, ipUdpHeader.size)
            System.arraycopy(responseDnsData, 0, fullPacket, ipUdpHeader.size, responseDnsData.size)

            output.write(fullPacket)
        } catch (e: Exception) {
            // Forwarding timeout or network error
        }
    }

    private fun createBlockedDnsResponse(packet: ByteBuffer, length: Int, dnsOffset: Int): ByteArray? {
        try {
            val dnsPayloadSize = length - dnsOffset
            val dnsPayload = ByteArray(dnsPayloadSize)
            packet.position(dnsOffset)
            packet.get(dnsPayload, 0, dnsPayloadSize)

            // Set DNS Response Flag (0x8183 = Response, NXDOMAIN)
            if (dnsPayload.size >= 4) {
                dnsPayload[2] = 0x81.toByte()
                dnsPayload[3] = 0x83.toByte() // RCODE = 3 (NXDOMAIN)
            }

            val srcPort = ((packet.get(dnsOffset - 8).toInt() and 0xFF) shl 8) or (packet.get(dnsOffset - 7).toInt() and 0xFF)
            val destPort = ((packet.get(dnsOffset - 6).toInt() and 0xFF) shl 8) or (packet.get(dnsOffset - 5).toInt() and 0xFF)

            val ipUdpHeader = createUdpIpHeader(
                srcIp = byteArrayOf(10, 1, 10, 1),
                destIp = byteArrayOf(packet.get(12), packet.get(13), packet.get(14), packet.get(15)),
                srcPort = destPort,
                destPort = srcPort,
                payloadLength = dnsPayload.size
            )

            val fullPacket = ByteArray(ipUdpHeader.size + dnsPayload.size)
            System.arraycopy(ipUdpHeader, 0, fullPacket, 0, ipUdpHeader.size)
            System.arraycopy(dnsPayload, 0, fullPacket, ipUdpHeader.size, dnsPayload.size)
            return fullPacket
        } catch (e: Exception) {
            return null
        }
    }

    private fun createUdpIpHeader(srcIp: ByteArray, destIp: ByteArray, srcPort: Int, destPort: Int, payloadLength: Int): ByteArray {
        val header = ByteArray(28)
        val ipLength = 28 + payloadLength

        // IP Header
        header[0] = 0x45.toByte() // IPv4, IHL 5
        header[1] = 0x00.toByte()
        header[2] = ((ipLength shr 8) and 0xFF).toByte()
        header[3] = (ipLength and 0xFF).toByte()
        header[4] = 0x00.toByte()
        header[5] = 0x00.toByte()
        header[6] = 0x40.toByte() // Don't fragment
        header[7] = 0x00.toByte()
        header[8] = 64.toByte()   // TTL
        header[9] = 17.toByte()   // UDP Protocol

        System.arraycopy(srcIp, 0, header, 12, 4)
        System.arraycopy(destIp, 0, header, 16, 4)

        // UDP Header
        header[20] = ((srcPort shr 8) and 0xFF).toByte()
        header[21] = (srcPort and 0xFF).toByte()
        header[22] = ((destPort shr 8) and 0xFF).toByte()
        header[23] = (destPort and 0xFF).toByte()

        val udpLen = 8 + payloadLength
        header[24] = ((udpLen shr 8) and 0xFF).toByte()
        header[25] = (udpLen and 0xFF).toByte()
        header[26] = 0.toByte()
        header[27] = 0.toByte()

        return header
    }

    override fun onRevoke() {
        stopVpn()
        super.onRevoke()
    }

    fun stopVpn() {
        isRunning = false
        vpnThread?.interrupt()
        cleanupVpn()
        stopForeground(true)
        stopSelf()
    }

    private fun cleanupVpn() {
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        vpnInterface = null
        isRunning = false
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
