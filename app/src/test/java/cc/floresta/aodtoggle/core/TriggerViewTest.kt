package cc.floresta.aodtoggle.core

import org.junit.Assert.assertEquals
import org.junit.Test

class TriggerViewTest {
    @Test
    fun `ligado e marcado habilitado e sem texto`() {
        assertEquals(TriggerView(true, true, false), triggerViewOf(AodState.On))
    }

    @Test
    fun `desligado e desmarcado habilitado e sem texto`() {
        assertEquals(TriggerView(false, true, false), triggerViewOf(AodState.Off))
    }

    @Test
    fun `indisponivel e desmarcado desabilitado e com texto para qualquer motivo`() {
        val expected = TriggerView(false, false, true)
        UnavailableReason.entries.forEach {
            assertEquals(expected, triggerViewOf(AodState.Unavailable(it)))
        }
    }
}
