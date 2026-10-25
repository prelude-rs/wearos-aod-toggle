package cc.floresta.aodtoggle.trigger

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.Switch
import android.widget.TextView
import cc.floresta.aodtoggle.R
import cc.floresta.aodtoggle.complication.requestComplicationRefresh
import cc.floresta.aodtoggle.core.AodState
import cc.floresta.aodtoggle.core.presentationOf
import cc.floresta.aodtoggle.core.triggerViewOf
import cc.floresta.aodtoggle.system.AodImage
import cc.floresta.aodtoggle.system.aodToggle

/**
 * Activity de lançador (botão físico): alterna o AOD ao abrir e a cada nova abertura com ela no topo,
 * e mostra o estado com um interruptor. Não se fecha por tempo: sai com o botão ou deslizando.
 */
class TriggerActivity : Activity() {
    private lateinit var image: ImageView
    private lateinit var toggleSwitch: Switch
    private lateinit var label: TextView

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
            render(aodToggle(this).current())
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
        render(aodToggle(this).current())
    }

    private fun toggleAndRender() {
        render(aodToggle(this).toggle())
        requestComplicationRefresh(this)
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
    }
}
