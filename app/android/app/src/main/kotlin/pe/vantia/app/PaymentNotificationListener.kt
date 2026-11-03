package pe.vantia.app

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.speech.tts.TextToSpeech
import org.json.JSONObject
import java.util.Locale

/**
 * F-71 / F-72: lee las notificaciones de Yape y de los bancos con Plin.
 *
 * - Encola el texto crudo para que Flutter lo parsee y registre el pago.
 * - Si hay un motor de Flutter vivo, lo envía al instante por EventChannel.
 * - Si el anuncio por voz está activo, lo anuncia con TextToSpeech nativo
 *   (funciona aunque la app esté cerrada).
 *
 * El sistema mantiene vinculado este servicio mientras el usuario conceda el
 * acceso a notificaciones; no requiere un servicio en primer plano.
 */
class PaymentNotificationListener : NotificationListenerService() {
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private val main = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        tts = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) tts?.language = Locale("es", "PE")
        }
    }

    override fun onDestroy() {
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!AutomationStore.isEnabled(this)) return
        if (sbn.packageName !in AutomationStore.PACKAGES) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (text.isBlank()) return

        val item = JSONObject()
            .put("package", sbn.packageName)
            .put("title", title)
            .put("text", text)
            .put("postedAt", sbn.postTime)

        val sink = NotificationBridge.eventSink
        if (sink != null) {
            main.post { sink.success(AutomationStore.toMap(item)) }
        } else {
            AutomationStore.enqueue(this, item)
        }

        if (AutomationStore.isVoiceEnabled(this)) announce(sbn.packageName, "$title $text")
    }

    private fun announce(pkg: String, content: String) {
        val phrase = SpeechText.build(pkg, content) ?: return
        if (ttsReady) tts?.speak(phrase, TextToSpeech.QUEUE_ADD, null, "vantia-${System.nanoTime()}")
    }
}

/** Frase a anunciar: "Yape: recibiste 10.50 soles de Juan P." */
object SpeechText {
    private val amount = Regex("""S/\.?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)""")
    private val name = Regex("""(?:Yape!\s*)?([^!\n]+?) te (?:envi[oó]|ha plineado|transfiri[oó])""", RegexOption.IGNORE_CASE)

    fun build(pkg: String, content: String): String? {
        val m = amount.find(content) ?: return null
        val label = if (pkg == "com.bcp.innovacxion.yapeapp") "Yape" else "Plin"
        val who = name.find(content)?.groupValues?.get(1)?.trim()
        val soles = m.groupValues[1].replace(",", "")
        return if (who.isNullOrBlank()) "$label: recibiste $soles soles"
        else "$label: recibiste $soles soles de $who"
    }
}
