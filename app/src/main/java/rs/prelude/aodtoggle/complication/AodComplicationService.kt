package rs.prelude.aodtoggle.complication

import android.app.PendingIntent
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageComplicationData
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import rs.prelude.aodtoggle.core.AodState
import rs.prelude.aodtoggle.core.TapAction
import rs.prelude.aodtoggle.core.presentationOf
import rs.prelude.aodtoggle.core.tapActionFor
import rs.prelude.aodtoggle.system.AodImage
import rs.prelude.aodtoggle.system.aodToggle

/**
 * Complication `SMALL_IMAGE` que mostra o estado atual do AOD. O toque alterna o AOD quando disponível;
 * quando indisponível só redesenha (R6), via [ToggleReceiver].
 */
class AodComplicationService : SuspendingComplicationDataSourceService() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? =
        if (request.complicationType == ComplicationType.SMALL_IMAGE) {
            aodToggle(this).current().let { state -> dataFor(state, tapIntentFor(tapActionFor(state))) }
        } else {
            null
        }

    // A prévia do seletor não lê as configurações: mostra sempre o estado desligado.
    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        if (type == ComplicationType.SMALL_IMAGE) dataFor(AodState.Off, null) else null

    // Ação distinta por TapAction: os Intents não são filterEquals e os dois PendingIntents coexistem.
    private fun tapIntentFor(action: TapAction): PendingIntent =
        PendingIntent.getBroadcast(
            this,
            0,
            Intent(this, ToggleReceiver::class.java).setAction(ToggleReceiver.actionName(action)),
            PendingIntent.FLAG_IMMUTABLE,
        )

    private fun dataFor(
        state: AodState,
        tapAction: PendingIntent?,
    ): ComplicationData {
        val presentation = presentationOf(state)
        return SmallImageComplicationData
            .Builder(
                SmallImage.Builder(AodImage.icon(this, presentation), SmallImageType.ICON).build(),
                PlainComplicationText.Builder(presentation.label).build(),
            ).setTapAction(tapAction)
            .build()
    }
}
