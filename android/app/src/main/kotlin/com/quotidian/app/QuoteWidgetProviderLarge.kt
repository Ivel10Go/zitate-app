package com.quotidian.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.quotidian.app.R

class QuoteWidgetProviderLarge : AppWidgetProvider() {
  override fun onReceive(context: Context, intent: Intent) {
    Log.d(LOG_TAG, "onReceive called with action: ${intent.action}")
    super.onReceive(context, intent)
    if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
      Log.d(LOG_TAG, "Refreshing all large widgets")
      refreshAll(context)
    }
  }

  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
  ) {
    Log.d(LOG_TAG, "onUpdate called for ${appWidgetIds.size} large widgets")
    appWidgetIds.forEach { widgetId ->
      updateWidget(context, appWidgetManager, widgetId)
    }
  }

  override fun onAppWidgetOptionsChanged(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    newOptions: android.os.Bundle,
  ) {
    Log.d(LOG_TAG, "onAppWidgetOptionsChanged called for large widget $appWidgetId")
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    updateWidget(context, appWidgetManager, appWidgetId)
  }

  companion object {
    private const val LOG_TAG = "QuoteWidgetProviderLarge"

    fun refreshAll(context: Context) {
      Log.d(LOG_TAG, "refreshAll called")
      val manager = AppWidgetManager.getInstance(context)
      val componentName = ComponentName(context, QuoteWidgetProviderLarge::class.java)
      val ids = manager.getAppWidgetIds(componentName)
      Log.d(LOG_TAG, "Found ${ids.size} large widget instances to refresh")
      ids.forEach { id ->
        updateWidget(context, manager, id)
      }
    }

    private fun updateWidget(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
    ) {
      Log.d(LOG_TAG, "updateWidget called for large widget $appWidgetId")
      try {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val quoteText = prefs.getString("quote_text", "Tageszitat wird geladen …") ?: ""
        Log.d(LOG_TAG, "Loaded quote_text from SharedPreferences")
        val contentType = prefs.getString("content_type", "") ?: ""
        val storedAuthor = prefs.getString("quote_author", "") ?: ""
        val quoteAuthor = when (contentType) {
          "fact" -> "Geschichte"
          else -> storedAuthor
        }
        val layout = selectLayout(appWidgetManager, appWidgetId)
        Log.d(LOG_TAG, "Selected layout: ${layoutName(layout)} for large widget $appWidgetId")

        val views = RemoteViews(context.packageName, layout)

        // Only show quote and author.
        try {
          views.setTextViewText(R.id.quote_author, quoteAuthor)
          Log.d(LOG_TAG, "✓ Set author")
        } catch (e: Exception) {
          Log.w(LOG_TAG, "Failed to set author: ${e.message}")
        }

        try {
          views.setTextViewText(R.id.quote_text_italic, quoteText)
          views.setTextViewText(R.id.fact_text_normal, quoteText)
          views.setViewVisibility(R.id.quote_text_italic, View.VISIBLE)
          views.setViewVisibility(R.id.fact_text_normal, View.GONE)
          Log.d(LOG_TAG, "✓ Set quote text")
        } catch (e: Exception) {
          Log.w(LOG_TAG, "Failed to set quote text: ${e.message}")
        }

        val openIntent = Intent(context, MainActivity::class.java)
        openIntent.putExtra("launch_route", "/")
        val pendingIntent = PendingIntent.getActivity(
          context,
          appWidgetId,
          openIntent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        
        try {
          views.setOnClickPendingIntent(R.id.quote_root, pendingIntent)
          Log.d(LOG_TAG, "✓ Set click intent")
        } catch (e: Exception) {
          Log.w(LOG_TAG, "Failed to set click intent: ${e.message}")
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d(LOG_TAG, "✓ Widget $appWidgetId successfully updated")
      } catch (e: Exception) {
        Log.e(LOG_TAG, "Widget render failed for id=$appWidgetId", e)
        val fallbackViews = RemoteViews(context.packageName, R.layout.quote_widget_compat)
        fallbackViews.setTextViewText(R.id.quote_text_italic, "Widget wird vorbereitet …")
        fallbackViews.setViewVisibility(R.id.fact_text_normal, View.GONE)
        fallbackViews.setTextViewText(R.id.quote_author, "")
        val fallbackIntent = Intent(context, MainActivity::class.java)
        fallbackIntent.putExtra("launch_route", "/")
        val fallbackPendingIntent = PendingIntent.getActivity(
          context,
          appWidgetId,
          fallbackIntent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        fallbackViews.setOnClickPendingIntent(R.id.quote_root, fallbackPendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
        Log.d(LOG_TAG, "Widget $appWidgetId updated with fallback layout")
      }
    }

    private fun selectLayout(
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
    ): Int {
      return try {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

        Log.d(LOG_TAG, "Widget size: ${minWidth}x${minHeight}dp")

        when {
          minWidth >= 280 || minHeight >= 180 -> R.layout.quote_widget_large_new
          minWidth >= 240 || minHeight >= 160 -> R.layout.quote_widget_modern
          minWidth >= 180 || minHeight >= 120 -> R.layout.quote_widget_medium_new
          else -> R.layout.quote_widget_small_new
        }
      } catch (e: Exception) {
        Log.w(LOG_TAG, "Failed to get widget options, using default layout: ${e.message}")
        R.layout.quote_widget_large_new
      }
    }

    private fun layoutName(layoutId: Int): String {
      return when (layoutId) {
        R.layout.quote_widget_large_new -> "quote_widget_large_new"
        R.layout.quote_widget_modern -> "quote_widget_modern"
        R.layout.quote_widget_medium_new -> "quote_widget_medium_new"
        R.layout.quote_widget_small_new -> "quote_widget_small_new"
        R.layout.quote_widget_v2 -> "quote_widget_v2"
        R.layout.quote_widget_large -> "quote_widget_large"
        R.layout.quote_widget_compat -> "quote_widget_compat"
        else -> "unknown_layout_$layoutId"
      }
    }
  }
}
