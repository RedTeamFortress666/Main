package com.polybius.polybius_flasher

import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import java.io.File
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min

/**
 * Minimal ESP ROM bootloader flasher.
 *
 * Download-mode entry is unreliable on Android USB-OTG (especially ESP32-S3
 * USB-JTAG on T-Deck). We try several reset strategies, then fall back to
 * manual BOOT instructions from the Flutter UI.
 */
class EspFlasher(
    private val usbManager: UsbManager,
    private val onLog: (String) -> Unit,
    private val onProgress: (written: Long, total: Long) -> Unit,
) {
    enum class Chip(val label: String, val defaultFlashBytes: Int) {
        ESP32("esp32", 4 * 1024 * 1024),
        ESP32_S3("esp32s3", 16 * 1024 * 1024),
    }

    enum class ResetStrategy {
        /** Classic USB-UART auto-reset: RTS=EN, DTR=IO0. */
        CLASSIC_DTR_RTS,

        /** Inverted line polarity used by some CDC bridges. */
        INVERTED_DTR_RTS,

        /**
         * 1200-baud "touch" then reopen at 115200 — common for ESP32-S3
         * USB-Serial/JTAG native USB when DTR/RTS do nothing.
         */
        BAUD_1200_TOUCH,

        /** Assume the user already held BOOT / RST manually. */
        NONE,
    }

    data class Options(
        val chip: Chip = Chip.ESP32,
        val flashOffset: Int = DEFAULT_FULL_OFFSET,
        val baud: Int = 115200,
        val eraseAll: Boolean = false,
        val skipAutoReset: Boolean = false,
        val syncOnly: Boolean = false,
        val hardResetAfter: Boolean = true,
        val flashSizeHint: Int? = null,
    )

    data class Result(val ok: Boolean, val message: String)

    private val cancelled = AtomicBoolean(false)

    fun cancel() {
        cancelled.set(true)
    }

    fun flash(
        device: UsbDevice,
        connection: UsbDeviceConnection,
        firmware: File?,
        options: Options,
    ): Result {
        cancelled.set(false)
        logUsb(device)

        val drivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        val driver = drivers.firstOrNull {
            it.device.deviceId == device.deviceId && it.device.vendorId == device.vendorId
        } ?: return Result(false, "No USB serial driver for ${device.deviceName}")

        val port = driver.ports.firstOrNull()
            ?: return Result(false, "USB device has no serial ports")

        var opened = false
        return try {
            port.open(connection)
            opened = true
            port.setParameters(115200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)

            val session = Session(port, onLog, cancelled)
            val strategies = if (options.skipAutoReset) {
                listOf(ResetStrategy.NONE)
            } else {
                listOf(
                    ResetStrategy.CLASSIC_DTR_RTS,
                    ResetStrategy.INVERTED_DTR_RTS,
                    ResetStrategy.BAUD_1200_TOUCH,
                    ResetStrategy.NONE,
                )
            }

            onLog("Entering download mode (${strategies.size} strategies)…")
            session.syncWithStrategies(strategies, options.chip)

            onLog("Attaching SPI flash (${options.chip.label})…")
            session.spiAttach(options.chip)

            if (options.baud != 115200) {
                onLog("Raising baud to ${options.baud}…")
                try {
                    session.changeBaud(options.baud)
                } catch (e: Exception) {
                    onLog("Baud change failed (${e.message}) — staying at 115200")
                    port.setParameters(115200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
                }
            }

            if (options.syncOnly) {
                onLog("Test connection OK — ROM sync + SPI attach succeeded.")
                return Result(true, "Connection OK — ${options.chip.label} ROM responding")
            }

            val file = firmware ?: return Result(false, "Firmware file missing")
            val image = file.readBytes()
            if (image.isEmpty()) return Result(false, "Firmware file is empty")

            if (options.eraseAll) {
                val eraseBytes = options.flashSizeHint ?: options.chip.defaultFlashBytes
                onLog("Erasing flash (${eraseBytes / (1024 * 1024)} MiB)…")
                session.eraseRegion(0, eraseBytes)
            }

            onLog(
                "Writing ${image.size} bytes at 0x${options.flashOffset.toString(16)}…",
            )
            session.flashImage(image, options.flashOffset) { written, total ->
                onProgress(written, total)
                if (cancelled.get()) throw IOException("Cancelled")
            }

            onLog("Finishing…")
            session.flashEnd(reboot = options.hardResetAfter)
            onProgress(image.size.toLong(), image.size.toLong())
            Result(
                true,
                "Flash complete — ${options.chip.label} @ 0x${options.flashOffset.toString(16)}. " +
                    "Press RESET / power-cycle the device now.",
            )
        } catch (e: Exception) {
            Result(false, e.message ?: e.toString())
        } finally {
            if (opened) {
                try {
                    port.close()
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun logUsb(device: UsbDevice) {
        val vid = device.vendorId
        val pid = device.productId
        val jtag = vid == 0x303A && (pid == 0x1001 || pid == 0x8140 || pid == 0x8141)
        onLog(
            "USB VID=0x${vid.toString(16)} PID=0x${pid.toString(16)} " +
                "name=${device.deviceName} " +
                if (jtag) "[Espressif USB-Serial/JTAG]" else "",
        )
    }

    private class Session(
        private val port: UsbSerialPort,
        private val onLog: (String) -> Unit,
        private val cancelled: AtomicBoolean,
    ) {
        private val decoder = SlipCodec.Decoder()
        private val readBuf = ByteArray(4096)

        fun syncWithStrategies(strategies: List<ResetStrategy>, chip: Chip) {
            var last: Exception? = null
            for ((si, strategy) in strategies.withIndex()) {
                if (cancelled.get()) throw IOException("Cancelled")
                onLog("Reset strategy ${si + 1}/${strategies.size}: $strategy")
                applyReset(strategy)
                try {
                    sync(attempts = 5, baseTimeoutMs = 300L + si * 100L)
                    onLog("Synced via $strategy")
                    return
                } catch (e: Exception) {
                    last = e
                    onLog("Sync failed after $strategy — ${e.message}")
                    Thread.sleep(200L + si * 150L)
                }
            }
            throw IOException(
                "Sync failed (cmd 0x08). Put ${chip.label} in download mode manually, " +
                    "then tap FLASH again or use Skip auto-reset. (${last?.message})",
            )
        }

        /**
         * Apply a download-mode entry strategy. ESP32-S3 native USB often ignores
         * DTR/RTS; the 1200-baud touch is the usual software fallback.
         */
        fun applyReset(strategy: ResetStrategy) {
            when (strategy) {
                ResetStrategy.CLASSIC_DTR_RTS -> {
                    // Classic USB-UART: RTS drives EN, DTR drives IO0 (BOOT).
                    trySetLines(dtr = false, rts = true) // EN low
                    Thread.sleep(100)
                    trySetLines(dtr = true, rts = true) // BOOT low, EN low
                    Thread.sleep(100)
                    trySetLines(dtr = true, rts = false) // EN high → boot download
                    Thread.sleep(50)
                    trySetLines(dtr = false, rts = false)
                    Thread.sleep(500)
                }
                ResetStrategy.INVERTED_DTR_RTS -> {
                    trySetLines(dtr = true, rts = false)
                    Thread.sleep(100)
                    trySetLines(dtr = false, rts = false)
                    Thread.sleep(100)
                    trySetLines(dtr = false, rts = true)
                    Thread.sleep(50)
                    trySetLines(dtr = true, rts = true)
                    Thread.sleep(500)
                }
                ResetStrategy.BAUD_1200_TOUCH -> {
                    // Many S3 USB-JTAG stacks enter download when host opens @ 1200 then closes.
                    try {
                        port.setParameters(1200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
                        trySetLines(dtr = false, rts = false)
                        Thread.sleep(80)
                        trySetLines(dtr = true, rts = false)
                        Thread.sleep(80)
                        trySetLines(dtr = false, rts = false)
                        Thread.sleep(200)
                        port.setParameters(115200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
                        Thread.sleep(600)
                    } catch (e: Exception) {
                        onLog("1200-baud touch unavailable: ${e.message}")
                        try {
                            port.setParameters(115200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
                        } catch (_: Exception) {
                        }
                        Thread.sleep(400)
                    }
                }
                ResetStrategy.NONE -> {
                    onLog("Skipping auto-reset — expecting manual download mode.")
                    Thread.sleep(300)
                }
            }
            flushInput()
        }

        private fun trySetLines(dtr: Boolean, rts: Boolean) {
            try {
                port.dtr = dtr
                port.rts = rts
            } catch (_: Exception) {
                // USB-JTAG / some CDC stacks reject line-state control.
            }
        }

        fun sync(attempts: Int, baseTimeoutMs: Long) {
            var last: Exception? = null
            repeat(attempts) { attempt ->
                try {
                    flushInput()
                    val data = ByteArray(36)
                    data[0] = 0x07
                    data[1] = 0x07
                    data[2] = 0x12
                    data[3] = 0x20
                    for (i in 4 until 36) data[i] = 0x55
                    val timeout = baseTimeoutMs + attempt * 120L
                    command(CMD_SYNC, data, checksum = 0, timeoutMs = timeout)
                    drainQuiet(150)
                    onLog("ROM sync ok (attempt ${attempt + 1})")
                    return
                } catch (e: Exception) {
                    last = e
                    Thread.sleep(100L + attempt * 80L)
                }
            }
            throw IOException(last?.message ?: "Sync timeout")
        }

        fun spiAttach(chip: Chip) {
            val payload = ByteArray(8)
            command(CMD_SPI_ATTACH, payload, checksum = 0, timeoutMs = 2000)
        }

        fun changeBaud(baud: Int) {
            val payload = ByteArray(8)
            writeU32(payload, 0, baud)
            writeU32(payload, 4, 0)
            command(CMD_CHANGE_BAUDRATE, payload, checksum = 0, timeoutMs = 2000)
            Thread.sleep(50)
            port.setParameters(baud, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
            Thread.sleep(80)
            flushInput()
        }

        fun eraseRegion(offset: Int, size: Int) {
            val begin = ByteArray(16)
            writeU32(begin, 0, size)
            writeU32(begin, 4, 0) // no data blocks — erase only
            writeU32(begin, 8, FLASH_BLOCK)
            writeU32(begin, 12, offset)
            command(CMD_FLASH_BEGIN, begin, checksum = 0, timeoutMs = 120_000)
        }

        fun flashImage(
            image: ByteArray,
            offset: Int,
            onProgress: (written: Long, total: Long) -> Unit,
        ) {
            val blockSize = FLASH_BLOCK
            val blocks = (image.size + blockSize - 1) / blockSize
            val eraseSize = blocks * blockSize

            val begin = ByteArray(16)
            writeU32(begin, 0, eraseSize)
            writeU32(begin, 4, blocks)
            writeU32(begin, 8, blockSize)
            writeU32(begin, 12, offset)
            command(CMD_FLASH_BEGIN, begin, checksum = 0, timeoutMs = 60_000)

            var sent = 0
            for (seq in 0 until blocks) {
                val start = seq * blockSize
                val end = min(start + blockSize, image.size)
                val chunk = ByteArray(blockSize)
                chunk.fill(0xFF.toByte())
                System.arraycopy(image, start, chunk, 0, end - start)

                val hdr = ByteArray(16 + blockSize)
                writeU32(hdr, 0, end - start)
                writeU32(hdr, 4, seq)
                writeU32(hdr, 8, 0)
                writeU32(hdr, 12, 0)
                System.arraycopy(chunk, 0, hdr, 16, blockSize)

                val chk = espChecksum(chunk)
                command(CMD_FLASH_DATA, hdr, checksum = chk, timeoutMs = 15_000)
                sent = end
                onProgress(sent.toLong(), image.size.toLong())
            }
        }

        fun flashEnd(reboot: Boolean) {
            val payload = ByteArray(4)
            writeU32(payload, 0, if (reboot) 0 else 1)
            try {
                command(CMD_FLASH_END, payload, checksum = 0, timeoutMs = 2000)
            } catch (_: Exception) {
                // Device may drop the port on reboot.
            }
        }

        private fun command(
            cmd: Int,
            data: ByteArray,
            checksum: Int,
            timeoutMs: Long,
        ): ByteArray {
            val packet = ByteArray(8 + data.size)
            packet[0] = 0x00
            packet[1] = cmd.toByte()
            packet[2] = (data.size and 0xFF).toByte()
            packet[3] = ((data.size shr 8) and 0xFF).toByte()
            writeU32(packet, 4, checksum)
            System.arraycopy(data, 0, packet, 8, data.size)
            writeSlip(packet)

            val deadline = System.currentTimeMillis() + timeoutMs
            while (System.currentTimeMillis() < deadline) {
                val frame = readFrame(deadline - System.currentTimeMillis()) ?: continue
                if (frame.size < 8) continue
                if (frame[0] != 0x01.toByte()) continue
                if (frame[1].toInt() and 0xFF != cmd) continue
                val size = (frame[2].toInt() and 0xFF) or ((frame[3].toInt() and 0xFF) shl 8)
                if (size >= 2 && frame.size >= 10) {
                    val fail = frame[8].toInt() and 0xFF
                    val err = frame[9].toInt() and 0xFF
                    if (fail != 0) {
                        throw IOException(
                            "ROM cmd 0x${cmd.toString(16)} failed status=$fail err=0x${err.toString(16)}",
                        )
                    }
                }
                return frame
            }
            throw IOException("Timeout waiting for cmd 0x${cmd.toString(16)}")
        }

        private fun writeSlip(payload: ByteArray) {
            val framed = SlipCodec.encode(payload)
            port.write(framed, WRITE_TIMEOUT_MS)
        }

        private fun readFrame(timeoutMs: Long): ByteArray? {
            val deadline = System.currentTimeMillis() + timeoutMs.coerceAtLeast(1)
            while (System.currentTimeMillis() < deadline) {
                val n = try {
                    port.read(readBuf, READ_TIMEOUT_MS)
                } catch (_: Exception) {
                    0
                }
                if (n > 0) {
                    val frames = decoder.feed(readBuf.copyOf(n))
                    if (frames.isNotEmpty()) return frames.first()
                }
            }
            return null
        }

        private fun drainQuiet(ms: Long) {
            val deadline = System.currentTimeMillis() + ms
            while (System.currentTimeMillis() < deadline) {
                val n = try {
                    port.read(readBuf, 40)
                } catch (_: Exception) {
                    0
                }
                if (n > 0) decoder.feed(readBuf.copyOf(n))
            }
        }

        private fun flushInput() {
            decoder.reset()
            repeat(12) {
                val n = try {
                    port.read(readBuf, 20)
                } catch (_: Exception) {
                    0
                }
                if (n <= 0) return
            }
        }
    }

    companion object {
        const val DEFAULT_FULL_OFFSET = 0x0
        const val DEFAULT_APP_OFFSET = 0x10000
        private const val FLASH_BLOCK = 0x400
        private const val CMD_FLASH_BEGIN = 0x02
        private const val CMD_FLASH_DATA = 0x03
        private const val CMD_FLASH_END = 0x04
        private const val CMD_SYNC = 0x08
        private const val CMD_SPI_ATTACH = 0x0D
        private const val CMD_CHANGE_BAUDRATE = 0x0F
        private const val WRITE_TIMEOUT_MS = 2000
        private const val READ_TIMEOUT_MS = 120

        private fun writeU32(buf: ByteArray, offset: Int, value: Int) {
            buf[offset] = (value and 0xFF).toByte()
            buf[offset + 1] = ((value shr 8) and 0xFF).toByte()
            buf[offset + 2] = ((value shr 16) and 0xFF).toByte()
            buf[offset + 3] = ((value shr 24) and 0xFF).toByte()
        }

        private fun espChecksum(data: ByteArray): Int {
            var c = 0xEF
            for (b in data) {
                c = c xor (b.toInt() and 0xFF)
            }
            return c
        }
    }
}
