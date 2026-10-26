package rs.prelude.aodtoggle.trigger

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageView
import android.widget.Switch
import android.widget.TextView
import rs.prelude.aodtoggle.R
import rs.prelude.aodtoggle.complication.requestComplicationRefresh
import rs.prelude.aodtoggle.core.AodState
import rs.prelude.aodtoggle.core.presentationOf
import rs.prelude.aodtoggle.core.triggerViewOf
import rs.prelude.aodtoggle.system.AodImage
import rs.prelude.aodtoggle.system.aodToggle

/**
 * Activity de lançador (botão físico): alterna o AOD ao abrir e a cada nova abertura com ela no topo,
 * e mostra o estado com um interruptor. Fecha sozinha [AUTO_CLOSE_MS] depois de mostrar o estado; cada
 * alternância recomeça a contagem. Também sai com o botão ou deslizando.
 */
class TriggerActivity : Activity() {
    private lateinit var image: ImageView
    private lateinit var toggleSwitch: Switch
    private lateinit var label: TextView
    private val handler = Handler(Looper.getMainLooper())
    private val autoClose = Runnable { finish() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_trigger)
        image = findViewById(R.id.trigger_image)
        toggleSwitch = findViewById(R.id.trigger_switch)
        label = findViewById(R.id.trigger_label)
        // Clique (e não OnCheckedChangeListener): o render programático de isChecked não dispara alternância.
        toggleSwitch.setOnClickListener { toggleAndRender() }
        if (savedInstanceState == null) {
            toggleAndRender()
        } else {
            renderCurrent()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        toggleAndRender()
    }

    /** A plataforma mantém `noHistory` ao dormir: ao reacordar, só relê o estado (não alterna). */
    override fun onRestart() {
        super.onRestart()
        renderCurrent()
    }

    override fun onDestroy() {
        handler.removeCallbacks(autoClose)
        super.onDestroy()
    }

    private fun toggleAndRender() {
        render(aodToggle(this).toggle())
        requestComplicationRefresh(this)
    }

    private fun renderCurrent() {
        render(aodToggle(this).current())
    }

    private fun render(state: AodState) {
        val presentation = presentationOf(state)
        val view = triggerViewOf(state)
        image.setImageIcon(AodImage.icon(this, presentation))
        image.contentDescription = presentation.label
        // Sempre do estado relido: o Switch já inverteu sozinho no clique; escrita sem efeito volta ao real.
        toggleSwitch.isChecked = view.switchChecked
        toggleSwitch.isEnabled = view.switchEnabled
        label.text = presentation.label
        label.visibility = if (view.showLabel) View.VISIBLE else View.GONE
        scheduleAutoClose()
    }

    private fun scheduleAutoClose() {
        handler.removeCallbacks(autoClose)
        handler.postDelayed(autoClose, AUTO_CLOSE_MS)
    }

    private companion object {
        /** Tempo, em ms, para ver o novo estado antes de voltar ao mostrador. */
        const val AUTO_CLOSE_MS = 3_000L
    }
}
