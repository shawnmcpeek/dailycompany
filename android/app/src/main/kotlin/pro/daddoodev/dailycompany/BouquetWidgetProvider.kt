package pro.daddoodev.dailycompany

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BouquetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val text = widgetData.getString("bouquet_text", "")?.trim().orEmpty()
        val empty = widgetData.getBoolean("bouquet_empty", true) || text.isEmpty()
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.bouquet_widget)
            views.setTextViewText(
                R.id.bouquet_label,
                if (empty) context.getString(R.string.bouquet_widget_empty_label)
                else context.getString(R.string.bouquet_widget_label),
            )
            views.setTextViewText(
                R.id.bouquet_text,
                if (empty) context.getString(R.string.bouquet_widget_empty)
                else text,
            )
            views.setOnClickPendingIntent(
                R.id.bouquet_widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
