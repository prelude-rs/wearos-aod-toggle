package cc.floresta.aodtoggle.core

import org.junit.Assert.assertEquals
import org.junit.Test

class PresentationTest {
    @Test
    fun `ligado e ambar`() {
        assertEquals(Presentation(0xFFFFC107.toInt(), "AOD on"), presentationOf(AodState.On))
    }

    @Test
    fun `desligado e branco`() {
        assertEquals(Presentation(0xFFFFFFFF.toInt(), "AOD off"), presentationOf(AodState.Off))
    }

    @Test
    fun `indisponivel e cinza para qualquer motivo`() {
        val expected = Presentation(0xFF757575.toInt(), "AOD unavailable")
        UnavailableReason.entries.forEach {
            assertEquals(expected, presentationOf(AodState.Unavailable(it)))
        }
    }
}
