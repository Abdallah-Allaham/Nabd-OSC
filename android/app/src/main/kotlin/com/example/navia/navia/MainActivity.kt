package com.navia.navia

import android.media.MediaPlayer
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val FEEDBACK_CHANNEL = "navia/feedback"
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ----- قناة الأصوات (feedback) -----
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FEEDBACK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playSuccessTone" -> playTone(R.raw.success_tone)
                    "playFailureTone" -> playTone(R.raw.failure_tone)
                    "playLoadingTone" -> playTone(R.raw.loading_tone)
                    // يمكنك إضافة المزيد هنا إذا أضفت أصوات ثانية
                    else -> result.notImplemented()
                }
            }

        // ----- قناة الملفات (saf_meta) -----
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "saf_meta")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMimeType" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr.isNullOrEmpty()) { result.error("ARG","uri missing",null); return@setMethodCallHandler }
                        val mime = contentResolver.getType(Uri.parse(uriStr)) ?: ""
                        result.success(mime)
                    }
                    "getFileSize" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr.isNullOrEmpty()) { result.error("ARG","uri missing",null); return@setMethodCallHandler }
                        try {
                            val size: Long? = if (uriStr.startsWith("content://")) {
                                contentResolver.query(
                                    Uri.parse(uriStr),
                                    arrayOf(OpenableColumns.SIZE),
                                    null, null, null
                                )?.use { c ->
                                    val idx = c.getColumnIndex(OpenableColumns.SIZE)
                                    if (idx != -1 && c.moveToFirst()) c.getLong(idx) else null
                                }
                            } else {
                                val f = File(uriStr)
                                if (f.exists()) f.length() else null
                            }
                            result.success(size ?: -1L)
                        } catch (e: Exception) {
                            result.error("SIZE", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // دالة تشغيل الصوت من ملفات raw
    private fun playTone(resId: Int) {
        mediaPlayer?.release()
        mediaPlayer = MediaPlayer.create(this, resId)
        mediaPlayer?.start()
    }
}
