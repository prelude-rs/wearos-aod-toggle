package rs.prelude.aodtoggle.system

import android.content.Context
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.Icon
import androidx.annotation.DrawableRes
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import rs.prelude.aodtoggle.R
import rs.prelude.aodtoggle.core.ClockIcon
import rs.prelude.aodtoggle.core.MonochromeForm
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
    ): Icon = rasterize(context, R.drawable.aod_text, presentation.tintArgb)

    /**
     * Rasteriza a forma monocromática em branco puro (alfa preservado), para o mostrador pintar na cor
     * do tema. Bitmap, e não `Icon` de recurso, para não depender de o mostrador carregar um recurso de
     * outro pacote — a mesma razão do [icon].
     */
    fun monochromeIcon(
        context: Context,
        form: MonochromeForm,
    ): Icon =
        rasterize(
            context,
            when (form) {
                MonochromeForm.SOLID -> R.drawable.aod_text
                MonochromeForm.HOLLOW -> R.drawable.aod_mono_hollow
                MonochromeForm.STRUCK -> R.drawable.aod_mono_struck
            },
            tintArgb = null,
        )

    /** Rasteriza o relógio do texto curto em branco puro (alfa preservado), pela mesma razão do [monochromeIcon]. */
    fun clockIcon(
        context: Context,
        icon: ClockIcon,
    ): Icon =
        rasterize(
            context,
            when (icon) {
                ClockIcon.SOLID -> R.drawable.aod_clock
                ClockIcon.DIM -> R.drawable.aod_clock_dim
            },
            tintArgb = null,
        )

    private fun rasterize(
        context: Context,
        @DrawableRes resId: Int,
        tintArgb: Int?,
    ): Icon {
        val drawable =
            checkNotNull(ContextCompat.getDrawable(context, resId)) { "drawable $resId ausente" }.mutate()
        if (tintArgb != null) {
            drawable.colorFilter = PorterDuffColorFilter(tintArgb, PorterDuff.Mode.SRC_IN)
        }
        return Icon.createWithBitmap(drawable.toBitmap(AOD_IMAGE_SIZE_PX, AOD_IMAGE_SIZE_PX))
    }
}
