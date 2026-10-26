package rs.prelude.aodtoggle.core

import org.junit.Assert.assertEquals
import org.junit.Test

class MonochromeFormTest {
    @Test
    fun `ligado e solido`() {
        assertEquals(MonochromeForm.SOLID, monochromeFormOf(AodState.On))
    }

    @Test
    fun `desligado e vazado`() {
        assertEquals(MonochromeForm.HOLLOW, monochromeFormOf(AodState.Off))
    }

    @Test
    fun `indisponivel por permissao e com tarja`() {
        assertEquals(
            MonochromeForm.STRUCK,
            monochromeFormOf(AodState.Unavailable(UnavailableReason.NO_PERMISSION)),
        )
    }

    @Test
    fun `indisponivel por chave ausente e com tarja`() {
        assertEquals(
            MonochromeForm.STRUCK,
            monochromeFormOf(AodState.Unavailable(UnavailableReason.KEY_MISSING)),
        )
    }
}
