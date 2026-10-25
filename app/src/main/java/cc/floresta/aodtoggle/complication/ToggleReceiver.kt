package cc.floresta.aodtoggle.complication

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import cc.floresta.aodtoggle.system.aodToggle

/** Recebe o toque na complication: alterna o AOD e pede o redesenho (também quando indisponível). */
class ToggleReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        aodToggle(context).toggle()
        requestComplicationRefresh(context)
    }
}
