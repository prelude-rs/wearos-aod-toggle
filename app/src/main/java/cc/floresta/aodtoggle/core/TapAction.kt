package cc.floresta.aodtoggle.core

/** O que o toque na complication faz, decidido pelo estado exibido (spec R6). */
enum class TapAction { TOGGLE, REFRESH }

fun tapActionFor(state: AodState): TapAction =
    when (state) {
        AodState.On, AodState.Off -> TapAction.TOGGLE
        is AodState.Unavailable -> TapAction.REFRESH
    }
