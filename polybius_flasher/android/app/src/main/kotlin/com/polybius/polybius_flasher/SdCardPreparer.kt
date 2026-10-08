package com.polybius.polybius_flasher

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.storage.StorageManager
import android.provider.Settings
import androidx.documentfile.provider.DocumentFile
import java.io.IOException

/**
 * Prepares a microSD (or USB card-reader volume) for Polybius flashing.
 *
 * Android third-party apps cannot run block-level `mkfs` without privileged
 * permissions. This preparer:
 *  1. Verifies the volume is writable (FAT32 / exFAT / compatible)
 *  2. Optionally performs a **logical format** (wipe selected tree)
 *  3. Recreates the PortMaster / ESP asset directory layout
 *  4. Can deep-link the user to system storage settings for a full format
 */
class SdCardPreparer(
    private val context: Context,
    private val onLog: (String) -> Unit,
    private val onProgress: (Double) -> Unit,
) {
    data class Result(val ok: Boolean, val message: String)

    enum class Layout {
        /** ArkOS / JELOS / PortMaster: roms/ports/ */
        R36S_PORTS,

        /** ESP boards with microSD: polybius/ asset tree */
        ESP_ASSETS,
    }

    fun prepare(
        treeUri: Uri,
        layout: Layout,
        logicalFormat: Boolean,
        wipePreviousPolybius: Boolean,
    ): Result {
        onProgress(0.02)
        val root = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result(false, "Could not open selected SD folder")

        if (!root.canWrite()) {
            return Result(
                false,
                "Selected volume is not writable. Format the card as FAT32 or exFAT " +
                    "in Android Settings → Storage, then retry.",
            )
        }

        onLog("Probing volume write…")
        val probe = probeWritable(root)
        if (!probe.ok) return probe
        onProgress(0.12)

        if (logicalFormat) {
            onLog("Logical format — wiping selected tree…")
            val wiped = wipeChildren(root)
            if (!wiped.ok) return wiped
            onProgress(0.45)
        } else if (wipePreviousPolybius) {
            onLog("Removing previous Polybius install…")
            wipePrevious(root, layout)
            onProgress(0.35)
        }

        onLog("Creating ${layout.name} layout…")
        val layoutResult = when (layout) {
            Layout.R36S_PORTS -> ensureR36sLayout(root)
            Layout.ESP_ASSETS -> ensureEspLayout(root)
        }
        if (!layoutResult.ok) {
            return Result(false, layoutResult.message)
        }
        onProgress(0.85)

        // Stamp a readiness marker so flash steps can confirm prepare ran.
        val markerDir = layoutResult.anchor
            ?: return Result(false, "Layout created but anchor missing")
        val markerName = "POLYBIUS_SD_READY.txt"
        markerDir.findFile(markerName)?.delete()
        val marker = markerDir.createFile("text/plain", markerName)
            ?: return Result(false, "Cannot write readiness marker — is the card FAT32/exFAT?")
        context.contentResolver.openOutputStream(marker.uri, "w")?.use { out ->
            out.write(
                (
                    "PØLYBÎŪS flasher prepared this volume.\n" +
                        "layout=${layout.name}\n" +
                        "fs=writable (FAT32/exFAT expected)\n"
                    ).toByteArray(Charsets.UTF_8),
            )
        } ?: return Result(false, "Cannot write readiness marker")

        onProgress(1.0)
        val tip =
            when (layout) {
                Layout.R36S_PORTS ->
                    "Ready for Port flash. Next: FLASH to install into roms/ports/."
                Layout.ESP_ASSETS ->
                    "Ready for ESP microSD assets. Firmware still flashes over USB-OTG."
            }
        return Result(
            true,
            "SD prepared (${layout.name.replace('_', ' ')}). $tip",
        )
    }

    fun openSystemFormatSettings(): Result {
        val candidates = listOf(
            Settings.ACTION_INTERNAL_STORAGE_SETTINGS,
            Settings.ACTION_MEMORY_CARD_SETTINGS,
            Settings.ACTION_SETTINGS,
        )
        for (action in candidates) {
            try {
                val intent = Intent(action).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                return Result(
                    true,
                    "Opened system settings — format the SD as FAT32 or exFAT, then return here.",
                )
            } catch (_: Exception) {
                // try next
            }
        }
        return Result(
            false,
            "Could not open storage settings. Format the card as FAT32/exFAT manually, then return here.",
        )
    }

    fun describeVolumes(): String {
        return try {
            val sm = context.getSystemService(StorageManager::class.java) ?: return "StorageManager unavailable"
            val vols = sm.storageVolumes
            if (vols.isEmpty()) return "No storage volumes reported"
            vols.joinToString("\n") { v ->
                val label = v.getDescription(context)
                val rem = if (v.isRemovable) "removable" else "internal"
                val state = v.state
                val uuid = if (Build.VERSION.SDK_INT >= 24) v.uuid ?: "-" else "-"
                "$label · $rem · $state · uuid=$uuid"
            }
        } catch (e: Exception) {
            "Volume probe failed: ${e.message}"
        }
    }

    private fun probeWritable(root: DocumentFile): Result {
        val name = ".__polybius_write_probe"
        try {
            root.findFile(name)?.delete()
            val probe = root.createFile("application/octet-stream", name)
                ?: return Result(
                    false,
                    "Write probe failed — format SD as FAT32/exFAT (not NTFS/ext4) and grant access.",
                )
            context.contentResolver.openOutputStream(probe.uri, "w")?.use { out ->
                out.write(byteArrayOf(0x50, 0x42)) // "PB"
                out.flush()
            } ?: return Result(false, "Write probe open failed")
            if (!probe.delete()) {
                onLog("Probe file left behind (non-fatal)")
            }
            return Result(true, "Writable")
        } catch (e: Exception) {
            return Result(false, "Write probe error: ${e.message ?: e}")
        }
    }

    private fun wipeChildren(root: DocumentFile): Result {
        val children = root.listFiles()
        if (children.isEmpty()) {
            onLog("Tree already empty")
            return Result(true, "empty")
        }
        var deleted = 0
        val total = children.size.coerceAtLeast(1)
        for ((i, child) in children.withIndex()) {
            if (!deleteRecursive(child)) {
                return Result(false, "Failed to delete ${child.name} during logical format")
            }
            deleted++
            onProgress(0.12 + 0.30 * ((i + 1).toDouble() / total))
            if (deleted % 8 == 0) onLog("Wiped $deleted / $total entries…")
        }
        onLog("Logical format removed $deleted entries")
        return Result(true, "wiped")
    }

    private fun wipePrevious(root: DocumentFile, layout: Layout) {
        when (layout) {
            Layout.R36S_PORTS -> {
                val ports = findPortsDir(root, create = false) ?: return
                for (name in listOf("polybius", "Polybius", "POLYBIUS")) {
                    ports.findFile(name)?.let {
                        onLog("Removing ${it.name}…")
                        deleteRecursive(it)
                    }
                }
                for (name in listOf("Polybius.sh", "polybius.sh", "POLYBIUS.sh")) {
                    ports.findFile(name)?.delete()
                }
            }
            Layout.ESP_ASSETS -> {
                for (name in listOf("polybius", "POLYBIUS")) {
                    root.findFile(name)?.let {
                        onLog("Removing ${it.name}…")
                        deleteRecursive(it)
                    }
                }
            }
        }
    }

    private data class LayoutResult(
        val ok: Boolean,
        val message: String,
        val anchor: DocumentFile? = null,
    )

    private fun ensureR36sLayout(root: DocumentFile): LayoutResult {
        // Accept: ports/, roms/, roms/ports/, or card root.
        val ports = findPortsDir(root, create = true)
            ?: return LayoutResult(false, "Cannot create roms/ports/ on this volume")
        // Ensure empty polybius placeholder dir exists for a clean flash target.
        val existing = ports.findFile("polybius")
        val polyDir = when {
            existing != null && existing.isDirectory -> existing
            existing != null -> {
                existing.delete()
                ports.createDirectory("polybius")
            }
            else -> ports.createDirectory("polybius")
        } ?: return LayoutResult(false, "Cannot create ports/polybius/")
        onLog("Layout ok: …/ports/polybius/")
        return LayoutResult(true, "ok", polyDir)
    }

    private fun ensureEspLayout(root: DocumentFile): LayoutResult {
        val existing = root.findFile("polybius")
        val polyDir = when {
            existing != null && existing.isDirectory -> existing
            existing != null -> {
                existing.delete()
                root.createDirectory("polybius")
            }
            else -> root.createDirectory("polybius")
        } ?: return LayoutResult(false, "Cannot create polybius/ on SD")
        onLog("Layout ok: polybius/")
        return LayoutResult(true, "ok", polyDir)
    }

    private fun findPortsDir(root: DocumentFile, create: Boolean): DocumentFile? {
        if (root.name.equals("ports", ignoreCase = true)) return root

        root.findFile("ports")?.takeIf { it.isDirectory }?.let { return it }

        val roms = root.findFile("roms")?.takeIf { it.isDirectory }
            ?: root.findFile("roms2")?.takeIf { it.isDirectory }
        if (roms != null) {
            roms.findFile("ports")?.takeIf { it.isDirectory }?.let { return it }
            if (create) return roms.createDirectory("ports")
            return null
        }

        if (!create) return null

        // Card root — create roms/ports
        val newRoms = root.createDirectory("roms") ?: return null
        return newRoms.createDirectory("ports")
    }

    private fun deleteRecursive(node: DocumentFile): Boolean {
        if (node.isDirectory) {
            for (child in node.listFiles()) {
                if (!deleteRecursive(child)) return false
            }
        }
        return try {
            node.delete()
        } catch (e: Exception) {
            throw IOException("delete ${node.name}: ${e.message}", e)
        }
    }
}
