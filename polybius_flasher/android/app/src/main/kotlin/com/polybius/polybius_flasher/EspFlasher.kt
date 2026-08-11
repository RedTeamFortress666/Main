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
 * Minimal ESP ROM bootloader flasher (uncompressed write_flash).
 *
 * Flashes an ESP-IDF / Arduino application image at [flashOffset] (default 0x10000).
 * Requires an existing bootloader + partition table on the chip (typical for CYD / T-Deck
 * field updates). Hold BOOT while resetting if auto-reset via DTR/RTS fails.
 */
class EspFlasher(
    private val usbManager: UsbManager,
    private val onLog: (String) -> Unit,
    private val onProgress: (Double) -> Unit,
) {
    enum class Chip(val label: String) {
        ESP32("esp32"),
        ESP32_S3("esp32s3"),
    }

    data class Result(val ok: Boolean, val message: String)

    private val cancelled = AtomicBoolean(false)

    fun cancel() {
        cancelled.set(true)
    }

    fun flash(
        device: UsbDevice,
        connection: UsbDeviceConnection,
        firmware: File,
        chip: Chip,
        flashOffset: Int = DEFAULT_APP_OFFSET,
        baud: Int = 460800,
    ): Result {
        cancelled.set(false)
        val drivers = UsbSerialProber.getDefaultProber().findAllDrivers(usbManager)
        val driver = drivers.firstOrNull { it.device.deviceId == device.deviceId &&
            it.device.vendorId == device.vendorId }
            ?: return Result(false, "No USB serial driver for ${device.deviceName}")

        val port = driver.ports.firstOrNull()
            ?: return Result(false, "USB device has no serial ports")

        var opened = false
        return try {
            port.open(connection)
            opened = true
            port.setParameters(115200, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
            try {
                port.dtr = false
                port.rts = false
            } catch (_: Exception) {
                // Some CDC stacks reject line-state; manual BOOT is fine.
            }

            val session = Session(port, onLog)
            onLog("Resetting into download mode…")
            session.enterBootloader()
            onLog("Syncing with ${chip.label} ROM…")
            session.sync()
            onLog("Attaching SPI flash…")
            session.spiAttach(chip)
            if (baud != 115200) {
                onLog("Raising baud to $baud…")
                session.changeBaud(baud)
            }

            val image = firmware.readBytes()
            if (image.isEmpty()) return Result(false, "Firmware file is empty")
            onLog("Writing ${image.size} bytes at 0x${flashOffset.toString(16)}…")
            session.flashImage(image, flashOffset) { pct ->
                onProgress(pct)
                if (cancelled.get()) throw IOException("Cancelled")
            }

            onLog("Finishing…")
            session.flashEnd(reboot = true)
            onProgress(1.0)
            Result(true, "Flash complete — ${chip.label} @ 0x${flashOffset.toString(16)}")
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

    private class Session(
        private val port: UsbSerialPort,
        private val onLog: (String) -> Unit,
    ) {
        private val decoder = SlipCodec.Decoder()
        private val readBuf = ByteArray(4096)

        fun enterBootloader() {
            // Classic USB-UART auto-reset: IO0 low, EN pulse.
            try {
                port.dtr = false
                port.rts = true // EN low
                Thread.sleep(100)
                port.dtr = true // IO0 low (download)
                Thread.sleep(100)
                port.rts = false // EN high — boot
                Thread.sleep(50)
                port.dtr = false
                Thread.sleep(400)
            } catch (_: Exception) {
                onLog("Auto-reset unavailable — hold BOOT, tap RESET, then wait.")
                Thread.sleep(800)
            }
            flushInput()
        }

        fun sync() {
            var last: Exception? = null
            repeat(12) { attempt ->
                try {
                    flushInput()
                    val data = ByteArray(36)
                    data[0] = 0x07
                    data[1] = 0x07
                    data[2] = 0x12
                    data[3] = 0x20
                    for (i in 4 until 36) data[i] = 0x55
                    command(CMD_SYNC, data, checksum = 0, timeoutMs = 200)
                    // Drain extra SYNC responses
                    drainQuiet(150)
                    onLog("Synced (attempt ${attempt + 1})")
                    return
                } catch (e: Exception) {
                    last = e
                    Thread.sleep(80)
                }
            }
            throw IOException(
                "Sync failed — hold BOOT, press RESET, retry. (${last?.message})",
            )
        }

        fun spiAttach(chip: Chip) {
            // ESP32 needs a 0 payload; ESP32-S3 uses same SPI_ATTACH with 0.
            val payload = when (chip) {
                Chip.ESP32 -> ByteArray(8) // hspi=0 + legacy pad
                Chip.ESP32_S3 -> ByteArray(8)
            }
            command(CMD_SPI_ATTACH, payload, checksum = 0, timeoutMs = 1500)
        }

        fun changeBaud(baud: Int) {
            val payload = ByteArray(8)
            writeU32(payload, 0, baud)
            writeU32(payload, 4, 0)
            command(CMD_CHANGE_BAUDRATE, payload, checksum = 0, timeoutMs = 1500)
            Thread.sleep(50)
            port.setParameters(baud, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE)
            Thread.sleep(50)
            flushInput()
        }

        fun flashImage(image: ByteArray, offset: Int, onProgress: (Double) -> Unit) {
            val blockSize = FLASH_BLOCK
            val blocks = (image.size + blockSize - 1) / blockSize
            val eraseSize = blocks * blockSize

            val begin = ByteArray(16)
            writeU32(begin, 0, eraseSize)
            writeU32(begin, 4, blocks)
            writeU32(begin, 8, blockSize)
            writeU32(begin, 12, offset)
            command(CMD_FLASH_BEGIN, begin, checksum = 0, timeoutMs = 30_000)

            var sent = 0
            for (seq in 0 until blocks) {
                val start = seq * blockSize
                val end = min(start + blockSize, image.size)
                val chunk = ByteArray(blockSize) // pad with 0xFF
                chunk.fill(0xFF.toByte())
                System.arraycopy(image, start, chunk, 0, end - start)

                val hdr = ByteArray(16 + blockSize)
                writeU32(hdr, 0, end - start)
                writeU32(hdr, 4, seq)
                writeU32(hdr, 8, 0)
                writeU32(hdr, 12, 0)
                System.arraycopy(chunk, 0, hdr, 16, blockSize)

                val chk = espChecksum(chunk)
                command(CMD_FLASH_DATA, hdr, checksum = chk, timeoutMs = 10_000)
                sent = end
                onProgress(sent.toDouble() / image.size.toDouble())
            }
        }

        fun flashEnd(reboot: Boolean) {
            val payload = ByteArray(4)
            writeU32(payload, 0, if (reboot) 0 else 1)
            try {
                command(CMD_FLASH_END, payload, checksum = 0, timeoutMs = 2000)
            } catch (_: Exception) {
                // Device may already reboot and drop the port.
            }
        }

        private fun command(
            cmd: Int,
            data: ByteArray,
            checksum: Int,
            timeoutMs: Long,
        ): ByteArray {
            val packet = ByteArray(8 + data.size)
            packet[0] = 0x00 // direction request
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
                val statusOffset = 8
                if (frame.size < statusOffset + 2) {
                    throw IOException("Short response for cmd 0x${cmd.toString(16)}")
                }
                // Some chips put status at end of body; classic ROM: last two bytes of data.
                val size = (frame[2].toInt() and 0xFF) or ((frame[3].toInt() and 0xFF) shl 8)
                if (size >= 2) {
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
            repeat(8) {
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
        const val DEFAULT_APP_OFFSET = 0x10000
        private const val FLASH_BLOCK = 0x400
        private const val CMD_FLASH_BEGIN = 0x02
        private const val CMD_FLASH_DATA = 0x03
        private const val CMD_FLASH_END = 0x04
        private const val CMD_SYNC = 0x08
        private const val CMD_SPI_ATTACH = 0x0D
        private const val CMD_CHANGE_BAUDRATE = 0x0F
        private const val WRITE_TIMEOUT_MS = 2000
        private const val READ_TIMEOUT_MS = 100

        private fun writeU32(buf: ByteArray, offset: Int, value: Int) {
            buf[offset] = (value and 0xFF).toByte()
            buf[offset + 1] = ((value shr 8) and 0xFF).toByte()
            buf[offset + 2] = ((value shr 16) and 0xFF).toByte()
            buf[offset + 3] = ((value shr 24) and 0xFF).toByte()
        }

        /** ESP ROM checksum: 0xEF XOR each data byte. */
        private fun espChecksum(data: ByteArray): Int {
            var c = 0xEF
            for (b in data) {
                c = c xor (b.toInt() and 0xFF)
            }
            return c
        }
    }
}
