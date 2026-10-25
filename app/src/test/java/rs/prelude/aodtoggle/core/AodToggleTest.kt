package rs.prelude.aodtoggle.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AodToggleTest {
    private val logs = mutableListOf<String>()

    private fun toggleOf(settings: FakeAodSettings) = AodToggle(settings) { logs += it }

    @Test
    fun `sem permissao e indisponivel e nao le a chave`() {
        val settings = FakeAodSettings(permission = false, value = 1)
        assertEquals(AodState.Unavailable(UnavailableReason.NO_PERMISSION), toggleOf(settings).current())
        assertEquals(0, settings.readCount)
    }

    @Test
    fun `chave ausente e indisponivel`() {
        val settings = FakeAodSettings(value = null)
        assertEquals(AodState.Unavailable(UnavailableReason.KEY_MISSING), toggleOf(settings).current())
    }

    @Test
    fun `valor 1 e ligado`() {
        assertEquals(AodState.On, toggleOf(FakeAodSettings(value = 1)).current())
    }

    @Test
    fun `valor 0 e desligado`() {
        assertEquals(AodState.Off, toggleOf(FakeAodSettings(value = 0)).current())
    }

    @Test
    fun `outro valor e desligado`() {
        assertEquals(AodState.Off, toggleOf(FakeAodSettings(value = 2)).current())
    }

    @Test
    fun `toggle de ligado escreve 0 e devolve desligado`() {
        val settings = FakeAodSettings(value = 1)
        assertEquals(AodState.Off, toggleOf(settings).toggle())
        assertEquals(listOf(0), settings.writes)
    }

    @Test
    fun `toggle de desligado escreve 1 e devolve ligado`() {
        val settings = FakeAodSettings(value = 0)
        assertEquals(AodState.On, toggleOf(settings).toggle())
        assertEquals(listOf(1), settings.writes)
    }

    @Test
    fun `toggle sem permissao nao escreve`() {
        val settings = FakeAodSettings(permission = false, value = 1)
        assertEquals(AodState.Unavailable(UnavailableReason.NO_PERMISSION), toggleOf(settings).toggle())
        assertTrue(settings.writes.isEmpty())
    }

    @Test
    fun `toggle com chave ausente nao escreve`() {
        val settings = FakeAodSettings(value = null)
        assertEquals(AodState.Unavailable(UnavailableReason.KEY_MISSING), toggleOf(settings).toggle())
        assertTrue(settings.writes.isEmpty())
    }

    @Test
    fun `escrita sem efeito devolve estado relido e registra log`() {
        val settings = FakeAodSettings(value = 1, writeTakesEffect = false)
        assertEquals(AodState.On, toggleOf(settings).toggle())
        assertEquals(1, logs.size)
    }

    @Test
    fun `caminho feliz nao registra log`() {
        val settings = FakeAodSettings(value = 0)
        val toggle = toggleOf(settings)
        toggle.toggle()
        toggle.toggle()
        toggle.current()
        assertTrue(logs.isEmpty())
    }

    @Test
    fun `indisponivel por permissao registra um log por chamada de toggle`() {
        toggleOf(FakeAodSettings(permission = false)).toggle()
        assertEquals(1, logs.size)
    }

    @Test
    fun `indisponivel por chave ausente registra um log por chamada de toggle`() {
        toggleOf(FakeAodSettings(value = null)).toggle()
        assertEquals(1, logs.size)
    }

    @Test
    fun `current indisponivel registra log`() {
        toggleOf(FakeAodSettings(permission = false)).current()
        assertEquals(1, logs.size)
    }
}
