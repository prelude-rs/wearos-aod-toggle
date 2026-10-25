package cc.floresta.aodtoggle.complication

import android.content.ComponentName
import android.content.Context
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester

/** Pede ao sistema que redesenhe todas as instâncias da complication do AOD. */
fun requestComplicationRefresh(context: Context) {
    ComplicationDataSourceUpdateRequester
        .create(context, ComponentName(context, AodComplicationService::class.java))
        .requestUpdateAll()
}
