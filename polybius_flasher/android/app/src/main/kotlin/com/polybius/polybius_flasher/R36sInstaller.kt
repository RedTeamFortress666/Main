package com.polybius.polybius_flasher

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.util.zip.ZipInputStream

/**
 * Installs the PØLYBĪUS R36S PortMaster zip into an SD card `roms/ports` (or `roms2/ports`) tree
 * selected via Storage Access Framework.
 */
class R36sInstaller(
    private val context: Context,
    private val onLog: (String) -> Unit,
    private val onProgress: (Double) -> Unit,
) {
    data class Result(val ok: Boolean, val message: String)

    fun install(zipFile: File, treeUri: Uri): Result {
        val resolver = context.contentResolver
        val root = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result(false, "Could not open selected SD folder")

        // Accept either the ports folder itself, or a parent containing ports/.
        val portsDir = when {
            root.name.equals("ports", ignoreCase = true) -> root
            else -> {
                val existing = root.findFile("ports")
                when {
                    existing != null && existing.isDirectory -> existing
                    else -> root.createDirectory("ports")
                        ?: return Result(false, "Cannot create ports/ under ${root.name}")
                }
            }
        }

        onLog("Installing into ${displayPath(portsDir)}…")

        val entries = ArrayList<Pair<String, Long>>()
        ZipInputStream(BufferedInputStream(FileInputStream(zipFile))).use { zin ->
            while (true) {
                val entry = zin.nextEntry ?: break
                if (!entry.isDirectory) {
                    // Zip layout: ports/Polybius.sh + ports/polybius/...
                    val name = entry.name.replace('\\', '/')
                    val relative = when {
                        name.startsWith("ports/") -> name.removePrefix("ports/")
                        else -> name
                    }
                    if (relative.isNotBlank()) {
                        entries.add(relative to entry.size)
                    }
                }
                zin.closeEntry()
            }
        }

        if (entries.isEmpty()) {
            return Result(false, "Zip has no files under ports/")
        }

        val totalBytes = entries.sumOf { it.second.coerceAtLeast(0L) }.coerceAtLeast(1L)
        var written = 0L
        var fileCount = 0

        ZipInputStream(BufferedInputStream(FileInputStream(zipFile))).use { zin ->
            while (true) {
                val entry = zin.nextEntry ?: break
                try {
                    if (entry.isDirectory) continue
                    val name = entry.name.replace('\\', '/')
                    val relative = when {
                        name.startsWith("ports/") -> name.removePrefix("ports/")
                        else -> name
                    }
                    if (relative.isBlank()) continue

                    val target = ensureFile(portsDir, relative, resolver)
                        ?: return Result(false, "Cannot create $relative")

                    resolver.openOutputStream(target.uri, "w")?.use { out ->
                        val buf = ByteArray(64 * 1024)
                        while (true) {
                            val n = zin.read(buf)
                            if (n <= 0) break
                            out.write(buf, 0, n)
                            written += n
                            onProgress((written.toDouble() / totalBytes.toDouble()).coerceIn(0.0, 1.0))
                        }
                        out.flush()
                    } ?: return Result(false, "Cannot write $relative")

                    fileCount++
                    if (fileCount % 5 == 0) {
                        onLog("Wrote $fileCount files…")
                    }
                } finally {
                    zin.closeEntry()
                }
            }
        }

        onProgress(1.0)
        return Result(
            true,
            "Installed $fileCount files into ${displayPath(portsDir)}. " +
                "On ArkOS / JELOS open Ports → Polybius.",
        )
    }

    private fun displayPath(dir: DocumentFile): String {
        return dir.name ?: "ports"
    }

    private fun ensureFile(portsDir: DocumentFile, relative: String, resolver: ContentResolver): DocumentFile? {
        val parts = relative.split('/').filter { it.isNotBlank() }
        if (parts.isEmpty()) return null
        var current = portsDir
        for (i in 0 until parts.lastIndex) {
            val name = parts[i]
            val next = current.findFile(name)
            current = when {
                next != null && next.isDirectory -> next
                next != null -> return null
                else -> current.createDirectory(name) ?: return null
            }
        }
        val fileName = parts.last()
        val existing = current.findFile(fileName)
        if (existing != null) {
            if (existing.isFile) {
                // Truncate by deleting + recreating for clean overwrite
                existing.delete()
            } else {
                return null
            }
        }
        val mime = guessMime(fileName)
        return current.createFile(mime, fileName)
    }

    private fun guessMime(name: String): String {
        return when {
            name.endsWith(".sh") -> "application/x-sh"
            name.endsWith(".so") -> "application/x-sharedlib"
            name.endsWith(".json") -> "application/json"
            name.endsWith(".txt") -> "text/plain"
            name.endsWith(".wav") -> "audio/wav"
            name.endsWith(".otf") -> "font/otf"
            name.endsWith(".ttf") -> "font/ttf"
            name.endsWith(".dat") -> "application/octet-stream"
            else -> "application/octet-stream"
        }
    }
}
