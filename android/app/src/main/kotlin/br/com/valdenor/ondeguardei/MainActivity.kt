package br.com.valdenor.ondeguardei

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var exportPath: String? = null
    private val worker = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "br.com.valdenor.ondeguardei/files")
            .setMethodCallHandler { call, result ->
                if (pending != null) {
                    result.error("busy", "Já há uma seleção de arquivo aberta.", null)
                    return@setMethodCallHandler
                }
                try {
                    when (call.method) {
                        "dataDirectory" -> result.success(filesDir.absolutePath)
                        "exportBackup" -> {
                            val path = call.argument<String>("path") ?: error("Arquivo ausente")
                            val source = File(path).canonicalFile
                            require(source.path.startsWith(filesDir.canonicalPath + File.separator))
                            require(source.isFile)
                            pending = result
                            exportPath = path
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/json"
                                putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "Onde-Guardei.ondeguardei.json")
                            }
                            startActivityForResult(intent, 4781)
                        }
                        "importBackup" -> {
                            pending = result
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "*/*"
                            }
                            startActivityForResult(intent, 4782)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    pending = null
                    exportPath = null
                    result.error("files", "Não foi possível abrir o seletor de arquivos.", null)
                }
            }
    }

    @Deprecated("Android activity callback used by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 4781 && requestCode != 4782) return
        val reply = pending ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            exportPath = null
            reply.success(if (requestCode == 4781) false else null)
            return
        }
        val sourcePath = exportPath
        worker.execute {
            var imported: File? = null
            try {
                val value: Any = if (requestCode == 4781) {
                    requireNotNull(sourcePath)
                    contentResolver.openOutputStream(uri, "wt").use { output ->
                        requireNotNull(output)
                        File(sourcePath).inputStream().use { it.copyTo(output) }
                    }
                    true
                } else {
                    imported = File.createTempFile("onde-guardei-import-", ".json", cacheDir)
                    contentResolver.openInputStream(uri).use { input ->
                        requireNotNull(input)
                        imported!!.outputStream().use { output ->
                            val buffer = ByteArray(64 * 1024)
                            var total = 0L
                            while (true) {
                                val read = input.read(buffer)
                                if (read < 0) break
                                total += read
                                require(total <= 100L * 1024 * 1024) { "Backup muito grande" }
                                output.write(buffer, 0, read)
                            }
                        }
                    }
                    imported!!.absolutePath
                }
                runOnUiThread { pending = null; exportPath = null; reply.success(value) }
            } catch (e: Exception) {
                imported?.delete()
                runOnUiThread { pending = null; exportPath = null; reply.error("files", "Não foi possível copiar o backup.", null) }
            }
        }
    }
}
