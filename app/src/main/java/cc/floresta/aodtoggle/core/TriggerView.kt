package cc.floresta.aodtoggle.core

data class TriggerView(
    val switchChecked: Boolean,
    val switchEnabled: Boolean,
    val showLabel: Boolean,
)

fun triggerViewOf(state: AodState): TriggerView =
    when (state) {
        AodState.On -> TriggerView(switchChecked = true, switchEnabled = true, showLabel = false)
        AodState.Off -> TriggerView(switchChecked = false, switchEnabled = true, showLabel = false)
        is AodState.Unavailable -> TriggerView(switchChecked = false, switchEnabled = false, showLabel = true)
    }
