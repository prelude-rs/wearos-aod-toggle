package cc.floresta.aodtoggle.core

/** Fake do porto [AodSettings]; `writeTakesEffect = false` simula escrita sem efeito. */
class FakeAodSettings(
    var permission: Boolean = true,
    var value: Int? = 0,
    var writeTakesEffect: Boolean = true,
) : AodSettings {
    var readCount = 0
        private set
    val writes = mutableListOf<Int>()

    override fun hasWritePermission(): Boolean = permission

    override fun read(): Int? {
        readCount++
        return value
    }

    override fun write(value: Int) {
        writes += value
        if (writeTakesEffect) this.value = value
    }
}
