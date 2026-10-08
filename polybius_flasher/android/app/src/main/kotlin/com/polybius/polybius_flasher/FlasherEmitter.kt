package com.polybius.polybius_flasher

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Structured EventChannel emitter.
 * Payload: {stage, percent, message, level, target, detail, ts, ok}
 */
class FlasherEmitter(
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    @Volatile
    var sink: EventChannel.EventSink? = null

    @Volatile
    var currentTarget: String = ""

    fun emit(
        stage: String,
        message: String,
        percent: Double? = null,
        level: String = "info",
        detail: String = "",
        ok: Boolean? = null,
        target: String? = null,
    ) {
        val payload =
            hashMapOf<String, Any?>(
                "stage" to stage,
                "message" to message,
                "level" to level,
                "target" to (target ?: currentTarget),
                "detail" to detail,
                "ts" to System.currentTimeMillis(),
                // Back-compat with older Flutter listeners
                "type" to if (percent != null) "progress" else "log",
                "value" to if (percent != null) {
                    mapOf(
                        "progress" to percent,
                        "written" to 0L,
                        "total" to 0L,
                        "message" to message,
                    )
                } else {
                    message
                },
            )
        if (percent != null) payload["percent"] = percent
        if (ok != null) payload["ok"] = ok
        mainHandler.post {
            try {
                sink?.success(payload)
            } catch (_: Exception) {
            }
        }
    }

    fun log(
        message: String,
        stage: String = "log",
        level: String = "info",
        detail: String = "",
        target: String? = null,
    ) {
        emit(stage = stage, message = message, level = level, detail = detail, target = target)
    }

    fun progress(percent: Double, message: String, stage: String = "progress") {
        emit(stage = stage, message = message, percent = percent.coerceIn(0.0, 1.0))
    }
}
