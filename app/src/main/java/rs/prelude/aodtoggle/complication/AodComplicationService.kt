package rs.prelude.aodtoggle.complication

import android.app.PendingIntent
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.MonochromaticImageComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageComplicationData
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import rs.prelude.aodtoggle.core.AodState
import rs.prelude.aodtoggle.core.TapAction
import rs.prelude.aodtoggle.core.monochromeFormOf
import rs.prelude.aodtoggle.core.presentationOf
import rs.prelude.aodtoggle.core.tapActionFor
import rs.prelude.aodtoggle.system.AodImage
import rs.prelude.aodtoggle.system.aodToggle

/**
 * Complication que mostra o estado atual do AOD, em `SMALL_IMAGE` (colorida) e `MONOCHROMATIC_IMAGE`
 * (branca, pintada pelo mostrador). O toque alterna o AOD quando disponível; quando indisponível só
 * redesenha (R6), via [ComplicationTapReceiver]. Os dois tipos usam o mesmo estado e o mesmo toque.
 */
class AodComplicationService : SuspendingComplicationDataSourceService() {
    // O tipo é decidido num ponto só, em `dataFor`; um tipo não declarado recebe null.
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? =
        aodToggle(this).current().let { state ->
            dataFor(request.complicationType, state, tapIntentFor(tapActionFor(state)))
        }

    // A prévia do seletor não lê as configurações: mostra sempre o estado desligado.
    override fun getPreviewData(type: ComplicationType): ComplicationData? = dataFor(type, AodState.Off, null)

    // Ação distinta por TapAction: os Intents não são filterEquals e os dois PendingIntents coexistem.
    private fun tapIntentFor(action: TapAction): PendingIntent =
        PendingIntent.getBroadcast(
            this,
            0,
            Intent(this, ComplicationTapReceiver::class.java).setAction(ComplicationTapReceiver.actionName(action)),
            PendingIntent.FLAG_IMMUTABLE,
        )

    private fun dataFor(
        type: ComplicationType,
        state: AodState,
        tapAction: PendingIntent?,
    ): ComplicationData? {
        val presentation = presentationOf(state)
        val description = PlainComplicationText.Builder(presentation.label).build()
        return when (type) {
            ComplicationType.MONOCHROMATIC_IMAGE ->
                MonochromaticImageComplicationData
                    .Builder(
                        MonochromaticImage.Builder(AodImage.monochromeIcon(this, monochromeFormOf(state))).build(),
                        description,
                    ).setTapAction(tapAction)
                    .build()

            ComplicationType.SMALL_IMAGE ->
                SmallImageComplicationData
                    .Builder(
                        SmallImage.Builder(AodImage.icon(this, presentation), SmallImageType.ICON).build(),
                        description,
                    ).setTapAction(tapAction)
                    .build()

            else -> null
        }
    }
}
