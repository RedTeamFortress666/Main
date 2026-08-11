package com.polybius.polybius_flasher

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "com.polybius.flasher/native"
    private val eventChannelName = "com.polybius.flasher/events"

    private val mainHandler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()

    private var eventSink: EventChannel.EventSink? = null
    private var pendingUsbResult: MethodChannel.Result? = null
    private var pendingTreeResult: MethodChannel.Result? = null
    private var activeFlasher: EspFlasher? = null

    private val treePicker =
        registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
            val result = pendingTreeResult
            pendingTreeResult = null
            if (uri == null) {
                result?.success(null)
                return@registerForActivityResult
            }
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                )
            } catch (_: SecurityException) {
                // Some providers don't allow persistable grants; continue anyway.
            }
            result?.success(uri.toString())
        }

    private val usbReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != ACTION_USB_PERMISSION) return
                val device =
                    if (Build.VERSION.SDK_INT >= 33) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                val result = pendingUsbResult
                pendingUsbResult = null
                result?.success(
                    mapOf(
                        "granted" to granted,
                        "deviceId" to (device?.deviceId ?: -1),
                    ),
                )
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listUsbDevices" -> {
                        result.success(listUsbDevices())
                    }
                    "requestUsbPermission" -> {
                        val deviceId = call.argument<Int>("deviceId")
                        if (deviceId == null) {
                            result.error("bad_args", "deviceId required", null)
                            return@setMethodCallHandler
                        }
                        requestUsbPermission(deviceId, result)
                    }
                    "flashEsp" -> {
                        val deviceId = call.argument<Int>("deviceId")
                        val firmwarePath = call.argument<String>("firmwarePath")
                        val chip = call.argument<String>("chip") ?: "esp32"
                        val offset = call.argument<Int>("offset") ?: EspFlasher.DEFAULT_APP_OFFSET
                        val baud = call.argument<Int>("baud") ?: 460800
                        if (deviceId == null || firmwarePath.isNullOrBlank()) {
                            result.error("bad_args", "deviceId and firmwarePath required", null)
                            return@setMethodCallHandler
                        }
                        flashEsp(deviceId, firmwarePath, chip, offset, baud, result)
                    }
                    "cancelFlash" -> {
                        activeFlasher?.cancel()
                        result.success(true)
                    }
                    "pickSdTree" -> {
                        pendingTreeResult = result
                        treePicker.launch(null)
                    }
                    "installR36s" -> {
                        val zipPath = call.argument<String>("zipPath")
                        val treeUri = call.argument<String>("treeUri")
                        if (zipPath.isNullOrBlank() || treeUri.isNullOrBlank()) {
                            result.error("bad_args", "zipPath and treeUri required", null)
                            return@setMethodCallHandler
                        }
                        installR36s(zipPath, treeUri, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStart() {
        super.onStart()
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(usbReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(usbReceiver, filter)
        }
    }

    override fun onStop() {
        try {
            unregisterReceiver(usbReceiver)
        } catch (_: Exception) {
        }
        super.onStop()
    }

    private fun listUsbDevices(): List<Map<String, Any?>> {
        val manager = getSystemService(USB_SERVICE) as UsbManager
        return manager.deviceList.values.map { d ->
            mapOf(
                "deviceId" to d.deviceId,
                "vendorId" to d.vendorId,
                "productId" to d.productId,
                "deviceName" to d.deviceName,
                "productName" to (d.productName ?: ""),
                "manufacturerName" to (d.manufacturerName ?: ""),
                "hasPermission" to manager.hasPermission(d),
            )
        }
    }

    private fun requestUsbPermission(deviceId: Int, result: MethodChannel.Result) {
        val manager = getSystemService(USB_SERVICE) as UsbManager
        val device = manager.deviceList.values.firstOrNull { it.deviceId == deviceId }
        if (device == null) {
            result.error("no_device", "USB device $deviceId not found", null)
            return
        }
        if (manager.hasPermission(device)) {
            result.success(mapOf("granted" to true, "deviceId" to deviceId))
            return
        }
        pendingUsbResult = result
        val flags =
            if (Build.VERSION.SDK_INT >= 23) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        val pi =
            PendingIntent.getBroadcast(
                this,
                0,
                Intent(ACTION_USB_PERMISSION).setPackage(packageName),
                flags,
            )
        manager.requestPermission(device, pi)
    }

    private fun flashEsp(
        deviceId: Int,
        firmwarePath: String,
        chipName: String,
        offset: Int,
        baud: Int,
        result: MethodChannel.Result,
    ) {
        io.execute {
            val manager = getSystemService(USB_SERVICE) as UsbManager
            val device = manager.deviceList.values.firstOrNull { it.deviceId == deviceId }
            if (device == null) {
                mainHandler.post { result.error("no_device", "USB device not found", null) }
                return@execute
            }
            if (!manager.hasPermission(device)) {
                mainHandler.post { result.error("no_permission", "USB permission denied", null) }
                return@execute
            }
            val connection = manager.openDevice(device)
            if (connection == null) {
                mainHandler.post { result.error("open_failed", "Could not open USB device", null) }
                return@execute
            }
            val file = File(firmwarePath)
            if (!file.isFile) {
                connection.close()
                mainHandler.post { result.error("no_file", "Firmware not found: $firmwarePath", null) }
                return@execute
            }
            val chip =
                when (chipName.lowercase()) {
                    "esp32s3", "esp32-s3", "s3" -> EspFlasher.Chip.ESP32_S3
                    else -> EspFlasher.Chip.ESP32
                }
            val flasher =
                EspFlasher(
                    usbManager = manager,
                    onLog = { msg -> emit("log", msg) },
                    onProgress = { p -> emit("progress", p) },
                )
            activeFlasher = flasher
            val flashResult =
                try {
                    flasher.flash(device, connection, file, chip, offset, baud)
                } finally {
                    activeFlasher = null
                    try {
                        connection.close()
                    } catch (_: Exception) {
                    }
                }
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to flashResult.ok,
                        "message" to flashResult.message,
                    ),
                )
            }
        }
    }

    private fun installR36s(zipPath: String, treeUri: String, result: MethodChannel.Result) {
        io.execute {
            val installer =
                R36sInstaller(
                    context = this,
                    onLog = { msg -> emit("log", msg) },
                    onProgress = { p -> emit("progress", p) },
                )
            val installResult =
                try {
                    installer.install(File(zipPath), Uri.parse(treeUri))
                } catch (e: Exception) {
                    R36sInstaller.Result(false, e.message ?: e.toString())
                }
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to installResult.ok,
                        "message" to installResult.message,
                    ),
                )
            }
        }
    }

    private fun emit(type: String, value: Any?) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to type, "value" to value))
        }
    }

    companion object {
        private const val ACTION_USB_PERMISSION = "com.polybius.flasher.USB_PERMISSION"
    }
}
