package com.polybius.polybius_flasher

/**
 * SLIP framing used by the ESP ROM serial bootloader protocol.
 */
object SlipCodec {
    const val END: Byte = 0xC0.toByte()
    const val ESC: Byte = 0xDB.toByte()
    private const val ESC_END: Byte = 0xDC.toByte()
    private const val ESC_ESC: Byte = 0xDD.toByte()

    fun encode(payload: ByteArray): ByteArray {
        val out = ArrayList<Byte>(payload.size + 16)
        out.add(END)
        for (b in payload) {
            when (b) {
                END -> {
                    out.add(ESC)
                    out.add(ESC_END)
                }
                ESC -> {
                    out.add(ESC)
                    out.add(ESC_ESC)
                }
                else -> out.add(b)
            }
        }
        out.add(END)
        return out.toByteArray()
    }

    /**
     * Accumulates USB bytes and yields complete SLIP frames (payload without END markers).
     */
    class Decoder {
        private val buf = ArrayList<Byte>(512)
        private var escape = false
        private var inFrame = false

        fun feed(data: ByteArray): List<ByteArray> {
            val frames = ArrayList<ByteArray>()
            for (raw in data) {
                val b = raw
                if (!inFrame) {
                    if (b == END) {
                        inFrame = true
                        buf.clear()
                        escape = false
                    }
                    continue
                }
                if (escape) {
                    when (b) {
                        ESC_END -> buf.add(END)
                        ESC_ESC -> buf.add(ESC)
                        else -> buf.add(b)
                    }
                    escape = false
                    continue
                }
                when (b) {
                    END -> {
                        if (buf.isNotEmpty()) {
                            frames.add(buf.toByteArray())
                        }
                        buf.clear()
                        // back-to-back END starts next frame
                        inFrame = true
                    }
                    ESC -> escape = true
                    else -> buf.add(b)
                }
            }
            return frames
        }

        fun reset() {
            buf.clear()
            escape = false
            inFrame = false
        }
    }
}
