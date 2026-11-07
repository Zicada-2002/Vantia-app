package pe.vantia.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Configuración y cola de notificaciones capturadas (F-71).
 *
 * La cola sobrevive aunque la app esté cerrada: Flutter la vacía al abrir
 * o volver a primer plano y registra los pagos.
 */
object AutomationStore {
    private const val PREFS = "vantia_automation"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_VOICE = "voice"
    private const val KEY_QUEUE = "queue"
    private const val MAX_QUEUE = 100

    /** Apps de las que se leen notificaciones (Yape y bancos con Plin). */
    val PACKAGES = setOf(
        "com.bcp.innovacxion.yapeapp",
        "pe.com.interbank.mobilebanking",
        "com.bbva.nxt_peru",
        "pe.com.scotiabank.blpm.android.client",
        "com.bcp.bank.bcp",
    )

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(ctx: Context) = prefs(ctx).getBoolean(KEY_ENABLED, false)
    fun isVoiceEnabled(ctx: Context) = prefs(ctx).getBoolean(KEY_VOICE, true)

    fun setConfig(ctx: Context, enabled: Boolean, voice: Boolean) {
        prefs(ctx).edit().putBoolean(KEY_ENABLED, enabled).putBoolean(KEY_VOICE, voice).apply()
    }

    @Synchronized
    fun enqueue(ctx: Context, item: JSONObject) {
        val queue = JSONArray(prefs(ctx).getString(KEY_QUEUE, "[]"))
        queue.put(item)
        val trimmed = JSONArray()
        val start = maxOf(0, queue.length() - MAX_QUEUE)
        for (i in start until queue.length()) trimmed.put(queue.get(i))
        prefs(ctx).edit().putString(KEY_QUEUE, trimmed.toString()).apply()
    }

    @Synchronized
    fun drain(ctx: Context): List<Map<String, Any>> {
        val queue = JSONArray(prefs(ctx).getString(KEY_QUEUE, "[]"))
        prefs(ctx).edit().putString(KEY_QUEUE, "[]").apply()
        return (0 until queue.length()).map { toMap(queue.getJSONObject(it)) }
    }

    fun toMap(o: JSONObject): Map<String, Any> = mapOf(
        "package" to o.optString("package"),
        "title" to o.optString("title"),
        "text" to o.optString("text"),
        "postedAt" to o.optLong("postedAt"),
    )
}
