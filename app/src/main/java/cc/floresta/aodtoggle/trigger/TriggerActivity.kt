package cc.floresta.aodtoggle.trigger

import android.app.Activity
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import cc.floresta.aodtoggle.R
import cc.floresta.aodtoggle.complication.requestComplicationRefresh
import cc.floresta.aodtoggle.core.presentationOf
import cc.floresta.aodtoggle.system.AodImage
import cc.floresta.aodtoggle.system.aodToggle

/** Tempo, em ms, que o resultado fica na tela antes de a activity se fechar. */
const val CLOSE_DELAY_MS = 1000L

/** Activity de lançador (botão físico): alterna o AOD, mostra o resultado por 1 s e se fecha. */
class TriggerActivity : Activity() {
    private lateinit var root: View
    private val closeTask = Runnable { finish() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_trigger)
        root = findViewById(R.id.trigger_root)
        if (savedInstanceState == null) {
            val presentation = presentationOf(aodToggle(this).toggle())
            findViewById<ImageView>(R.id.trigger_image).apply {
                setImageIcon(AodImage.icon(this@TriggerActivity, presentation))
                contentDescription = presentation.label
            }
            findViewById<TextView>(R.id.trigger_label).text = presentation.label
            requestComplicationRefresh(this)
        }
        root.postDelayed(closeTask, CLOSE_DELAY_MS)
    }

    override fun onDestroy() {
        root.removeCallbacks(closeTask)
        super.onDestroy()
    }
}
