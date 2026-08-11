package com.polybius.polybius_flasher

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.util.Base64
import android.util.Log
import com.cgutman.adblib.AdbBase64
import com.cgutman.adblib.AdbConnection
import com.cgutman.adblib.AdbCrypto
import com.cgutman.adblib.AdbStream
import com.cgutman.adblib.TcpChannel
import com.cgutman.adblib.UsbChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.charset.StandardCharsets
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Install an APK onto another Android device over USB OTG (ADB gadget)
 * or TCP ADB using AdbLib.
 *
 * Target phone must have USB debugging enabled and must authorize this
 * flasher's RSA key the first time.
 */
object AdbOtgInstaller {
    private const val TAG = "AdbOtgInstaller"
    private const val ADB_CLASS = 0xFF
    private const val ADB_SUBCLASS = 0x42
    private const val ADB_PROTOCOL = 0x01
    private const val KEY_DIR = "adbkeys"
    private const val REMOTE_DIR = "/data/local/tmp"

    /** Live connection so [cancelFlash] can tear down a hung AUTH wait. */
    val activeConnection = AtomicReference<AdbConnection?>(null)

    data class AdbUsbDeviceInfo(
        val deviceId: Int,
        val vendorId: Int,
        val productId: Int,
        val productName: String?,
        val manufacturerName: String?,
        val serial: String?,
        val hasAdbInterface: Boolean,
        val hasPermission: Boolean,
    )

    fun listAdbDevices(context: Context): List<AdbUsbDeviceInfo> {
        val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager
        return usb.deviceList.values.mapNotNull { d ->
            if (findAdbInterface(d) == null) return@mapNotNull null
            AdbUsbDeviceInfo(
                deviceId = d.deviceId,
                vendorId = d.vendorId,
                productId = d.productId,
                productName = d.productName,
                manufacturerName = d.manufacturerName,
                serial = try {
                    d.serialNumber
                } catch (_: SecurityException) {
                    null
                },
                hasAdbInterface = true,
                hasPermission = usb.hasPermission(d),
            )
        }
    }

    fun findDevice(context: Context, deviceId: Int): UsbDevice? {
        val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager
        return usb.deviceList.values.firstOrNull { it.deviceId == deviceId }
    }

    fun findAdbInterface(device: UsbDevice): android.hardware.usb.UsbInterface? {
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            if (intf.interfaceClass == ADB_CLASS &&
                intf.interfaceSubclass == ADB_SUBCLASS &&
                intf.interfaceProtocol == ADB_PROTOCOL
            ) {
                return intf
            }
        }
        return null
    }

    private fun adbBase64(): AdbBase64 = AdbBase64 { data ->
        Base64.encodeToString(data, Base64.NO_WRAP)
    }

    private fun loadOrCreateCrypto(context: Context): AdbCrypto {
        val dir = File(context.filesDir, KEY_DIR)
        if (!dir.exists()) dir.mkdirs()
        val priv = File(dir, "private.key")
        val pub = File(dir, "public.key")
        return if (priv.exists() && pub.exists()) {
            AdbCrypto.loadAdbKeyPair(adbBase64(), priv, pub)
        } else {
            val crypto = AdbCrypto.generateAdbKeyPair(adbBase64())
            crypto.saveAdbKeyPair(priv, pub)
            crypto
        }
    }

    fun installViaUsb(
        context: Context,
        device: UsbDevice,
        apkFile: File,
        cancel: AtomicBoolean,
        onProgress: (Double, String) -> Unit,
    ): String {
        val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager
        if (!usb.hasPermission(device)) {
            throw IOException("USB permission not granted for ADB device")
        }
        val intf = findAdbInterface(device)
            ?: throw IOException("No ADB interface on USB device (enable USB debugging on the target)")

        val connection = usb.openDevice(device)
            ?: throw IOException("Failed to open USB device")
        if (!connection.claimInterface(intf, true)) {
            connection.close()
            throw IOException("Failed to claim ADB interface")
        }

        val channel = UsbChannel(connection, intf)
        val crypto = loadOrCreateCrypto(context)
        val adb = AdbConnection.create(channel, crypto)
        activeConnection.set(adb)
        try {
            onProgress(0.02, "ADB handshake — authorize this key on the target if prompted…")
            if (cancel.get()) throw IOException("Cancelled")
            adb.connect()
            val maxData = adb.maxDataSafe()
            onProgress(0.08, "ADB connected (maxData=$maxData)")
            return pushAndInstall(adb, apkFile, maxData, cancel, onProgress)
        } finally {
            activeConnection.compareAndSet(adb, null)
            try {
                adb.close()
            } catch (_: Exception) {
            }
        }
    }

    fun installViaTcp(
        context: Context,
        host: String,
        port: Int,
        apkFile: File,
        cancel: AtomicBoolean,
        onProgress: (Double, String) -> Unit,
    ): String {
        onProgress(0.02, "Connecting TCP ADB $host:$port…")
        val socket = Socket()
        socket.tcpNoDelay = true
        socket.connect(InetSocketAddress(host, port), 10_000)
        val channel = TcpChannel(socket)
        val crypto = loadOrCreateCrypto(context)
        val adb = AdbConnection.create(channel, crypto)
        activeConnection.set(adb)
        try {
            if (cancel.get()) throw IOException("Cancelled")
            adb.connect()
            val maxData = adb.maxDataSafe()
            onProgress(0.08, "ADB connected (maxData=$maxData)")
            return pushAndInstall(adb, apkFile, maxData, cancel, onProgress)
        } finally {
            activeConnection.compareAndSet(adb, null)
            try {
                adb.close()
            } catch (_: Exception) {
            }
        }
    }

    fun cancelActive() {
        try {
            activeConnection.getAndSet(null)?.close()
        } catch (_: Exception) {
        }
    }

    private fun AdbConnection.maxDataSafe(): Int {
        return try {
            getMaxData().coerceAtLeast(1024)
        } catch (_: Exception) {
            4096
        }
    }

    private fun pushAndInstall(
        adb: AdbConnection,
        apkFile: File,
        maxData: Int,
        cancel: AtomicBoolean,
        onProgress: (Double, String) -> Unit,
    ): String {
        if (!apkFile.isFile || apkFile.length() <= 0L) {
            throw IOException("APK missing or empty: ${apkFile.absolutePath}")
        }
        val remoteName = "polybius_install_${System.currentTimeMillis()}.apk"
        val remotePath = "$REMOTE_DIR/$remoteName"
        val size = apkFile.length()

        onProgress(0.10, "Pushing ${apkFile.name} (${size} bytes) → $remotePath")
        syncPush(adb, apkFile, remotePath, size, maxData, cancel) { p, msg ->
            onProgress(0.10 + p * 0.70, msg)
        }

        if (cancel.get()) throw IOException("Cancelled")

        onProgress(0.82, "pm install -r …")
        val installOut = shellExec(adb, "pm install -r \"$remotePath\"", cancel)
        Log.i(TAG, "pm install output: $installOut")

        val ok = installOut.contains("Success", ignoreCase = true)
        if (!ok) {
            onProgress(0.88, "Retry pm install -r -t --user 0…")
            val retry = shellExec(adb, "pm install -r -t --user 0 \"$remotePath\"", cancel)
            Log.i(TAG, "pm install retry: $retry")
            if (!retry.contains("Success", ignoreCase = true)) {
                try {
                    shellExec(adb, "rm -f \"$remotePath\"", cancel)
                } catch (_: Exception) {
                }
                throw IOException("pm install failed:\n$installOut\n$retry")
            }
            onProgress(0.95, "Cleaning temp APK…")
            try {
                shellExec(adb, "rm -f \"$remotePath\"", cancel)
            } catch (_: Exception) {
            }
            onProgress(1.0, "Installed (retry)")
            return retry.trim()
        }

        onProgress(0.95, "Cleaning temp APK…")
        try {
            shellExec(adb, "rm -f \"$remotePath\"", cancel)
        } catch (_: Exception) {
        }
        onProgress(1.0, "Installed")
        return installOut.trim()
    }

    private fun syncPush(
        adb: AdbConnection,
        local: File,
        remotePath: String,
        size: Long,
        maxData: Int,
        cancel: AtomicBoolean,
        onProgress: (Double, String) -> Unit,
    ) {
        val stream = adb.open("sync:")
        try {
            val pathAndMode = "$remotePath,0644"
            val pathBytes = pathAndMode.toByteArray(StandardCharsets.UTF_8)
            writeChunked(stream, syncPacket("SEND", pathBytes.size) + pathBytes, maxData)

            // Leave room for the 8-byte DATA header in the same WRTE when possible.
            val dataMax = (maxData - 8).coerceIn(256, 256 * 1024)
            val buf = ByteArray(dataMax)
            var sent = 0L
            FileInputStream(local).use { input ->
                while (true) {
                    if (cancel.get()) throw IOException("Cancelled")
                    val n = input.read(buf)
                    if (n <= 0) break
                    val packet = ByteArray(8 + n)
                    System.arraycopy(syncPacket("DATA", n), 0, packet, 0, 8)
                    System.arraycopy(buf, 0, packet, 8, n)
                    writeChunked(stream, packet, maxData)
                    sent += n
                    val p = (sent.toDouble() / size.toDouble()).coerceIn(0.0, 1.0)
                    if (sent == n.toLong() || sent % (256 * 1024) < n || sent == size) {
                        onProgress(p, "Pushed $sent / $size")
                    }
                }
            }

            val mtime = (System.currentTimeMillis() / 1000L).toInt()
            writeChunked(stream, syncPacket("DONE", mtime), maxData)

            val reader = StreamReader(stream)
            val id = String(reader.readFully(4), StandardCharsets.UTF_8)
            val len = reader.readIntLe()
            if (id != "OKAY") {
                val err = if (len in 1..4096) {
                    String(reader.readFully(len), StandardCharsets.UTF_8)
                } else {
                    ""
                }
                throw IOException("ADB sync failed: $id $err")
            }
        } finally {
            try {
                stream.close()
            } catch (_: Exception) {
            }
        }
    }

    private fun writeChunked(stream: AdbStream, data: ByteArray, maxData: Int) {
        var offset = 0
        val cap = maxData.coerceAtLeast(1024)
        while (offset < data.size) {
            val n = minOf(cap, data.size - offset)
            if (offset == 0 && n == data.size) {
                stream.write(data)
            } else {
                stream.write(data.copyOfRange(offset, offset + n))
            }
            offset += n
        }
    }

    private fun syncPacket(id: String, arg: Int): ByteArray {
        val out = ByteArray(8)
        val idBytes = id.toByteArray(StandardCharsets.UTF_8)
        System.arraycopy(idBytes, 0, out, 0, 4)
        out[4] = (arg and 0xff).toByte()
        out[5] = ((arg shr 8) and 0xff).toByte()
        out[6] = ((arg shr 16) and 0xff).toByte()
        out[7] = ((arg shr 24) and 0xff).toByte()
        return out
    }

    private class StreamReader(private val stream: AdbStream) {
        private var buf = ByteArray(0)
        private var pos = 0

        fun readFully(n: Int): ByteArray {
            val out = ByteArray(n)
            var filled = 0
            while (filled < n) {
                if (pos >= buf.size) {
                    val next = try {
                        stream.read()
                    } catch (e: IOException) {
                        throw IOException("ADB stream closed while reading ($filled/$n)", e)
                    } ?: throw IOException("ADB stream EOF ($filled/$n)")
                    buf = next
                    pos = 0
                }
                val take = minOf(n - filled, buf.size - pos)
                System.arraycopy(buf, pos, out, filled, take)
                pos += take
                filled += take
            }
            return out
        }

        fun readIntLe(): Int {
            val b = readFully(4)
            return (b[0].toInt() and 0xff) or
                ((b[1].toInt() and 0xff) shl 8) or
                ((b[2].toInt() and 0xff) shl 16) or
                ((b[3].toInt() and 0xff) shl 24)
        }
    }

    private fun shellExec(adb: AdbConnection, command: String, cancel: AtomicBoolean): String {
        val stream = adb.open("shell:$command")
        try {
            val sb = StringBuilder()
            while (true) {
                if (cancel.get()) throw IOException("Cancelled")
                val chunk = try {
                    stream.read()
                } catch (_: IOException) {
                    break
                } ?: break
                sb.append(String(chunk, StandardCharsets.UTF_8))
            }
            return sb.toString()
        } finally {
            try {
                stream.close()
            } catch (_: Exception) {
            }
        }
    }
}
