package cc.floresta.aodtoggle.core

import org.junit.Assert.assertEquals
import org.junit.Test

class TapActionTest {
    @Test
    fun `ligado alterna`() {
        assertEquals(TapAction.TOGGLE, tapActionFor(AodState.On))
    }

    @Test
    fun `desligado alterna`() {
        assertEquals(TapAction.TOGGLE, tapActionFor(AodState.Off))
    }

    @Test
    fun `indisponivel por permissao so redesenha`() {
        assertEquals(TapAction.REFRESH, tapActionFor(AodState.Unavailable(UnavailableReason.NO_PERMISSION)))
    }

    @Test
    fun `indisponivel por chave ausente so redesenha`() {
        assertEquals(TapAction.REFRESH, tapActionFor(AodState.Unavailable(UnavailableReason.KEY_MISSING)))
    }
}
