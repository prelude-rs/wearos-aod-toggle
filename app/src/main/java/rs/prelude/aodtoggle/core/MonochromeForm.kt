package rs.prelude.aodtoggle.core

/** Forma monocromática que representa o estado do AOD: sólido, vazado ou com tarja (spec R2, R3, R4). */
enum class MonochromeForm { SOLID, HOLLOW, STRUCK }

fun monochromeFormOf(state: AodState): MonochromeForm =
    when (state) {
        AodState.On -> MonochromeForm.SOLID
        AodState.Off -> MonochromeForm.HOLLOW
        is AodState.Unavailable -> MonochromeForm.STRUCK
    }
