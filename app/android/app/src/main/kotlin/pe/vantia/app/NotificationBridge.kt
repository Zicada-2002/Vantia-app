package pe.vantia.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** Canales entre Flutter y el listener de notificaciones (F-71, F-73). */
object NotificationBridge {
    private const val METHODS = "pe.vantia/automation"
    private const val EVENTS = "pe.vantia/automation/events"

    @Volatile
    var eventSink: EventChannel.EventSink? = null

    fun register(engine: FlutterEngine, ctx: Context) {
        val app = ctx.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, METHODS).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> result.success(isListenerEnabled(app))
                "openPermissionSettings" -> {
                    app.startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = app.getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(app.packageName))
                }
                "openBatterySettings" -> {
                    // Lista general de optimización (no requiere el permiso
                    // restringido REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    try {
                        app.startActivity(intent)
                    } catch (e: Exception) {
                        app.startActivity(
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                .setData(Uri.parse("package:${app.packageName}"))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    }
                    result.success(null)
                }
                "setConfig" -> {
                    AutomationStore.setConfig(
                        app,
                        call.argument<Boolean>("enabled") ?: false,
                        call.argument<Boolean>("voice") ?: true,
                    )
                    result.success(null)
                }
                "drainQueue" -> result.success(AutomationStore.drain(app))
                else -> result.notImplemented()
            }
        }
        EventChannel(engine.dartExecutor.binaryMessenger, EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    private fun isListenerEnabled(ctx: Context): Boolean {
        val flat = Settings.Secure.getString(ctx.contentResolver, "enabled_notification_listeners")
            ?: return false
        val me = ComponentName(ctx, PaymentNotificationListener::class.java)
        return flat.split(":").mapNotNull { ComponentName.unflattenFromString(it) }.any { it == me }
    }
}
