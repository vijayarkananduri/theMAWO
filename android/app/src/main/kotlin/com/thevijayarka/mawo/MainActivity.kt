package com.thevijayarka.mawo

import android.app.AlarmManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "mawo/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isExactAlarmAllowed" -> {
                        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                                alarmManager.canScheduleExactAlarms()
                        )
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            startActivity(
                                Intent(
                                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    Uri.parse("package:$packageName")
                                )
                            )
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
