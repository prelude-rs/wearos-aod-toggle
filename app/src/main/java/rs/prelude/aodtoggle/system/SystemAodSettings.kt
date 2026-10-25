package rs.prelude.aodtoggle.system

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import rs.prelude.aodtoggle.core.AodSettings
import rs.prelude.aodtoggle.core.AodToggle

private const val LOG_TAG = "AodToggle"
internal const val AOD_KEY = "ambient_enabled"

private fun logWarning(message: String) {
    Log.w(LOG_TAG, message)
}

/** Implementa o porto sobre `Settings.Global`; único lugar onde [AOD_KEY] aparece. */
class SystemAodSettings(
    context: Context,
    private val log: (String) -> Unit = ::logWarning,
) : AodSettings {
    private val context = context.applicationContext

    override fun hasWritePermission(): Boolean =
        context.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) ==
            PackageManager.PERMISSION_GRANTED

    override fun read(): Int? =
        try {
            Settings.Global.getInt(context.contentResolver, AOD_KEY)
        } catch (e: Settings.SettingNotFoundException) {
            log("leitura: chave $AOD_KEY ausente (${e.message})")
            null
        } catch (e: SecurityException) {
            log("leitura negada para $AOD_KEY (${e.message})")
            null
        }

    override fun write(value: Int) {
        try {
            Settings.Global.putInt(context.contentResolver, AOD_KEY, value)
        } catch (e: SecurityException) {
            log("escrita negada para $AOD_KEY (${e.message})")
        }
    }
}

/** Liga o núcleo ao sistema e ao logcat. */
fun aodToggle(context: Context): AodToggle = AodToggle(SystemAodSettings(context), ::logWarning)
