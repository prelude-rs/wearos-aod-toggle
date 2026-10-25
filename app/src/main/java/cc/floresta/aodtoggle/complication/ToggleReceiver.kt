package cc.floresta.aodtoggle.complication

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import cc.floresta.aodtoggle.system.aodToggle

/** Recebe o toque na complication: alterna o AOD e pede o redesenho (também quando indisponível). */
class ToggleReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        aodToggle(context).toggle()
        ComplicationDataSourceUpdateRequester
            .create(context, ComponentName(context, AodComplicationService::class.java))
            .requestUpdateAll()
    }
}
