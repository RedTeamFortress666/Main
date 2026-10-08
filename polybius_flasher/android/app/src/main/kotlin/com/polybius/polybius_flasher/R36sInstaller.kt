package com.polybius.polybius_flasher

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import androidx.documentfile.provider.DocumentFile
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.security.MessageDigest
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

    /** USB OTG stick layout folder name (easy to spot in R36S file manager). */
    private val usbPackageDirName = "POLYBIUS_R36S_USB"

    /** Staged CRYPT3X OS lite GPT image / zip (not a PortMaster unzip). */
    private val crypt3xPackageDirName = "CRYPT3X_OS_LITE"
    private val crypt3xEtcherDirName = "CRYPT3X_ETCHER"
    private val fat32MaxBytes = 4_294_967_295L
    private val kitPartPrefix = "CRYPT3X_OS_LITE-r36s-20260815.zip.part"
    private val altPartPrefix = "crypt3x_lite_img_zip.part"

    fun probeStickWrite(treeUri: Uri): Result {
        val root = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result(false, "Could not open selected USB stick folder")
        if (!root.canWrite()) {
            return Result(false, "USB stick is not writable. Use FAT32 or exFAT.")
        }
        return probeWritable(root)
    }

    /**
     * Writes a self-contained R36S package onto a USB stick for later copy on-device.
     *
     * Layout under the user-selected SAF tree:
     * ```
     * POLYBIUS_R36S_USB/
     *   README.txt
     *   ports/                 (extracted PortMaster port)
     *   polybius-r36s-port.zip (full zip backup / autoinstall source)
     *   custom/                (optional extra ROM/file)
     *   POLYBIUS_USB_READY.txt
     * ```
     */
    fun writeUsbStick(
        zipFile: File,
        treeUri: Uri,
        extraFile: File? = null,
        includeZipCopy: Boolean = true,
    ): Result {
        if (cancel.get()) return Result(false, "Cancelled")

        val resolver = context.contentResolver
        val stickRoot = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result(false, "Could not open selected USB stick folder")

        if (!stickRoot.canWrite()) {
            return Result(
                false,
                "USB stick is not writable. Use FAT32 or exFAT (format in Android Settings if needed).",
            )
        }

        onProgress(0.02, "Probing USB stick write access…")
        val probe = probeWritable(stickRoot)
        if (!probe.ok) return Result(false, probe.message)

        val zipSize = zipFile.length().coerceAtLeast(1L)
        val extraSize = extraFile?.length()?.coerceAtLeast(0L) ?: 0L
        val requiredBytes = zipSize * 2 + extraSize + (512 * 1024)
        onLog(
            "Payload ~${requiredBytes / (1024 * 1024)} MiB needed " +
                "(zip ${zipSize / 1024} KiB" +
                (if (extraSize > 0) " + extra ${extraSize / 1024} KiB" else "") +
                "). Ensure the stick has free space.",
        )
        if (requiredBytes > 900L * 1024 * 1024) {
            onLog("Warning: payload is large — verify the stick is not nearly full.")
        }

        onProgress(0.06, "Preparing $usbPackageDirName/ on USB stick…")
        stickRoot.findFile(usbPackageDirName)?.let { existing ->
            onLog("Removing previous $usbPackageDirName/…")
            deleteTree(existing)
        }
        val packageDir = stickRoot.createDirectory(usbPackageDirName)
            ?: return Result(false, "Cannot create $usbPackageDirName/ on stick")

        val portsDir = packageDir.createDirectory("ports")
            ?: return Result(false, "Cannot create $usbPackageDirName/ports/")

        onProgress(0.10, "Writing README…")
        writeTextFile(
            packageDir,
            "README.txt",
            usbReadmeText(),
            resolver,
        ) ?: return Result(false, "Cannot write README.txt")

        onProgress(0.12, "Extracting port into USB stick…")
        val extract = extractZipIntoPorts(zipFile, portsDir, resolver, progressStart = 0.12, progressEnd = 0.72)
        if (!extract.ok) return Result(false, extract.message)

        if (includeZipCopy) {
            onProgress(0.78, "Copying zip archive…")
            val zipName = zipFile.name.ifBlank { "polybius-r36s-port.zip" }
            packageDir.findFile(zipName)?.delete()
            val dest = packageDir.createFile("application/zip", zipName)
                ?: return Result(false, "Cannot create $zipName on stick")
            resolver.openOutputStream(dest.uri, "w")?.use { out ->
                FileInputStream(zipFile).use { input -> input.copyTo(out) }
            } ?: return Result(false, "Cannot write $zipName")
            onLog("Copied $zipName to stick root package folder")
        }

        extraFile?.let { extra ->
            onProgress(0.86, "Copying custom file…")
            val customDir = packageDir.findFile("custom")?.takeIf { it.isDirectory }
                ?: packageDir.createDirectory("custom")
                ?: return Result(false, "Cannot create custom/ folder")
            val safeName = extra.name.replace(Regex("[^A-Za-z0-9._-]"), "_")
            customDir.findFile(safeName)?.delete()
            val dest = customDir.createFile(guessMime(safeName), safeName)
                ?: return Result(false, "Cannot create custom/$safeName")
            resolver.openOutputStream(dest.uri, "w")?.use { out ->
                FileInputStream(extra).use { input -> input.copyTo(out) }
            } ?: return Result(false, "Cannot write custom/$safeName")
            onLog("Copied custom file custom/$safeName (${extra.length() / 1024} KiB)")
        }

        onProgress(0.94, "Writing readiness marker…")
        writeTextFile(
            packageDir,
            "POLYBIUS_USB_READY.txt",
            "PØLYBÎŪS R36S USB package ready.\n" +
                "Copy ports/ to your handheld SD roms/ports/ via the R36S file manager.\n",
            resolver,
        ) ?: return Result(false, "Cannot write POLYBIUS_USB_READY.txt")

        onProgress(0.96, "Verifying USB package…")
        val verify = verifyInstall(portsDir)
        onProgress(1.0, if (verify.ok) "USB stick ready" else "Verify warnings")

        val extraNote = extraFile?.let { " + custom/${it.name}" } ?: ""
        val msg =
            "Wrote $usbPackageDirName/ on USB stick (${extract.fileCount} files$extraNote). " +
                verify.message +
                " Eject safely, plug into R36S OTG, copy ports/ to roms/ports/."

        return Result(
            ok = verify.ok,
            message = msg,
            portsPath = "$usbPackageDirName/ports",
            verified = verify.ok,
            detail = verify.detail,
        )
    }

    /**
     * Stages the official 8 GiB CRYPT3X OS lite image (or its zip) onto a
     * SAF tree — typically an OTG USB stick. Does **not** `dd` the card;
     * unprivileged Android cannot write GPT to a block device.
     *
     * Layout:
     * ```
     * CRYPT3X_OS_LITE/
     *   README.txt
     *   FLASH.txt
     *   SHA256.txt
     *   lineage-18.1-…-crypt3x-lite.img[.zip]
     *   CRYPT3X_LITE_READY.txt
     * ```
     */
    fun writeCrypt3xLite(
        source: String,
        treeUri: Uri,
        destFileName: String,
        expectedSha256: String?,
        expectedBytes: Long,
    ): Result {
        if (cancel.get()) return Result(false, "Cancelled")

        val resolver = context.contentResolver
        val stickRoot = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result(false, "Could not open selected folder")
        if (!stickRoot.canWrite()) {
            return Result(false, "Destination is not writable. Use exFAT for the 8 GiB image (FAT32 max file is 4 GiB).")
        }

        onProgress(0.02, "Probing destination write access…")
        val probe = probeWritable(stickRoot)
        if (!probe.ok) return Result(false, probe.message)

        val sourceLen = sourceLength(source)
        if (sourceLen <= 0L) {
            return Result(false, "Cannot read source size — pick the .img or .img.zip again")
        }
        if (expectedBytes > 0L && sourceLen != expectedBytes) {
            return Result(
                false,
                "Size mismatch: source is $sourceLen bytes, catalog expects $expectedBytes",
            )
        }
        if (sourceLen > fat32MaxBytes) {
            onLog(
                "Source is ${sourceLen / (1024L * 1024L * 1024L)} GiB — FAT32 cannot hold this file. " +
                    "Use an exFAT stick, or stage the 921 MiB .img.zip instead.",
            )
        }

        onProgress(0.06, "Preparing $crypt3xPackageDirName/…")
        stickRoot.findFile(crypt3xPackageDirName)?.let { existing ->
            onLog("Removing previous $crypt3xPackageDirName/…")
            deleteTree(existing)
        }
        val packageDir = stickRoot.createDirectory(crypt3xPackageDirName)
            ?: return Result(false, "Cannot create $crypt3xPackageDirName/")

        onProgress(0.08, "Writing README + FLASH instructions…")
        writeTextFile(packageDir, "README.txt", crypt3xReadmeText(destFileName, sourceLen), resolver)
            ?: return Result(false, "Cannot write README.txt")
        writeTextFile(packageDir, "FLASH.txt", crypt3xFlashText(destFileName), resolver)
            ?: return Result(false, "Cannot write FLASH.txt")

        packageDir.findFile(destFileName)?.delete()
        val dest = packageDir.createFile(guessMime(destFileName), destFileName)
            ?: return Result(false, "Cannot create $destFileName")

        onProgress(0.10, "Copying $destFileName (${sourceLen / (1024L * 1024L)} MiB)…")
        val digest = MessageDigest.getInstance("SHA-256")
        val buf = ByteArray(1024 * 1024)
        var written = 0L
        try {
            openSource(source)?.use { input ->
                resolver.openOutputStream(dest.uri, "w")?.use { out ->
                    while (true) {
                        if (cancel.get()) {
                            dest.delete()
                            return Result(false, "Cancelled")
                        }
                        val n = input.read(buf)
                        if (n <= 0) break
                        out.write(buf, 0, n)
                        digest.update(buf, 0, n)
                        written += n
                        val frac = 0.10 + 0.80 * (written.toDouble() / sourceLen.toDouble())
                        onProgress(frac.coerceIn(0.10, 0.90), "Writing $destFileName")
                    }
                    out.flush()
                } ?: return Result(false, "Cannot open output for $destFileName")
            } ?: return Result(false, "Cannot open source image")
        } catch (e: Exception) {
            dest.delete()
            val hint =
                if (sourceLen > fat32MaxBytes) {
                    " FAT32 rejects files over 4 GiB — format the stick as exFAT or stage the .img.zip."
                } else {
                    ""
                }
            return Result(false, "Copy failed after $written bytes: ${e.message}.$hint")
        }

        if (written != sourceLen) {
            dest.delete()
            return Result(false, "Short write: $written of $sourceLen bytes")
        }

        val hex = digest.digest().joinToString("") { b -> "%02x".format(b) }
        val expect = expectedSha256?.lowercase()?.takeIf { it.length == 64 }
        val hashOk = expect == null || hex == expect
        if (!hashOk) {
            dest.delete()
            return Result(
                false,
                "SHA-256 mismatch for $destFileName\nexpected $expect\nactual   $hex",
                detail = "sha256=$hex",
            )
        }

        onProgress(0.92, "Writing SHA256 + ready marker…")
        writeTextFile(
            packageDir,
            "SHA256.txt",
            "$hex  $destFileName\n",
            resolver,
        ) ?: return Result(false, "Cannot write SHA256.txt")
        writeTextFile(
            packageDir,
            "CRYPT3X_LITE_READY.txt",
            "CRYPT3X OS LITE staged.\n" +
                "file=$destFileName\n" +
                "bytes=$written\n" +
                "sha256=$hex\n" +
                "verified=${expect != null}\n",
            resolver,
        ) ?: return Result(false, "Cannot write CRYPT3X_LITE_READY.txt")

        onProgress(1.0, "CRYPT3X OS LITE staged")
        val verifyNote = if (expect != null) "SHA-256 verified." else "SHA-256 recorded (catalog did not match this filename)."
        return Result(
            ok = true,
            message =
                "Wrote $crypt3xPackageDirName/$destFileName " +
                    "(${written / (1024L * 1024L)} MiB). $verifyNote " +
                    "Eject safely, then dd the .img onto the R36S SD from a PC " +
                    "(see FLASH.txt). The phone cannot write GPT to /dev/block.",
            portsPath = crypt3xPackageDirName,
            verified = expect != null,
            detail = "sha256=$hex bytes=$written",
        )
    }

    /**
     * Concatenates the twelve CRYPT3X zip parts (kit names or
     * `crypt3x_lite_img_zip.partNN`) onto a USB stick as
     * `CRYPT3X_ETCHER/` — ready for balenaEtcher / Rufus / `dd`.
     *
     * Does **not** `dd` the card. Unprivileged Android cannot write GPT.
     */
    fun assembleCrypt3xEtcherKit(
        partsTreeUri: Uri,
        destTreeUri: Uri,
        kitFileName: String,
        kitSha256: String,
        kitBytes: Long,
        officialZipFileName: String,
        officialZipSha256: String,
        officialZipBytes: Long,
        etcherFolder: String = crypt3xEtcherDirName,
        etcherText: String,
        rufusText: String,
        flashText: String,
    ): Result {
        if (cancel.get()) return Result(false, "Cancelled")

        val resolver = context.contentResolver
        val partsRoot = DocumentFile.fromTreeUri(context, partsTreeUri)
            ?: return Result(false, "Could not open the parts folder")
        val stickRoot = DocumentFile.fromTreeUri(context, destTreeUri)
            ?: return Result(false, "Could not open the USB stick / destination folder")
        if (!stickRoot.canWrite()) {
            return Result(false, "Destination is not writable. Use FAT32 or exFAT.")
        }

        onProgress(0.02, "Probing destination write access…")
        val probe = probeWritable(stickRoot)
        if (!probe.ok) return Result(false, probe.message)

        onProgress(0.04, "Looking for part00–part11…")
        val parts = findCrypt3xParts(partsRoot)
            ?: return Result(
                false,
                "Need all 12 parts in that folder (or one level down): " +
                    "${kitPartPrefix}00…11 or ${altPartPrefix}00…11",
            )
        val totalBytes = parts.sumOf { it.length().coerceAtLeast(0L) }
        if (totalBytes <= 0L) {
            return Result(false, "Parts are unreadable (size 0). Re-copy part00–part11.")
        }
        onLog(
            "Found ${parts.size} parts, ${totalBytes / (1024L * 1024L)} MiB. " +
                "Concatenating onto $etcherFolder/…",
        )

        onProgress(0.06, "Preparing $etcherFolder/…")
        stickRoot.findFile(etcherFolder)?.let { existing ->
            onLog("Removing previous $etcherFolder/…")
            deleteTree(existing)
        }
        val packageDir = stickRoot.createDirectory(etcherFolder)
            ?: return Result(false, "Cannot create $etcherFolder/")

        val tmpName = "CRYPT3X_ASSEMBLING.zip"
        packageDir.findFile(tmpName)?.delete()
        val dest = packageDir.createFile("application/zip", tmpName)
            ?: return Result(false, "Cannot create $tmpName")

        onProgress(0.08, "Concatenating parts…")
        val digest = MessageDigest.getInstance("SHA-256")
        val buf = ByteArray(1024 * 1024)
        var written = 0L
        try {
            resolver.openOutputStream(dest.uri, "w")?.use { out ->
                for ((index, part) in parts.withIndex()) {
                    if (cancel.get()) {
                        dest.delete()
                        return Result(false, "Cancelled")
                    }
                    val label = part.name ?: "part${index.toString().padStart(2, '0')}"
                    onLog("Appending $label (${part.length() / (1024L * 1024L)} MiB)")
                    resolver.openInputStream(part.uri)?.use { input ->
                        while (true) {
                            if (cancel.get()) {
                                dest.delete()
                                return Result(false, "Cancelled")
                            }
                            val n = input.read(buf)
                            if (n <= 0) break
                            out.write(buf, 0, n)
                            digest.update(buf, 0, n)
                            written += n
                            val frac = 0.08 + 0.78 * (written.toDouble() / totalBytes.toDouble())
                            onProgress(frac.coerceIn(0.08, 0.86), "Assembling $label")
                        }
                    } ?: run {
                        dest.delete()
                        return Result(false, "Cannot read $label")
                    }
                }
                out.flush()
            } ?: return Result(false, "Cannot open output for $tmpName")
        } catch (e: Exception) {
            dest.delete()
            return Result(false, "Assemble failed after $written bytes: ${e.message}")
        }

        if (written != totalBytes) {
            dest.delete()
            return Result(false, "Short write: $written of $totalBytes bytes")
        }

        val hex = digest.digest().joinToString("") { b -> "%02x".format(b) }
        val kitExpect = kitSha256.lowercase()
        val zipExpect = officialZipSha256.lowercase()
        val destFileName = when {
            hex == kitExpect && (kitBytes <= 0L || written == kitBytes) -> kitFileName
            hex == zipExpect && (officialZipBytes <= 0L || written == officialZipBytes) ->
                officialZipFileName
            hex == kitExpect -> kitFileName
            hex == zipExpect -> officialZipFileName
            else -> {
                dest.delete()
                return Result(
                    false,
                    "SHA-256 mismatch for assembled zip\n" +
                        "expected kit $kitExpect ($kitBytes bytes) or " +
                        "official $zipExpect ($officialZipBytes bytes)\n" +
                        "actual   $hex ($written bytes)\n" +
                        "Re-download part00–part11 and try again.",
                    detail = "sha256=$hex bytes=$written",
                )
            }
        }

        onProgress(0.88, "Renaming to $destFileName…")
        if (!renameAssembledZip(packageDir, dest, destFileName, resolver)) {
            dest.delete()
            return Result(false, "Cannot rename assembled zip to $destFileName")
        }

        val namedEtcher = etcherText.replace(kitFileName, destFileName)
        val namedRufus = rufusText.replace(kitFileName, destFileName)
        val namedFlash = flashText.replace(kitFileName, destFileName)

        onProgress(0.92, "Writing ETCHER / RUFUS / FLASH instructions…")
        writeTextFile(packageDir, "ETCHER.txt", namedEtcher, resolver)
            ?: return Result(false, "Cannot write ETCHER.txt")
        writeTextFile(packageDir, "RUFUS.txt", namedRufus, resolver)
            ?: return Result(false, "Cannot write RUFUS.txt")
        writeTextFile(packageDir, "FLASH.txt", namedFlash, resolver)
            ?: return Result(false, "Cannot write FLASH.txt")
        writeTextFile(
            packageDir,
            "SHA256.txt",
            "$hex  $destFileName\n",
            resolver,
        ) ?: return Result(false, "Cannot write SHA256.txt")
        writeTextFile(
            packageDir,
            "CRYPT3X_ETCHER_READY.txt",
            "CRYPT3X OS LITE Etcher/Rufus kit ready.\n" +
                "file=$destFileName\n" +
                "bytes=$written\n" +
                "sha256=$hex\n" +
                "folder=$etcherFolder\n" +
                "etcher=select $destFileName (or unzip and select the .img)\n" +
                "rufus=unzip then DD Image mode on the .img\n",
            resolver,
        ) ?: return Result(false, "Cannot write CRYPT3X_ETCHER_READY.txt")

        onProgress(1.0, "Etcher/Rufus kit ready")
        return Result(
            ok = true,
            message =
                "Wrote $etcherFolder/$destFileName " +
                    "(${written / (1024L * 1024L)} MiB). SHA-256 verified. " +
                    "Eject, open ETCHER.txt or RUFUS.txt on a PC. " +
                    "The phone cannot write GPT to the R36S card.",
            portsPath = etcherFolder,
            verified = true,
            detail = "sha256=$hex bytes=$written file=$destFileName",
        )
    }

    private fun findCrypt3xParts(root: DocumentFile): List<DocumentFile>? {
        val files = ArrayList<DocumentFile>()
        collectFiles(root, files, depth = 0, maxDepth = 2)
        fun match(prefix: String): List<DocumentFile>? {
            val found = ArrayList<DocumentFile>(12)
            for (i in 0..11) {
                val want = prefix + i.toString().padStart(2, '0')
                val hit =
                    files.firstOrNull { doc ->
                        val n = doc.name ?: return@firstOrNull false
                        n == want || n.endsWith(want) || n.endsWith("/$want")
                    } ?: return null
                found.add(hit)
            }
            return found
        }
        return match(kitPartPrefix) ?: match(altPartPrefix)
    }

    private fun collectFiles(
        dir: DocumentFile,
        out: MutableList<DocumentFile>,
        depth: Int,
        maxDepth: Int,
    ) {
        for (child in dir.listFiles()) {
            if (child.isFile) {
                out.add(child)
            } else if (child.isDirectory && depth < maxDepth) {
                val name = child.name ?: continue
                if (name.startsWith(".")) continue
                collectFiles(child, out, depth + 1, maxDepth)
            }
        }
    }

    private fun renameAssembledZip(
        parent: DocumentFile,
        tmp: DocumentFile,
        destFileName: String,
        resolver: ContentResolver,
    ): Boolean {
        if (tmp.name == destFileName) return true
        parent.findFile(destFileName)?.delete()
        if (tmp.renameTo(destFileName)) return true
        val dest = parent.createFile("application/zip", destFileName) ?: return false
        return try {
            resolver.openInputStream(tmp.uri)?.use { input ->
                resolver.openOutputStream(dest.uri, "w")?.use { out ->
                    input.copyTo(out)
                    out.flush()
                } ?: return false
            } ?: return false
            tmp.delete()
            true
        } catch (_: Exception) {
            dest.delete()
            false
        }
    }

    private fun openSource(source: String): InputStream? {
        return if (source.startsWith("content:") || source.startsWith("file:")) {
            context.contentResolver.openInputStream(Uri.parse(source))
        } else {
            val f = File(source)
            if (f.isFile) FileInputStream(f) else null
        }
    }

    private fun sourceLength(source: String): Long {
        if (source.startsWith("content:") || source.startsWith("file:")) {
            val uri = Uri.parse(source)
            try {
                context.contentResolver.query(
                    uri,
                    arrayOf(OpenableColumns.SIZE),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val idx = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (idx >= 0) {
                            val n = cursor.getLong(idx)
                            if (n > 0L) return n
                        }
                    }
                }
            } catch (_: Exception) {
            }
            DocumentFile.fromSingleUri(context, uri)?.length()?.takeIf { it > 0L }?.let { return it }
            return -1L
        }
        val f = File(source)
        return if (f.isFile) f.length() else -1L
    }

    private fun crypt3xReadmeText(fileName: String, bytes: Long): String =
        """
        CRYPT3X OS LITE — staged image
        ==============================

        Prepared by PØLYBÎŪS FLASHER.

        This folder holds the official 8 GiB CRYPT3X OS lite GPT image
        (or its zip). It is NOT a PortMaster port. Copying these files
        onto an ArkOS/JELOS card will not boot CRYPT3X.

        ON A PC (required to flash the handheld):
        1. If you have the .img.zip, unzip it first.
        2. Identify the SD card device (lsblk / Disk Utility).
        3. Write the raw image:
              sudo dd if=$fileName of=/dev/sdX bs=4M status=progress conv=fsync
        4. Eject and boot the R36S from that card.

        FAT32 cannot store the raw 8 GiB .img (4 GiB file cap). Use exFAT
        for the raw image, or carry the 921 MiB .img.zip on FAT32.

        Source size: $bytes bytes
        File: $fileName
        """.trimIndent()

    private fun crypt3xFlashText(fileName: String): String {
        val rawName =
            if (fileName.endsWith(".zip")) {
                fileName.removeSuffix(".zip").removeSuffix(".img") + ".img"
            } else {
                fileName
            }
        val zipName = if (fileName.endsWith(".zip")) fileName else "$rawName.zip"
        return """
            # CRYPT3X OS LITE — flash the R36S SD
            # WARNING: this erases the target device.

            unzip -o $zipName   # skip if you already have the raw .img
            sudo dd if=$rawName of=/dev/sdX bs=4M status=progress conv=fsync
            sync

            Or from the repo:
              polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX
            """.trimIndent()
    }

    private data class ExtractResult(
        val ok: Boolean,
        val message: String = "",
        val fileCount: Int = 0,
    )

    private fun extractZipIntoPorts(
        zipFile: File,
        portsDir: DocumentFile,
        resolver: ContentResolver,
        progressStart: Double,
        progressEnd: Double,
    ): ExtractResult {
        onProgress(progressStart + 0.02, "Reading zip index…")
        val entries = ArrayList<Pair<String, Long>>()
        ZipInputStream(BufferedInputStream(FileInputStream(zipFile))).use { zin ->
            while (true) {
                if (cancel.get()) return ExtractResult(false, "Cancelled")
                val entry = zin.nextEntry ?: break
                if (!entry.isDirectory) {
                    val name = entry.name.replace('\\', '/')
                    val relative = when {
                        name.startsWith("ports/") -> name.removePrefix("ports/")
                        else -> name
                    }
                    if (relative.isNotBlank()) entries.add(relative to entry.size)
                }
                zin.closeEntry()
            }
        }
        if (entries.isEmpty()) return ExtractResult(false, "Zip has no files under ports/")

        val totalBytes = entries.sumOf { it.second.coerceAtLeast(0L) }.coerceAtLeast(1L)
        var written = 0L
        var fileCount = 0
        val span = (progressEnd - progressStart - 0.04).coerceAtLeast(0.01)

        ZipInputStream(BufferedInputStream(FileInputStream(zipFile))).use { zin ->
            while (true) {
                if (cancel.get()) return ExtractResult(false, "Cancelled")
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
                        ?: return ExtractResult(false, "Cannot create $relative")

                    resolver.openOutputStream(target.uri, "w")?.use { out ->
                        val buf = ByteArray(64 * 1024)
                        while (true) {
                            val n = zin.read(buf)
                            if (n <= 0) break
                            out.write(buf, 0, n)
                            written += n
                            onProgress(
                                (progressStart + 0.04 + span * (written.toDouble() / totalBytes))
                                    .coerceIn(progressStart, progressEnd),
                                "Writing $relative",
                            )
                        }
                        out.flush()
                    } ?: return ExtractResult(false, "Cannot write $relative")

                    fileCount++
                    if (fileCount % 5 == 0) onLog("Wrote $fileCount files…")
                } finally {
                    zin.closeEntry()
                }
            }
        }
        return ExtractResult(true, fileCount = fileCount)
    }

    private fun probeWritable(root: DocumentFile): Result {
        val probeName = ".polybius_usb_probe_${System.currentTimeMillis()}.tmp"
        return try {
            val probe = root.createFile("application/octet-stream", probeName)
                ?: return Result(false, "Write probe failed — is the stick FAT32/exFAT?")
            context.contentResolver.openOutputStream(probe.uri, "w")?.use { out ->
                out.write(byteArrayOf(0x50, 0x4F, 0x4C, 0x59))
            } ?: return Result(false, "Write probe failed — cannot open output stream")
            probe.delete()
            Result(true, "USB stick write probe OK")
        } catch (e: Exception) {
            Result(false, "Write probe failed: ${e.message}")
        }
    }

    private fun deleteTree(dir: DocumentFile) {
        for (child in dir.listFiles()) {
            if (child.isDirectory) deleteTree(child)
            child.delete()
        }
        dir.delete()
    }

    private fun writeTextFile(
        parent: DocumentFile,
        name: String,
        text: String,
        resolver: ContentResolver,
    ): DocumentFile? {
        parent.findFile(name)?.delete()
        val file = parent.createFile("text/plain", name) ?: return null
        resolver.openOutputStream(file.uri, "w")?.use { out ->
            out.write(text.toByteArray(Charsets.UTF_8))
        } ?: return null
        return file
    }

    private fun usbReadmeText(): String =
        """
        PØLYBÎŪS R36S — USB stick package
        =================================

        Prepared by PØLYBÎŪS FLASHER on your phone.

        ON THE R36S (after plugging this stick into OTG):
        1. Open the built-in file manager.
        2. Browse to this folder: POLYBIUS_R36S_USB/ports/
        3. Copy ALL contents to your SD card ports folder, for example:
              roms/ports/        (ArkOS / JELOS)
              roms2/ports/       (some ROCKNIX layouts)
              EASYROMS/ports/    (alternate firmwares)
        4. Optional — PortMaster autoinstall:
              Copy polybius-r36s-port.zip to roms/ports/autoinstall/
              OR PortMaster/autoinstall/ then reboot / launch PortMaster.
        5. Optional — see custom/ for any extra ROM you bundled.
        6. Launch **Polybius** from the Ports menu.

        Do NOT format this USB stick from the R36S unless you want to erase these files.
        Use a short OTG data cable or powered hub if copy fails.
        """.trimIndent()

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

        val zipSize = zipFile.length().coerceAtLeast(1L)
        onLog("Zip size ${zipSize / 1024} KiB — ensure the card has free space")

        onProgress(0.08, "Extracting port…")
        val extract = extractZipIntoPorts(zipFile, portsDir, resolver, progressStart = 0.08, progressEnd = 0.88)
        if (!extract.ok) return Result(false, extract.message)
        val fileCount = extract.fileCount

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
            name.endsWith(".img") -> "application/octet-stream"
            else -> "application/octet-stream"
        }
    }
}
