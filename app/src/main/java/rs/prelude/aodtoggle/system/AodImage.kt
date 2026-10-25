package rs.prelude.aodtoggle.system

import android.content.Context
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.Icon
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import rs.prelude.aodtoggle.R
import rs.prelude.aodtoggle.core.Presentation

/** Lado, em px, do bitmap do "AOD": nítido num slot de complication (~110 px) e na tela do gatilho. */
const val AOD_IMAGE_SIZE_PX = 192

object AodImage {
    /**
     * Rasteriza `aod_text` com a cor de [presentation] já gravada nos pixels. O tint é aplicado a uma
     * cópia mutável via [PorterDuffColorFilter] (SRC_IN), sem tocar no drawable compartilhado, e não
     * depende de o mostrador respeitar `Icon.setTint`.
     */
    fun icon(
        context: Context,
        presentation: Presentation,
    ): Icon {
        val drawable =
            checkNotNull(ContextCompat.getDrawable(context, R.drawable.aod_text)) { "aod_text ausente" }
                .mutate()
        drawable.colorFilter = PorterDuffColorFilter(presentation.tintArgb, PorterDuff.Mode.SRC_IN)
        return Icon.createWithBitmap(drawable.toBitmap(AOD_IMAGE_SIZE_PX, AOD_IMAGE_SIZE_PX))
    }
}
