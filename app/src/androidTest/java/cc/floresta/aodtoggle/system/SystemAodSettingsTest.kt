package cc.floresta.aodtoggle.system

import android.Manifest
import android.content.Context
import android.os.ParcelFileDescriptor
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

class SystemAodSettingsTest {
    private lateinit var context: Context
    private lateinit var settings: SystemAodSettings
    private var original: Int? = null

    @Before
    fun grantAndSave() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        context = instrumentation.targetContext
        grant(context.packageName)
        settings = SystemAodSettings(context)
        original = settings.read()
    }

    @After
    fun restore() {
        // Restaura pelo próprio adaptador: usa o mesmo caminho que o app usa em produção.
        original?.let { settings.write(it) }
    }

    @Test
    fun withGrantTheAppCanReadAndWriteTheKey() {
        assertTrue("premise 1: hasWritePermission() false after grant", settings.hasWritePermission())

        val current = settings.read()
        assertNotNull("premise 1: read() returned null with grant", current)
        assertTrue("premise 1: read() = $current, expected 0 or 1", current == 0 || current == 1)

        val opposite = if (current == 1) 0 else 1
        settings.write(opposite)
        assertEquals("premise 1: write($opposite) not reflected by read()", opposite, settings.read())
    }

    private fun grant(packageName: String) {
        val command = "pm grant $packageName ${Manifest.permission.WRITE_SECURE_SETTINGS}"
        // Rwe devolve [stdout, stdin, stderr]; pm grant escreve falhas em stderr.
        val (stdout, stdin, stderr) =
            InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommandRwe(command)
        stdin.close()
        // Lê os dois fluxos até o EOF, fechando cada descritor uma única vez, antes de asserir.
        val out = ParcelFileDescriptor.AutoCloseInputStream(stdout).use { it.readBytes().decodeToString() }
        val err = ParcelFileDescriptor.AutoCloseInputStream(stderr).use { it.readBytes().decodeToString() }
        val output = (out + err).trim()
        if (output.isNotEmpty()) fail("harness: pm grant failed: $output")
    }
}
