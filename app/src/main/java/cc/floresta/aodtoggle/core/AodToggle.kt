package cc.floresta.aodtoggle.core

/** Lê e alterna o estado do AOD; [log] é chamado só em falhas. */
class AodToggle(
    private val settings: AodSettings,
    private val log: (String) -> Unit,
) {
    fun current(): AodState {
        val state = readState()
        if (state is AodState.Unavailable) {
            log(
                when (state.reason) {
                    UnavailableReason.NO_PERMISSION -> "AOD indisponivel: sem permissao WRITE_SECURE_SETTINGS"
                    UnavailableReason.KEY_MISSING -> "AOD indisponivel: chave ausente ou leitura negada"
                },
            )
        }
        return state
    }

    private fun readState(): AodState {
        if (!settings.hasWritePermission()) return AodState.Unavailable(UnavailableReason.NO_PERMISSION)
        return when (settings.read()) {
            null -> AodState.Unavailable(UnavailableReason.KEY_MISSING)
            ON_VALUE -> AodState.On
            else -> AodState.Off
        }
    }

    fun toggle(): AodState {
        val before = current()
        if (before is AodState.Unavailable) return before
        settings.write(if (before == AodState.On) OFF_VALUE else ON_VALUE)
        val after = current()
        if (after == before) log("AOD: escrita sem efeito, estado continua $after")
        return after
    }

    private companion object {
        const val ON_VALUE = 1
        const val OFF_VALUE = 0
    }
}
