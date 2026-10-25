package rs.prelude.aodtoggle.core

/** Porto: o único ponto que toca o sistema. */
interface AodSettings {
    fun hasWritePermission(): Boolean

    /** `null` = chave ausente ou leitura negada. */
    fun read(): Int?

    fun write(value: Int)
}
