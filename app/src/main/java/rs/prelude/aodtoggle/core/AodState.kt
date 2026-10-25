package rs.prelude.aodtoggle.core

enum class UnavailableReason { NO_PERMISSION, KEY_MISSING }

sealed interface AodState {
    data object On : AodState

    data object Off : AodState

    data class Unavailable(
        val reason: UnavailableReason,
    ) : AodState
}
