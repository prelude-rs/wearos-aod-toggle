package rs.prelude.aodtoggle.core

/** Ícone de relógio do texto curto: sólido quando ligado, esmaecido nos demais casos (spec R2, R3, R4, R7). */
enum class ClockIcon { SOLID, DIM }

/** Vista do texto curto da complication: texto literal do protocolo visual e ícone de relógio (spec R2, R3, R4, R7). */
data class ShortTextView(
    val text: String,
    val icon: ClockIcon,
)

/** Mapeia o estado do AOD para a vista do texto curto; os textos são literais do protocolo (spec R2, R3, R4, R7). */
fun shortTextViewOf(state: AodState): ShortTextView =
    when (state) {
        AodState.On -> ShortTextView("AOD", ClockIcon.SOLID)
        AodState.Off -> ShortTextView("OFF", ClockIcon.DIM)
        is AodState.Unavailable -> ShortTextView("---", ClockIcon.DIM)
    }
