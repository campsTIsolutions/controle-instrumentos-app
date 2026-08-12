package com.example.controle_instrumentos

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "camps/file_export"
        private const val REQUEST_WRITE_STORAGE = 9026
        private const val SUBDIRECTORY = "CAMPS"
        private const val LOCATION_LABEL = "Downloads/CAMPS"
    }

    private data class PendingSave(
        val fileName: String,
        val bytes: ByteArray,
        val mimeType: String,
        val result: MethodChannel.Result,
    )

    private var pendingSave: PendingSave? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> handleSave(call, result)
                    "openAppSettings" -> openApplicationSettings(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSave(call: MethodCall, result: MethodChannel.Result) {
        val requestedName = call.argument<String>("fileName")
        val bytes = call.argument<ByteArray>("bytes")
        val mimeType = call.argument<String>("mimeType")
            ?: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

        if (requestedName.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
            result.error("INVALID_ARGUMENTS", "Nome e conteúdo do arquivo são obrigatórios.", null)
            return
        }
        if (pendingSave != null) {
            result.error("EXPORT_IN_PROGRESS", "Já existe uma exportação em andamento.", null)
            return
        }

        val save = PendingSave(sanitizeFileName(requestedName), bytes, mimeType, result)
        if (
            Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            pendingSave = save
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                REQUEST_WRITE_STORAGE,
            )
            return
        }

        performSave(save)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_WRITE_STORAGE) return

        val save = pendingSave ?: return
        pendingSave = null
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            performSave(save)
        } else {
            save.result.error(
                "STORAGE_PERMISSION_DENIED",
                "Permissão de armazenamento negada.",
                null,
            )
        }
    }

    private fun performSave(save: PendingSave) {
        try {
            val saved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(save)
            } else {
                saveInLegacyDownloads(save)
            }
            save.result.success(saved)
        } catch (error: Exception) {
            save.result.error(
                "SAVE_FAILED",
                error.localizedMessage ?: "Não foi possível salvar o arquivo.",
                null,
            )
        }
    }

    private fun saveWithMediaStore(save: PendingSave): Map<String, String?> {
        val resolver = contentResolver
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/$SUBDIRECTORY/"
        val finalName = uniqueMediaStoreName(collection, relativePath, save.fileName)
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, finalName)
            put(MediaStore.Downloads.MIME_TYPE, save.mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("Não foi possível criar o arquivo em Downloads.")
        try {
            resolver.openOutputStream(uri, "w")?.use { stream ->
                stream.write(save.bytes)
                stream.flush()
            } ?: throw IllegalStateException("Não foi possível abrir o arquivo para gravação.")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return savedResult(finalName, uri.toString(), null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun uniqueMediaStoreName(
        collection: Uri,
        relativePath: String,
        requestedName: String,
    ): String {
        var candidate = requestedName
        var suffix = 1
        while (mediaStoreNameExists(collection, relativePath, candidate)) {
            candidate = withNumericSuffix(requestedName, suffix)
            suffix++
        }
        return candidate
    }

    private fun mediaStoreNameExists(
        collection: Uri,
        relativePath: String,
        fileName: String,
    ): Boolean {
        val selection =
            "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} = ?"
        return contentResolver.query(
            collection,
            arrayOf(MediaStore.Downloads._ID),
            selection,
            arrayOf(fileName, relativePath),
            null,
        )?.use { cursor -> cursor.moveToFirst() } ?: false
    }

    @Suppress("DEPRECATION")
    private fun saveInLegacyDownloads(save: PendingSave): Map<String, String?> {
        if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
            throw IllegalStateException("O armazenamento do aparelho não está disponível.")
        }
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val targetDirectory = File(downloads, SUBDIRECTORY)
        if (!targetDirectory.exists() && !targetDirectory.mkdirs()) {
            throw IllegalStateException("Não foi possível criar a pasta $LOCATION_LABEL.")
        }

        var target = File(targetDirectory, save.fileName)
        var suffix = 1
        while (target.exists()) {
            target = File(targetDirectory, withNumericSuffix(save.fileName, suffix))
            suffix++
        }
        FileOutputStream(target).use { stream ->
            stream.write(save.bytes)
            stream.flush()
            stream.fd.sync()
        }
        if (!target.exists() || target.length() != save.bytes.size.toLong()) {
            target.delete()
            throw IllegalStateException("O arquivo não foi gravado completamente.")
        }
        return savedResult(target.name, null, target.absolutePath)
    }

    private fun savedResult(
        fileName: String,
        uri: String?,
        path: String?,
    ): Map<String, String?> = mapOf(
        "fileName" to fileName,
        "location" to LOCATION_LABEL,
        "uri" to uri,
        "path" to path,
    )

    private fun withNumericSuffix(fileName: String, suffix: Int): String {
        val dot = fileName.lastIndexOf('.')
        return if (dot > 0) {
            "${fileName.substring(0, dot)} ($suffix)${fileName.substring(dot)}"
        } else {
            "$fileName ($suffix)"
        }
    }

    private fun sanitizeFileName(fileName: String): String {
        val sanitized = fileName.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim()
        if (sanitized.isEmpty()) throw IllegalArgumentException("Nome de arquivo inválido.")
        return sanitized
    }

    private fun openApplicationSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            startActivity(intent)
            result.success(true)
        } catch (error: Exception) {
            result.error("SETTINGS_FAILED", "Não foi possível abrir as configurações.", null)
        }
    }
}
