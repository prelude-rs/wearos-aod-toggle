package cc.floresta.aodtoggle.complication

import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageComplicationData
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import cc.floresta.aodtoggle.core.AodState
import cc.floresta.aodtoggle.core.presentationOf
import cc.floresta.aodtoggle.system.AodImage
import cc.floresta.aodtoggle.system.aodToggle

/** Complication `SMALL_IMAGE` que mostra o estado atual do AOD. O toque é adicionado na Task 6. */
class AodComplicationService : SuspendingComplicationDataSourceService() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? =
        if (request.complicationType == ComplicationType.SMALL_IMAGE) {
            dataFor(aodToggle(this).current())
        } else {
            null
        }

    // A prévia do seletor não lê as configurações: mostra sempre o estado desligado.
    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        if (type == ComplicationType.SMALL_IMAGE) dataFor(AodState.Off) else null

    private fun dataFor(state: AodState): ComplicationData {
        val presentation = presentationOf(state)
        return SmallImageComplicationData
            .Builder(
                SmallImage.Builder(AodImage.icon(this, presentation), SmallImageType.ICON).build(),
                PlainComplicationText.Builder(presentation.label).build(),
            ).build()
    }
}
