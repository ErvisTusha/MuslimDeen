package com.example.muslim_deen

import android.media.AudioManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ervis.muslimdeen/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRingerMode" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audioManager.ringerMode)
                }
                else -> result.notImplemented()
            }
        }
    }
}
