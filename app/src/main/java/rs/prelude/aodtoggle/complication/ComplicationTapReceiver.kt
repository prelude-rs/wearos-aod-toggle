package rs.prelude.aodtoggle.complication

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import rs.prelude.aodtoggle.core.TapAction
import rs.prelude.aodtoggle.system.aodToggle

/**
 * Recebe o toque na complication. A ação vem do estado exibido ao montar o PendingIntent:
 * TOGGLE alterna e redesenha; REFRESH só redesenha (R6). Ação nula ou desconhecida: só redesenha (padrão seguro).
 */
class ComplicationTapReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action == actionName(TapAction.TOGGLE)) {
            aodToggle(context).toggle()
        }
        requestComplicationRefresh(context)
    }

    companion object {
        fun actionName(action: TapAction): String = "rs.prelude.aodtoggle.action.${action.name}"
    }
}
