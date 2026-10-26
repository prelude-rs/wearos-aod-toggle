package rs.prelude.aodtoggle.core

import org.junit.Assert.assertEquals
import org.junit.Test

class ShortTextViewTest {
    @Test
    fun `ligado mostra AOD com icone solido`() {
        assertEquals(
            ShortTextView("AOD", ClockIcon.SOLID),
            shortTextViewOf(AodState.On),
        )
    }

    @Test
    fun `desligado mostra OFF com icone esmaecido`() {
        assertEquals(
            ShortTextView("OFF", ClockIcon.DIM),
            shortTextViewOf(AodState.Off),
        )
    }

    @Test
    fun `indisponivel por permissao mostra traco com icone esmaecido`() {
        assertEquals(
            ShortTextView("---", ClockIcon.DIM),
            shortTextViewOf(AodState.Unavailable(UnavailableReason.NO_PERMISSION)),
        )
    }

    @Test
    fun `indisponivel por chave ausente mostra traco com icone esmaecido`() {
        assertEquals(
            ShortTextView("---", ClockIcon.DIM),
            shortTextViewOf(AodState.Unavailable(UnavailableReason.KEY_MISSING)),
        )
    }
}
