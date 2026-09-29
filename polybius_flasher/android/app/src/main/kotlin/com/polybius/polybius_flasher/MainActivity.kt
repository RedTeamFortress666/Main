package com.polybius.polybius_flasher

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "com.polybius.flasher/native"
    private val eventChannelName = "com.polybius.flasher/events"

    private val mainHandler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private val emitter = FlasherEmitter(mainHandler)

    private var pendingUsbResult: MethodChannel.Result? = null
    private var pendingTreeResult: MethodChannel.Result? = null
    private var pendingApkResult: MethodChannel.Result? = null
    private var pendingExtraFileResult: MethodChannel.Result? = null
    private var pendingCrypt3xResult: MethodChannel.Result? = null
    private var activeFlasher: EspFlasher? = null
    private val adbCancel = AtomicBoolean(false)
    private val r36Cancel = AtomicBoolean(false)

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
            }
            result?.success(uri.toString())
        }

    private val apkPicker =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val result = pendingApkResult
            pendingApkResult = null
            if (uri == null) {
                result?.success(null)
                return@registerForActivityResult
            }
            io.execute {
                try {
                    val name = uri.lastPathSegment?.substringAfterLast('/') ?: "picked.apk"
                    val safeName = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
                    val out = File(cacheDir, "picked_$safeName")
                    contentResolver.openInputStream(uri)?.use { input ->
                        out.outputStream().use { output -> input.copyTo(output) }
                    } ?: throw IOException("Cannot open picked APK")
                    mainHandler.post { result?.success(out.absolutePath) }
                } catch (e: Exception) {
                    mainHandler.post {
                        result?.error("pick_failed", e.message ?: e.toString(), null)
                    }
                }
            }
        }

    private val extraFilePicker =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val result = pendingExtraFileResult
            pendingExtraFileResult = null
            if (uri == null) {
                result?.success(null)
                return@registerForActivityResult
            }
            io.execute {
                try {
                    val name = uri.lastPathSegment?.substringAfterLast('/') ?: "extra.bin"
                    val safeName = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
                    val out = File(cacheDir, "extra_$safeName")
                    contentResolver.openInputStream(uri)?.use { input ->
                        out.outputStream().use { output -> input.copyTo(output) }
                    } ?: throw IOException("Cannot open picked file")
                    mainHandler.post { result?.success(out.absolutePath) }
                } catch (e: Exception) {
                    mainHandler.post {
                        result?.error("pick_failed", e.message ?: e.toString(), null)
                    }
                }
            }
        }

    private val crypt3xPicker =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val result = pendingCrypt3xResult
            pendingCrypt3xResult = null
            if (uri == null) {
                result?.success(null)
                return@registerForActivityResult
            }
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (_: SecurityException) {
            }
            val name = uri.lastPathSegment?.substringAfterLast('/') ?: "crypt3x.img"
            result?.success(
                mapOf(
                    "uri" to uri.toString(),
                    "name" to name,
                ),
            )
        }

    private val usbReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    ACTION_USB_PERMISSION -> {
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
                        emitter.log(
                            if (granted) "USB permission granted" else "USB permission denied",
                            stage = "usb_permission",
                            level = if (granted) "info" else "warn",
                        )
                        result?.success(
                            mapOf(
                                "granted" to granted,
                                "deviceId" to (device?.deviceId ?: -1),
                            ),
                        )
                    }
                    UsbManager.ACTION_USB_DEVICE_ATTACHED,
                    UsbManager.ACTION_USB_DEVICE_DETACHED,
                    -> {
                        emitter.log(
                            "USB topology changed (${intent.action})",
                            stage = "usb_hotplug",
                            level = "info",
                        )
                    }
                }
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        emitter.sink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        emitter.sink = null
                    }
                },
            )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "listUsbDevices" -> result.success(listUsbDevices())
                    "listAdbUsbDevices" -> result.success(listAdbUsbDevices())
                    "listUsbInventory" -> result.success(listUsbInventory())
                    "getBatteryStatus" -> result.success(batteryStatus())
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
                        val offset = call.argument<Int>("offset") ?: EspFlasher.DEFAULT_FULL_OFFSET
                        val baud = call.argument<Int>("baud") ?: 115200
                        val eraseAll = call.argument<Boolean>("eraseAll") ?: false
                        val skipAutoReset = call.argument<Boolean>("skipAutoReset") ?: false
                        val syncOnly = call.argument<Boolean>("syncOnly") ?: false
                        val hardResetAfter = call.argument<Boolean>("hardResetAfter") ?: true
                        val flashSizeHint = call.argument<Int>("flashSizeHint")
                        val serialMonitorMs = call.argument<Int>("serialMonitorMs") ?: 0
                        val target = call.argument<String>("target") ?: "esp"
                        if (deviceId == null) {
                            result.error("bad_args", "deviceId required", null)
                            return@setMethodCallHandler
                        }
                        if (!syncOnly && firmwarePath.isNullOrBlank()) {
                            result.error("bad_args", "firmwarePath required", null)
                            return@setMethodCallHandler
                        }
                        flashEsp(
                            deviceId = deviceId,
                            firmwarePath = firmwarePath,
                            chipName = chip,
                            offset = offset,
                            baud = baud,
                            eraseAll = eraseAll,
                            skipAutoReset = skipAutoReset,
                            syncOnly = syncOnly,
                            hardResetAfter = hardResetAfter,
                            flashSizeHint = flashSizeHint,
                            serialMonitorMs = serialMonitorMs,
                            target = target,
                            result = result,
                        )
                    }
                    "cancelFlash" -> {
                        activeFlasher?.cancel()
                        adbCancel.set(true)
                        r36Cancel.set(true)
                        AdbOtgInstaller.cancelActive()
                        emitter.log("Cancel requested", stage = "cancel", level = "warn")
                        result.success(true)
                    }
                    "pickSdTree" -> {
                        pendingTreeResult = result
                        treePicker.launch(null)
                    }
                    "pickApk" -> {
                        pendingApkResult = result
                        apkPicker.launch(
                            arrayOf(
                                "application/vnd.android.package-archive",
                                "application/octet-stream",
                                "*/*",
                            ),
                        )
                    }
                    "pickExtraFile" -> {
                        pendingExtraFileResult = result
                        extraFilePicker.launch(arrayOf("*/*"))
                    }
                    "pickCrypt3xImage" -> {
                        pendingCrypt3xResult = result
                        crypt3xPicker.launch(
                            arrayOf(
                                "application/octet-stream",
                                "application/zip",
                                "*/*",
                            ),
                        )
                    }
                    "detectR36Paths" -> {
                        val treeUri = call.argument<String>("treeUri")
                        if (treeUri.isNullOrBlank()) {
                            result.error("bad_args", "treeUri required", null)
                            return@setMethodCallHandler
                        }
                        io.execute {
                            val installer =
                                R36sInstaller(this, onLog = {}, onProgress = { _, _ -> })
                            val list =
                                installer.detectCandidates(Uri.parse(treeUri)).map { c ->
                                    mapOf(
                                        "label" to c.label,
                                        "hint" to c.relativeHint,
                                        "exists" to (c.document != null),
                                    )
                                }
                            mainHandler.post { result.success(list) }
                        }
                    }
                    "installR36s" -> {
                        val zipPath = call.argument<String>("zipPath")
                        val treeUri = call.argument<String>("treeUri")
                        val mode = call.argument<String>("mode") ?: "direct"
                        val preferredHint = call.argument<String>("preferredHint")
                        if (zipPath.isNullOrBlank() || treeUri.isNullOrBlank()) {
                            result.error("bad_args", "zipPath and treeUri required", null)
                            return@setMethodCallHandler
                        }
                        installR36s(zipPath, treeUri, mode, preferredHint, result)
                    }
                    "writeR36UsbStick" -> {
                        val zipPath = call.argument<String>("zipPath")
                        val treeUri = call.argument<String>("treeUri")
                        val extraFilePath = call.argument<String>("extraFilePath")
                        val includeZipCopy = call.argument<Boolean>("includeZipCopy") ?: true
                        if (zipPath.isNullOrBlank() || treeUri.isNullOrBlank()) {
                            result.error("bad_args", "zipPath and treeUri required", null)
                            return@setMethodCallHandler
                        }
                        writeR36UsbStick(zipPath, treeUri, extraFilePath, includeZipCopy, result)
                    }
                    "writeCrypt3xLite" -> {
                        val source = call.argument<String>("source")
                        val treeUri = call.argument<String>("treeUri")
                        val destFileName = call.argument<String>("destFileName")
                            ?: "lineage-18.1-20260815-1244-r36s-crypt3x-lite.img"
                        val expectedSha256 = call.argument<String>("expectedSha256")
                        val expectedBytes = (call.argument<Number>("expectedBytes")?.toLong()) ?: 0L
                        if (source.isNullOrBlank() || treeUri.isNullOrBlank()) {
                            result.error("bad_args", "source and treeUri required", null)
                            return@setMethodCallHandler
                        }
                        writeCrypt3xLite(
                            source = source,
                            treeUri = treeUri,
                            destFileName = destFileName,
                            expectedSha256 = expectedSha256,
                            expectedBytes = expectedBytes,
                            result = result,
                        )
                    }
                    "assembleCrypt3xEtcherKit" -> {
                        val partsTreeUri = call.argument<String>("partsTreeUri")
                        val destTreeUri = call.argument<String>("destTreeUri")
                        val kitFileName = call.argument<String>("kitFileName")
                            ?: "CRYPT3X_OS_LITE-r36s-20260815.zip"
                        val kitSha256 = call.argument<String>("kitSha256") ?: ""
                        val kitBytes = (call.argument<Number>("kitBytes")?.toLong()) ?: 0L
                        val officialZipFileName = call.argument<String>("officialZipFileName")
                            ?: "lineage-18.1-20260815-1244-r36s-crypt3x-lite.img.zip"
                        val officialZipSha256 = call.argument<String>("officialZipSha256") ?: ""
                        val officialZipBytes =
                            (call.argument<Number>("officialZipBytes")?.toLong()) ?: 0L
                        val etcherFolder = call.argument<String>("etcherFolder")
                            ?: "CRYPT3X_ETCHER"
                        val etcherText = call.argument<String>("etcherText") ?: ""
                        val rufusText = call.argument<String>("rufusText") ?: ""
                        val flashText = call.argument<String>("flashText") ?: ""
                        if (partsTreeUri.isNullOrBlank() || destTreeUri.isNullOrBlank()) {
                            result.error("bad_args", "partsTreeUri and destTreeUri required", null)
                            return@setMethodCallHandler
                        }
                        assembleCrypt3xEtcherKit(
                            partsTreeUri = partsTreeUri,
                            destTreeUri = destTreeUri,
                            kitFileName = kitFileName,
                            kitSha256 = kitSha256,
                            kitBytes = kitBytes,
                            officialZipFileName = officialZipFileName,
                            officialZipSha256 = officialZipSha256,
                            officialZipBytes = officialZipBytes,
                            etcherFolder = etcherFolder,
                            etcherText = etcherText,
                            rufusText = rufusText,
                            flashText = flashText,
                            result = result,
                        )
                    }
                    "probeUsbWrite" -> {
                        val treeUri = call.argument<String>("treeUri")
                        if (treeUri.isNullOrBlank()) {
                            result.error("bad_args", "treeUri required", null)
                            return@setMethodCallHandler
                        }
                        io.execute {
                            val installer =
                                R36sInstaller(
                                    this,
                                    onLog = {
                                        emitter.log(it, stage = "usb_probe", target = "r36s_usb")
                                    },
                                    onProgress = { _, _ -> },
                                )
                            val probe = installer.probeStickWrite(Uri.parse(treeUri))
                            mainHandler.post {
                                result.success(
                                    mapOf("ok" to probe.ok, "message" to probe.message),
                                )
                            }
                        }
                    }
                    "prepareSd" -> {
                        val treeUri = call.argument<String>("treeUri")
                        val layout = call.argument<String>("layout") ?: "r36s_ports"
                        val logicalFormat = call.argument<Boolean>("logicalFormat") ?: false
                        val wipePrevious = call.argument<Boolean>("wipePrevious") ?: true
                        if (treeUri.isNullOrBlank()) {
                            result.error("bad_args", "treeUri required", null)
                            return@setMethodCallHandler
                        }
                        prepareSd(treeUri, layout, logicalFormat, wipePrevious, result)
                    }
                    "openSystemSdFormat" -> {
                        val prep =
                            SdCardPreparer(this, onLog = { emitter.log(it, stage = "sd") }, onProgress = {})
                        val r = prep.openSystemFormatSettings()
                        result.success(mapOf("ok" to r.ok, "message" to r.message))
                    }
                    "listStorageVolumes" -> {
                        val prep = SdCardPreparer(this, onLog = {}, onProgress = {})
                        result.success(prep.describeVolumes())
                    }
                    "probeSdWrite" -> {
                        val treeUri = call.argument<String>("treeUri")
                        if (treeUri.isNullOrBlank()) {
                            result.error("bad_args", "treeUri required", null)
                            return@setMethodCallHandler
                        }
                        io.execute {
                            val prep =
                                SdCardPreparer(
                                    this,
                                    onLog = { emitter.log(it, stage = "sd_probe", target = "r36s") },
                                    onProgress = {},
                                )
                            val r =
                                prep.prepare(
                                    treeUri = Uri.parse(treeUri),
                                    layout = SdCardPreparer.Layout.R36S_PORTS,
                                    logicalFormat = false,
                                    wipePreviousPolybius = false,
                                )
                            mainHandler.post {
                                result.success(mapOf("ok" to r.ok, "message" to r.message))
                            }
                        }
                    }
                    "installApkAdbUsb" -> {
                        val deviceId = call.argument<Int>("deviceId")
                        val apkPath = call.argument<String>("apkPath")
                        val forceDowngrade = call.argument<Boolean>("forceDowngrade") ?: false
                        val forceUser0 = call.argument<Boolean>("forceUser0") ?: false
                        if (deviceId == null || apkPath.isNullOrBlank()) {
                            result.error("bad_args", "deviceId and apkPath required", null)
                            return@setMethodCallHandler
                        }
                        installApkAdbUsb(deviceId, apkPath, forceDowngrade, forceUser0, result)
                    }
                    "installApkAdbTcp" -> {
                        val host = call.argument<String>("host") ?: "127.0.0.1"
                        val port = call.argument<Int>("port") ?: 5555
                        val apkPath = call.argument<String>("apkPath")
                        val forceDowngrade = call.argument<Boolean>("forceDowngrade") ?: false
                        val forceUser0 = call.argument<Boolean>("forceUser0") ?: false
                        if (apkPath.isNullOrBlank()) {
                            result.error("bad_args", "apkPath required", null)
                            return@setMethodCallHandler
                        }
                        installApkAdbTcp(host, port, apkPath, forceDowngrade, forceUser0, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStart() {
        super.onStart()
        val filter =
            IntentFilter().apply {
                addAction(ACTION_USB_PERMISSION)
                addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            }
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

    private fun batteryStatus(): Map<String, Any?> {
        val bm = getSystemService(BATTERY_SERVICE) as BatteryManager
        val pct = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val charging =
            bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS).let { s ->
                s == BatteryManager.BATTERY_STATUS_CHARGING ||
                    s == BatteryManager.BATTERY_STATUS_FULL
            }
        val low = pct in 1..20
        return mapOf(
            "percent" to pct,
            "charging" to charging,
            "low" to low,
            "warning" to
                if (low && !charging) {
                    "Battery ~$pct%. OTG draws power — use a short data cable or a powered hub."
                } else {
                    "Use a short data-capable OTG cable. A powered hub helps if the board disconnects."
                },
        )
    }

    private fun listUsbDevices(): List<Map<String, Any?>> {
        val manager = getSystemService(USB_SERVICE) as UsbManager
        return manager.deviceList.values.map { d ->
            val jtag = d.vendorId == 0x303A &&
                (d.productId == 0x1001 || d.productId == 0x8140 || d.productId == 0x8141)
            mapOf(
                "deviceId" to d.deviceId,
                "vendorId" to d.vendorId,
                "productId" to d.productId,
                "deviceName" to d.deviceName,
                "productName" to (d.productName ?: ""),
                "manufacturerName" to (d.manufacturerName ?: ""),
                "hasPermission" to manager.hasPermission(d),
                "usbJtag" to jtag,
                "serial" to
                    try {
                        d.serialNumber ?: ""
                    } catch (_: SecurityException) {
                        ""
                    },
            )
        }
    }

    private fun listAdbUsbDevices(): List<Map<String, Any?>> {
        return AdbOtgInstaller.listAdbDevices(this).map { d ->
            mapOf(
                "deviceId" to d.deviceId,
                "vendorId" to d.vendorId,
                "productId" to d.productId,
                "productName" to (d.productName ?: ""),
                "manufacturerName" to (d.manufacturerName ?: ""),
                "serial" to (d.serial ?: ""),
                "hasAdbInterface" to d.hasAdbInterface,
                "hasPermission" to d.hasPermission,
            )
        }
    }

    private fun listUsbInventory(): List<Map<String, Any?>> {
        return AdbOtgInstaller.listUsbInventory(this).map { d ->
            mapOf(
                "deviceId" to d.deviceId,
                "vendorId" to d.vendorId,
                "productId" to d.productId,
                "productName" to (d.productName ?: ""),
                "manufacturerName" to (d.manufacturerName ?: ""),
                "serial" to (d.serial ?: ""),
                "hasAdbInterface" to d.hasAdbInterface,
                "hasMtpOrStorage" to d.hasMtpOrStorage,
                "hasPermission" to d.hasPermission,
                "hint" to d.hint,
            )
        }
    }

    private fun requestUsbPermission(deviceId: Int, result: MethodChannel.Result) {
        val manager = getSystemService(USB_SERVICE) as UsbManager
        val device = manager.deviceList.values.firstOrNull { it.deviceId == deviceId }
        if (device == null) {
            result.error("no_device", "USB device $deviceId not found — replug and re-scan", null)
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
        firmwarePath: String?,
        chipName: String,
        offset: Int,
        baud: Int,
        eraseAll: Boolean,
        skipAutoReset: Boolean,
        syncOnly: Boolean,
        hardResetAfter: Boolean,
        flashSizeHint: Int?,
        serialMonitorMs: Int,
        target: String,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = target
        io.execute {
            val manager = getSystemService(USB_SERVICE) as UsbManager
            // Re-resolve live device — never reuse a stale handle after replug.
            val device = manager.deviceList.values.firstOrNull { it.deviceId == deviceId }
            if (device == null) {
                mainHandler.post {
                    result.error("no_device", "USB device not found — replug OTG and re-scan", null)
                }
                return@execute
            }
            if (!manager.hasPermission(device)) {
                mainHandler.post {
                    result.error("no_permission", "USB permission denied — re-request permission", null)
                }
                return@execute
            }
            val connection = manager.openDevice(device)
            if (connection == null) {
                mainHandler.post { result.error("open_failed", "Could not open USB device", null) }
                return@execute
            }
            val file = if (syncOnly) null else File(firmwarePath!!)
            if (!syncOnly && (file == null || !file.isFile)) {
                connection.close()
                mainHandler.post { result.error("no_file", "Firmware not found: $firmwarePath", null) }
                return@execute
            }
            val chip =
                when (chipName.lowercase()) {
                    "esp32s3", "esp32-s3", "s3" -> EspFlasher.Chip.ESP32_S3
                    else -> EspFlasher.Chip.ESP32
                }
            emitter.emit(
                stage = if (syncOnly) "esp_sync" else "esp_flash",
                message = if (syncOnly) "Testing connection…" else "Flashing…",
                percent = 0.01,
                target = target,
            )
            val flasher =
                EspFlasher(
                    usbManager = manager,
                    onLog = { msg ->
                        emitter.log(msg, stage = if (syncOnly) "esp_sync" else "esp_flash", target = target)
                    },
                    onProgress = { written, total ->
                        val p = if (total > 0) written.toDouble() / total.toDouble() else 0.0
                        emitter.progress(p, "Wrote $written / $total", stage = "esp_flash")
                    },
                )
            activeFlasher = flasher
            val flashResult =
                try {
                    flasher.flash(
                        device,
                        connection,
                        file,
                        EspFlasher.Options(
                            chip = chip,
                            flashOffset = offset,
                            baud = baud,
                            eraseAll = eraseAll,
                            skipAutoReset = skipAutoReset,
                            syncOnly = syncOnly,
                            hardResetAfter = hardResetAfter,
                            flashSizeHint = flashSizeHint,
                            serialMonitorMs = serialMonitorMs,
                        ),
                    )
                } finally {
                    activeFlasher = null
                    try {
                        connection.close()
                    } catch (_: Exception) {
                    }
                }
            emitter.emit(
                stage = if (syncOnly) "esp_sync" else "esp_flash",
                message = flashResult.message,
                percent = if (flashResult.ok) 1.0 else null,
                level = if (flashResult.ok) "success" else "error",
                ok = flashResult.ok,
                target = target,
            )
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

    private fun installR36s(
        zipPath: String,
        treeUri: String,
        modeName: String,
        preferredHint: String?,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "r36s"
        r36Cancel.set(false)
        io.execute {
            val mode =
                when (modeName.lowercase()) {
                    "autoinstall", "auto" -> R36sInstaller.InstallMode.AUTOINSTALL
                    else -> R36sInstaller.InstallMode.DIRECT
                }
            val installer =
                R36sInstaller(
                    context = this,
                    onLog = { msg -> emitter.log(msg, stage = "r36s_install", target = "r36s") },
                    onProgress = { p, msg ->
                        emitter.progress(p, msg, stage = "r36s_install")
                    },
                    cancel = r36Cancel,
                )
            val installResult =
                try {
                    installer.install(
                        zipFile = File(zipPath),
                        treeUri = Uri.parse(treeUri),
                        mode = mode,
                        preferredHint = preferredHint,
                    )
                } catch (e: Exception) {
                    R36sInstaller.Result(false, e.message ?: e.toString())
                }
            emitter.emit(
                stage = "r36s_install",
                message = installResult.message,
                percent = if (installResult.ok) 1.0 else null,
                level = if (installResult.ok) "success" else "error",
                ok = installResult.ok,
                detail = installResult.detail,
                target = "r36s",
            )
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to installResult.ok,
                        "message" to installResult.message,
                        "portsPath" to installResult.portsPath,
                        "verified" to installResult.verified,
                        "detail" to installResult.detail,
                    ),
                )
            }
        }
    }

    private fun writeR36UsbStick(
        zipPath: String,
        treeUri: String,
        extraFilePath: String?,
        includeZipCopy: Boolean,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "r36s_usb"
        r36Cancel.set(false)
        io.execute {
            val extraFile =
                extraFilePath?.takeIf { it.isNotBlank() }?.let { path ->
                    val f = File(path)
                    if (f.exists() && f.isFile) f else null
                }
            val installer =
                R36sInstaller(
                    context = this,
                    onLog = { msg -> emitter.log(msg, stage = "r36s_usb", target = "r36s_usb") },
                    onProgress = { p, msg ->
                        emitter.progress(p, msg, stage = "r36s_usb")
                    },
                    cancel = r36Cancel,
                )
            val writeResult =
                try {
                    installer.writeUsbStick(
                        zipFile = File(zipPath),
                        treeUri = Uri.parse(treeUri),
                        extraFile = extraFile,
                        includeZipCopy = includeZipCopy,
                    )
                } catch (e: Exception) {
                    R36sInstaller.Result(false, e.message ?: e.toString())
                }
            emitter.emit(
                stage = "r36s_usb",
                message = writeResult.message,
                percent = if (writeResult.ok) 1.0 else null,
                level = if (writeResult.ok) "success" else "error",
                ok = writeResult.ok,
                detail = writeResult.detail,
                target = "r36s_usb",
            )
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to writeResult.ok,
                        "message" to writeResult.message,
                        "portsPath" to writeResult.portsPath,
                        "verified" to writeResult.verified,
                        "detail" to writeResult.detail,
                    ),
                )
            }
        }
    }

    private fun assembleCrypt3xEtcherKit(
        partsTreeUri: String,
        destTreeUri: String,
        kitFileName: String,
        kitSha256: String,
        kitBytes: Long,
        officialZipFileName: String,
        officialZipSha256: String,
        officialZipBytes: Long,
        etcherFolder: String,
        etcherText: String,
        rufusText: String,
        flashText: String,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "crypt3x_lite"
        r36Cancel.set(false)
        io.execute {
            val installer =
                R36sInstaller(
                    context = this,
                    onLog = { msg ->
                        emitter.log(msg, stage = "crypt3x_etcher", target = "crypt3x_lite")
                    },
                    onProgress = { p, msg ->
                        emitter.progress(p, msg, stage = "crypt3x_etcher")
                    },
                    cancel = r36Cancel,
                )
            val writeResult =
                try {
                    installer.assembleCrypt3xEtcherKit(
                        partsTreeUri = Uri.parse(partsTreeUri),
                        destTreeUri = Uri.parse(destTreeUri),
                        kitFileName = kitFileName,
                        kitSha256 = kitSha256,
                        kitBytes = kitBytes,
                        officialZipFileName = officialZipFileName,
                        officialZipSha256 = officialZipSha256,
                        officialZipBytes = officialZipBytes,
                        etcherFolder = etcherFolder,
                        etcherText = etcherText,
                        rufusText = rufusText,
                        flashText = flashText,
                    )
                } catch (e: Exception) {
                    R36sInstaller.Result(false, e.message ?: e.toString())
                }
            emitter.emit(
                stage = "crypt3x_etcher",
                message = writeResult.message,
                percent = if (writeResult.ok) 1.0 else null,
                level = if (writeResult.ok) "success" else "error",
                ok = writeResult.ok,
                detail = writeResult.detail,
                target = "crypt3x_lite",
            )
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to writeResult.ok,
                        "message" to writeResult.message,
                        "portsPath" to writeResult.portsPath,
                        "verified" to writeResult.verified,
                        "detail" to writeResult.detail,
                    ),
                )
            }
        }
    }

    private fun writeCrypt3xLite(
        source: String,
        treeUri: String,
        destFileName: String,
        expectedSha256: String?,
        expectedBytes: Long,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "crypt3x_lite"
        r36Cancel.set(false)
        io.execute {
            val installer =
                R36sInstaller(
                    context = this,
                    onLog = { msg ->
                        emitter.log(msg, stage = "crypt3x_lite", target = "crypt3x_lite")
                    },
                    onProgress = { p, msg ->
                        emitter.progress(p, msg, stage = "crypt3x_lite")
                    },
                    cancel = r36Cancel,
                )
            val writeResult =
                try {
                    installer.writeCrypt3xLite(
                        source = source,
                        treeUri = Uri.parse(treeUri),
                        destFileName = destFileName,
                        expectedSha256 = expectedSha256,
                        expectedBytes = expectedBytes,
                    )
                } catch (e: Exception) {
                    R36sInstaller.Result(false, e.message ?: e.toString())
                }
            emitter.emit(
                stage = "crypt3x_lite",
                message = writeResult.message,
                percent = if (writeResult.ok) 1.0 else null,
                level = if (writeResult.ok) "success" else "error",
                ok = writeResult.ok,
                detail = writeResult.detail,
                target = "crypt3x_lite",
            )
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to writeResult.ok,
                        "message" to writeResult.message,
                        "portsPath" to writeResult.portsPath,
                        "verified" to writeResult.verified,
                        "detail" to writeResult.detail,
                    ),
                )
            }
        }
    }

    private fun prepareSd(
        treeUri: String,
        layoutName: String,
        logicalFormat: Boolean,
        wipePrevious: Boolean,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "r36s"
        io.execute {
            val layout =
                when (layoutName.lowercase()) {
                    "esp_assets", "esp", "esp32" -> SdCardPreparer.Layout.ESP_ASSETS
                    else -> SdCardPreparer.Layout.R36S_PORTS
                }
            val preparer =
                SdCardPreparer(
                    context = this,
                    onLog = { msg -> emitter.log(msg, stage = "sd_prepare", target = "r36s") },
                    onProgress = { p ->
                        emitter.progress(p, "Preparing SD…", stage = "sd_prepare")
                    },
                )
            val prepResult =
                try {
                    preparer.prepare(
                        treeUri = Uri.parse(treeUri),
                        layout = layout,
                        logicalFormat = logicalFormat,
                        wipePreviousPolybius = wipePrevious,
                    )
                } catch (e: Exception) {
                    SdCardPreparer.Result(false, e.message ?: e.toString())
                }
            emitter.emit(
                stage = "sd_prepare",
                message = prepResult.message,
                percent = if (prepResult.ok) 1.0 else null,
                level = if (prepResult.ok) "success" else "error",
                ok = prepResult.ok,
                target = "r36s",
            )
            mainHandler.post {
                result.success(
                    mapOf(
                        "ok" to prepResult.ok,
                        "message" to prepResult.message,
                    ),
                )
            }
        }
    }

    private fun installApkAdbUsb(
        deviceId: Int,
        apkPath: String,
        forceDowngrade: Boolean,
        forceUser0: Boolean,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "androidOtg"
        io.execute {
            adbCancel.set(false)
            val device = AdbOtgInstaller.findDevice(this, deviceId)
            if (device == null) {
                mainHandler.post {
                    result.error("no_device", "ADB USB device not found — replug and re-scan", null)
                }
                return@execute
            }
            val manager = getSystemService(USB_SERVICE) as UsbManager
            if (!manager.hasPermission(device)) {
                mainHandler.post {
                    result.error("no_permission", "USB permission denied — re-request permission", null)
                }
                return@execute
            }
            val apk = File(apkPath)
            if (!apk.isFile) {
                mainHandler.post { result.error("no_file", "APK not found: $apkPath", null) }
                return@execute
            }
            try {
                val outcome =
                    AdbOtgInstaller.installViaUsb(
                        context = this,
                        device = device,
                        apkFile = apk,
                        cancel = adbCancel,
                        onProgress = { p, log ->
                            emitter.progress(p, log, stage = "adb_install")
                            emitter.log(log, stage = "adb_install", target = "androidOtg")
                        },
                        options =
                            AdbOtgInstaller.InstallOptions(
                                forceDowngrade = forceDowngrade,
                                forceUser0 = forceUser0,
                            ),
                    )
                emitter.emit(
                    stage = "adb_install",
                    message = outcome.message,
                    percent = if (outcome.ok) 1.0 else null,
                    level = if (outcome.ok) "success" else "error",
                    ok = outcome.ok,
                    detail = outcome.errorCode,
                    target = "androidOtg",
                )
                mainHandler.post {
                    result.success(
                        mapOf(
                            "ok" to outcome.ok,
                            "message" to outcome.message,
                            "pmOutput" to outcome.pmOutput,
                            "errorCode" to outcome.errorCode,
                        ),
                    )
                }
            } catch (e: Exception) {
                emitter.emit(
                    stage = "adb_install",
                    message = e.message ?: e.toString(),
                    level = "error",
                    ok = false,
                    target = "androidOtg",
                )
                mainHandler.post {
                    result.success(
                        mapOf(
                            "ok" to false,
                            "message" to (e.message ?: e.toString()),
                            "errorCode" to "EXCEPTION",
                        ),
                    )
                }
            }
        }
    }

    private fun installApkAdbTcp(
        host: String,
        port: Int,
        apkPath: String,
        forceDowngrade: Boolean,
        forceUser0: Boolean,
        result: MethodChannel.Result,
    ) {
        emitter.currentTarget = "androidOtg"
        io.execute {
            adbCancel.set(false)
            val apk = File(apkPath)
            if (!apk.isFile) {
                mainHandler.post { result.error("no_file", "APK not found: $apkPath", null) }
                return@execute
            }
            try {
                val outcome =
                    AdbOtgInstaller.installViaTcp(
                        context = this,
                        host = host,
                        port = port,
                        apkFile = apk,
                        cancel = adbCancel,
                        onProgress = { p, log ->
                            emitter.progress(p, log, stage = "adb_install")
                            emitter.log(log, stage = "adb_install", target = "androidOtg")
                        },
                        options =
                            AdbOtgInstaller.InstallOptions(
                                forceDowngrade = forceDowngrade,
                                forceUser0 = forceUser0,
                            ),
                    )
                emitter.emit(
                    stage = "adb_install",
                    message = outcome.message,
                    percent = if (outcome.ok) 1.0 else null,
                    level = if (outcome.ok) "success" else "error",
                    ok = outcome.ok,
                    detail = outcome.errorCode,
                    target = "androidOtg",
                )
                mainHandler.post {
                    result.success(
                        mapOf(
                            "ok" to outcome.ok,
                            "message" to outcome.message,
                            "pmOutput" to outcome.pmOutput,
                            "errorCode" to outcome.errorCode,
                        ),
                    )
                }
            } catch (e: Exception) {
                emitter.emit(
                    stage = "adb_install",
                    message = e.message ?: e.toString(),
                    level = "error",
                    ok = false,
                    target = "androidOtg",
                )
                mainHandler.post {
                    result.success(
                        mapOf(
                            "ok" to false,
                            "message" to (e.message ?: e.toString()),
                            "errorCode" to "EXCEPTION",
                        ),
                    )
                }
            }
        }
    }

    companion object {
        private const val ACTION_USB_PERMISSION = "com.polybius.flasher.USB_PERMISSION"
    }
}
