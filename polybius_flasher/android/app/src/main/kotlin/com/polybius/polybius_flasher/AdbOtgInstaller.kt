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

    data class UsbInventoryItem(
        val deviceId: Int,
        val vendorId: Int,
        val productId: Int,
        val productName: String?,
        val manufacturerName: String?,
        val serial: String?,
        val hasAdbInterface: Boolean,
        val hasMtpOrStorage: Boolean,
        val hasPermission: Boolean,
        val hint: String,
    )

    data class InstallOptions(
        val forceDowngrade: Boolean = false,
        val forceUser0: Boolean = false,
    )

    data class InstallOutcome(
        val ok: Boolean,
        val message: String,
        val pmOutput: String = "",
        val errorCode: String = "",
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

    /** Full USB inventory including MTP-only gadgets (no ADB). */
    fun listUsbInventory(context: Context): List<UsbInventoryItem> {
        val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager
        return usb.deviceList.values.map { d ->
            val adb = findAdbInterface(d) != null
            val mtp = hasMtpOrMassStorage(d)
            val hint = when {
                adb -> "ADB ready — authorize USB debugging on the target if prompted"
                mtp -> "MTP/storage only — enable USB debugging (and set USB mode to File transfer / charging+ADB)"
                else -> "Unknown USB gadget — enable USB debugging on the target"
            }
            UsbInventoryItem(
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
                hasAdbInterface = adb,
                hasMtpOrStorage = mtp,
                hasPermission = usb.hasPermission(d),
                hint = hint,
            )
        }
    }

    fun hasMtpOrMassStorage(device: UsbDevice): Boolean {
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            // Still Image / MTP often appears as class 6 (Still Image) or vendor-specific
            // Mass storage = class 8
            if (intf.interfaceClass == 0x08) return true
            if (intf.interfaceClass == 0x06) return true
            // PTP/MTP subclass patterns
            if (intf.interfaceClass == 0xFF && intf.interfaceSubclass == 0xFF) {
                // ambiguous; ignore
            }
        }
        return false
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

    fun classifyPmError(output: String): String {
        val u = output.uppercase()
        return when {
            u.contains("INSUFFICIENT_STORAGE") || u.contains("INSTALL_FAILED_INSUFFICIENT_STORAGE") ->
                "INSUFFICIENT_STORAGE"
            u.contains("VERSION_DOWNGRADE") || u.contains("INSTALL_FAILED_VERSION_DOWNGRADE") ->
                "VERSION_DOWNGRADE"
            u.contains("INCOMPATIBLE") || u.contains("INSTALL_FAILED_NO_MATCHING_ABIS") ||
                u.contains("INSTALL_PARSE_FAILED") ->
                "INCOMPATIBLE"
            u.contains("UPDATE_INCOMPATIBLE") || u.contains("INSTALL_FAILED_UPDATE_INCOMPATIBLE") ->
                "UPDATE_INCOMPATIBLE"
            u.contains("PERMISSION_DENIED") || u.contains("INSTALL_FAILED_USER_RESTRICTED") ->
                "PERMISSION_DENIED"
            u.contains("ALREADY_EXISTS") -> "ALREADY_EXISTS"
            u.contains("CANCEL") -> "CANCELLED"
            u.contains("SUCCESS") -> "SUCCESS"
            else -> "UNKNOWN"
        }
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
        options: InstallOptions = InstallOptions(),
    ): InstallOutcome {
        // Always re-resolve the device from the live USB list — handles replug.
        val live = findDevice(context, device.deviceId)
            ?: throw IOException("USB device gone — unplugged or permission revoked. Reconnect OTG and re-scan.")
        val usb = context.getSystemService(Context.USB_SERVICE) as UsbManager
        if (!usb.hasPermission(live)) {
            throw IOException("USB permission not granted for ADB device — re-request permission")
        }
        val intf = findAdbInterface(live)
            ?: throw IOException(
                "No ADB interface on USB device. If you only see MTP/file-transfer, " +
                    "enable USB debugging and switch USB mode so ADB is exposed.",
            )

        val connection = usb.openDevice(live)
            ?: throw IOException("Failed to open USB device — replug OTG cable and retry")
        if (!connection.claimInterface(intf, true)) {
            connection.close()
            throw IOException("Failed to claim ADB interface")
        }

        val channel = UsbChannel(connection, intf)
        val crypto = loadOrCreateCrypto(context)
        val adb = AdbConnection.create(channel, crypto)
        activeConnection.set(adb)
        try {
            onProgress(0.02, "ADB handshake — authorize this key on the TARGET if prompted…")
            if (cancel.get()) throw IOException("Cancelled")
            adb.connect()
            val maxData = adb.maxDataSafe()
            onProgress(0.08, "ADB connected (maxData=$maxData)")
            return pushAndInstall(adb, apkFile, maxData, cancel, onProgress, options)
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
        options: InstallOptions = InstallOptions(),
    ): InstallOutcome {
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
            return pushAndInstall(adb, apkFile, maxData, cancel, onProgress, options)
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

    private fun buildPmCommand(remotePath: String, options: InstallOptions): String {
        val flags = StringBuilder("pm install -r")
        if (options.forceDowngrade) flags.append(" -d")
        if (options.forceUser0) flags.append(" --user 0")
        flags.append(" -t")
        flags.append(" \"").append(remotePath).append("\"")
        return flags.toString()
    }

    private fun pushAndInstall(
        adb: AdbConnection,
        apkFile: File,
        maxData: Int,
        cancel: AtomicBoolean,
        onProgress: (Double, String) -> Unit,
        options: InstallOptions,
    ): InstallOutcome {
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

        val primaryCmd = buildPmCommand(remotePath, options)
        onProgress(0.82, primaryCmd)
        val installOut = shellExec(adb, primaryCmd, cancel)
        Log.i(TAG, "pm install output: $installOut")

        val code = classifyPmError(installOut)
        if (code == "SUCCESS" || installOut.contains("Success", ignoreCase = true)) {
            onProgress(0.95, "Cleaning temp APK…")
            try {
                shellExec(adb, "rm -f \"$remotePath\"", cancel)
            } catch (_: Exception) {
            }
            onProgress(1.0, "Installed")
            return InstallOutcome(true, installOut.trim(), installOut, "SUCCESS")
        }

        // Fallback without assuming prior flags worked
        onProgress(0.88, "Retry pm install -r -t --user 0…")
        val retryCmd = "pm install -r -t --user 0 \"$remotePath\"" +
            if (options.forceDowngrade) " -d" else ""
        // note: flag order varies by Android; try a clean known-good form
        val retry = shellExec(
            adb,
            if (options.forceDowngrade) {
                "pm install -r -d -t --user 0 \"$remotePath\""
            } else {
                "pm install -r -t --user 0 \"$remotePath\""
            },
            cancel,
        )
        Log.i(TAG, "pm install retry: $retry")
        val retryCode = classifyPmError(retry)
        try {
            shellExec(adb, "rm -f \"$remotePath\"", cancel)
        } catch (_: Exception) {
        }
        if (retryCode == "SUCCESS" || retry.contains("Success", ignoreCase = true)) {
            onProgress(1.0, "Installed (retry)")
            return InstallOutcome(true, retry.trim(), "$installOut\n---\n$retry", "SUCCESS")
        }

        val combined = "$installOut\n---\n$retry"
        val err = classifyPmError(combined)
        return InstallOutcome(
            ok = false,
            message = "pm install failed [$err]:\n$combined",
            pmOutput = combined,
            errorCode = err,
        )
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
