package cc.floresta.aodtoggle.core

data class Presentation(
    val tintArgb: Int,
    val label: String,
)

private val AMBER = 0xFFFFC107.toInt()
private val WHITE = 0xFFFFFFFF.toInt()
private val GRAY = 0xFF757575.toInt()

fun presentationOf(state: AodState): Presentation =
    when (state) {
        AodState.On -> Presentation(AMBER, "AOD on")
        AodState.Off -> Presentation(WHITE, "AOD off")
        is AodState.Unavailable -> Presentation(GRAY, "AOD unavailable")
    }
