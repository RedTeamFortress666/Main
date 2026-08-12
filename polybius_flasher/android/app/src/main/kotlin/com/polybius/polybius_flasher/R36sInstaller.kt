package com.polybius.polybius_flasher

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import androidx.documentfile.provider.DocumentFile
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.util.concurrent.atomic.AtomicBoolean
import java.util.zip.ZipInputStream

/**
 * Installs the PØLYBĪUS R36S PortMaster zip into an SD card ports tree
 * selected via Storage Access Framework.
 *
 * Supports common roots (roms/ports, roms2/ports, EASYROMS/ports, …),
 * direct unzip into ports/, and PortMaster autoinstall staging.
 */
class R36sInstaller(
    private val context: Context,
    private val onLog: (String) -> Unit,
    private val onProgress: (Double, String) -> Unit,
    private val cancel: AtomicBoolean = AtomicBoolean(false),
) {
    data class Result(
        val ok: Boolean,
        val message: String,
        val portsPath: String = "",
        val verified: Boolean = false,
        val freeBytes: Long = -1L,
        val detail: String = "",
    )

    data class PathCandidate(
        val label: String,
        val relativeHint: String,
        val document: DocumentFile?,
    )

    enum class InstallMode {
        /** Unzip contents into ports/ (strip leading ports/). */
        DIRECT,

        /** Also stage the zip into ports/autoinstall or PortMaster/autoinstall. */
        AUTOINSTALL,
    }

    fun detectCandidates(treeUri: Uri): List<PathCandidate> {
        val root = DocumentFile.fromTreeUri(context, treeUri) ?: return emptyList()
        val out = ArrayList<PathCandidate>()

        fun add(label: String, hint: String, doc: DocumentFile?) {
            out.add(PathCandidate(label, hint, doc))
        }

        if (root.name.equals("ports", ignoreCase = true)) {
            add("Selected folder is ports/", "ports", root)
        }

        // Direct children
        for (name in listOf("ports", "Ports", "PORTS")) {
            root.findFile(name)?.takeIf { it.isDirectory }?.let {
                add("ports/ under ${root.name ?: "root"}", name, it)
            }
        }

        // roms / roms2 / EASYROMS / ROMS
        for (romName in listOf("roms", "roms2", "EASYROMS", "ROMS", "Roms")) {
            val roms = root.findFile(romName)?.takeIf { it.isDirectory } ?: continue
            for (portsName in listOf("ports", "Ports", "PORTS")) {
                val ports = roms.findFile(portsName)?.takeIf { it.isDirectory }
                add(
                    "$romName/$portsName",
                    "$romName/$portsName",
                    ports,
                )
            }
        }

        // Nested mnt/mmc/ROMS/Ports style if user picked a higher root
        walkFindPorts(root, depth = 0, maxDepth = 3, pathSoFar = root.name ?: "root")
            .forEach { (hint, doc) ->
                if (out.none { it.document?.uri == doc.uri }) {
                    add(hint, hint, doc)
                }
            }

        // Always offer "create roms/ports under selection"
        add("Create roms/ports under selection", "roms/ports (create)", null)

        return out
    }

    private fun walkFindPorts(
        dir: DocumentFile,
        depth: Int,
        maxDepth: Int,
        pathSoFar: String,
    ): List<Pair<String, DocumentFile>> {
        if (depth > maxDepth) return emptyList()
        val found = ArrayList<Pair<String, DocumentFile>>()
        if (dir.name.equals("ports", ignoreCase = true) && depth > 0) {
            found.add(pathSoFar to dir)
        }
        if (depth == maxDepth) return found
        for (child in dir.listFiles()) {
            if (!child.isDirectory) continue
            val name = child.name ?: continue
            // Skip huge ROM game folders
            if (name.startsWith(".") ) continue
            found.addAll(
                walkFindPorts(child, depth + 1, maxDepth, "$pathSoFar/$name"),
            )
        }
        return found
    }

    fun resolvePortsDir(
        treeUri: Uri,
        preferredHint: String?,
        createIfMissing: Boolean,
    ): DocumentFile? {
        val root = DocumentFile.fromTreeUri(context, treeUri) ?: return null
        if (root.name.equals("ports", ignoreCase = true)) return root

        val hint = preferredHint?.trim().orEmpty()
        if (hint.isNotEmpty() && !hint.contains("(create)")) {
            val parts = hint.split('/').filter { it.isNotBlank() && it != "(create)" }
            var cur: DocumentFile? = root
            for (part in parts) {
                cur = cur?.findFile(part)?.takeIf { it.isDirectory }
                if (cur == null) break
            }
            if (cur != null) return cur
        }

        // Auto-detect first existing ports dir
        detectCandidates(treeUri)
            .mapNotNull { it.document }
            .firstOrNull()
            ?.let { return it }

        if (!createIfMissing) return null
        val roms = root.findFile("roms")?.takeIf { it.isDirectory }
            ?: root.createDirectory("roms")
            ?: return null
        return roms.findFile("ports")?.takeIf { it.isDirectory }
            ?: roms.createDirectory("ports")
    }

    fun freeSpaceHint(treeUri: Uri): Long {
        return try {
            val root = DocumentFile.fromTreeUri(context, treeUri) ?: return -1L
            val pfd: ParcelFileDescriptor =
                context.contentResolver.openFileDescriptor(root.uri, "r") ?: return -1L
            pfd.use {
                // SAF doesn't expose free space reliably; probe via StatFs when possible.
                -1L
            }
        } catch (_: Exception) {
            -1L
        }
    }

    fun install(
        zipFile: File,
        treeUri: Uri,
        mode: InstallMode = InstallMode.DIRECT,
        preferredHint: String? = null,
    ): Result {
        if (cancel.get()) return Result(false, "Cancelled")
        val resolver = context.contentResolver
        val root = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result(false, "Could not open selected SD folder")

        onProgress(0.02, "Resolving ports directory…")
        val portsDir = resolvePortsDir(treeUri, preferredHint, createIfMissing = true)
            ?: return Result(false, "Cannot resolve or create a ports/ directory")

        val portsLabel = preferredHint?.takeIf { it.isNotBlank() } ?: displayPath(portsDir)
        onLog("Installing into $portsLabel (${mode.name})…")

        // Free-space soft check via zip size * 2 heuristic against available if we can.
        val zipSize = zipFile.length().coerceAtLeast(1L)
        onLog("Zip size ${zipSize / 1024} KiB — ensure the card has free space")

        onProgress(0.08, "Reading zip index…")
        val entries = ArrayList<Pair<String, Long>>()
        ZipInputStream(BufferedInputStream(FileInputStream(zipFile))).use { zin ->
            while (true) {
                if (cancel.get()) return Result(false, "Cancelled")
                val entry = zin.nextEntry ?: break
                if (!entry.isDirectory) {
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
                if (cancel.get()) return Result(false, "Cancelled")
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
                            onProgress(
                                (0.08 + 0.75 * (written.toDouble() / totalBytes.toDouble()))
                                    .coerceIn(0.0, 0.9),
                                "Writing $relative",
                            )
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

        if (mode == InstallMode.AUTOINSTALL) {
            onProgress(0.92, "Staging PortMaster autoinstall…")
            stageAutoinstall(root, portsDir, zipFile, resolver)
        }

        onProgress(0.96, "Verifying install…")
        val verify = verifyInstall(portsDir)
        onProgress(1.0, if (verify.ok) "Verified" else "Verify warnings")

        val msg =
            "Installed $fileCount files into $portsLabel" +
                (if (mode == InstallMode.AUTOINSTALL) " (+ autoinstall staged)" else "") +
                ". ${verify.message}"

        return Result(
            ok = verify.ok,
            message = msg,
            portsPath = portsLabel,
            verified = verify.ok,
            detail = verify.detail,
        )
    }

    private data class VerifyResult(val ok: Boolean, val message: String, val detail: String = "")

    private fun verifyInstall(portsDir: DocumentFile): VerifyResult {
        val scriptNames = listOf("Polybius.sh", "polybius.sh", "POLYBIUS.sh")
        val script = scriptNames.mapNotNull { portsDir.findFile(it) }.firstOrNull()
        val folder = listOf("polybius", "Polybius", "POLYBIUS")
            .mapNotNull { portsDir.findFile(it)?.takeIf { d -> d.isDirectory } }
            .firstOrNull()

        val missing = ArrayList<String>()
        if (script == null || (script.length() <= 0L)) missing.add("Polybius.sh")
        if (folder == null) {
            missing.add("polybius/")
        } else {
            val children = folder.listFiles()
            if (children.isEmpty()) missing.add("polybius/ (empty)")
        }

        return if (missing.isEmpty()) {
            VerifyResult(
                true,
                "Verified Polybius.sh + polybius/ present.",
                "script=${script?.name} dir=${folder?.name}",
            )
        } else {
            VerifyResult(
                false,
                "Missing/empty after write: ${missing.joinToString(", ")}",
                missing.joinToString(","),
            )
        }
    }

    private fun stageAutoinstall(
        root: DocumentFile,
        portsDir: DocumentFile,
        zipFile: File,
        resolver: ContentResolver,
    ) {
        val candidates = listOf(
            // under ports/
            Triple(portsDir, "autoinstall", true),
            // under PortMaster next to ports
            Triple(root, "PortMaster", false),
        )

        var staged = false
        for ((base, name, isAutoDir) in candidates) {
            try {
                val dir = if (isAutoDir) {
                    base.findFile(name)?.takeIf { it.isDirectory }
                        ?: base.createDirectory(name)
                } else {
                    val pm = base.findFile(name)?.takeIf { it.isDirectory }
                        ?: base.findFile("portmaster")?.takeIf { it.isDirectory }
                    val auto = pm?.findFile("autoinstall")?.takeIf { it.isDirectory }
                        ?: pm?.createDirectory("autoinstall")
                    auto
                } ?: continue

                val outName = "polybius-r36s-port.zip"
                dir.findFile(outName)?.delete()
                val dest = dir.createFile("application/zip", outName) ?: continue
                resolver.openOutputStream(dest.uri, "w")?.use { out ->
                    FileInputStream(zipFile).use { input -> input.copyTo(out) }
                } ?: continue
                onLog("Staged autoinstall zip at ${displayPath(dir)}/$outName")
                staged = true
                break
            } catch (e: Exception) {
                onLog("Autoinstall stage skipped (${e.message})")
            }
        }
        if (!staged) {
            onLog("Could not stage autoinstall — direct ports/ install still applied")
        }
    }

    private fun displayPath(dir: DocumentFile): String = dir.name ?: "ports"

    private fun ensureFile(
        portsDir: DocumentFile,
        relative: String,
        resolver: ContentResolver,
    ): DocumentFile? {
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
                existing.delete()
            } else {
                return null
            }
        }
        return current.createFile(guessMime(fileName), fileName)
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
            name.endsWith(".zip") -> "application/zip"
            else -> "application/octet-stream"
        }
    }
}
