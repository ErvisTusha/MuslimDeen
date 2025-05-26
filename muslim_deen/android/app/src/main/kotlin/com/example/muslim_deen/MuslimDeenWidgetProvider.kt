package com.example.muslim_deen

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin

class MuslimDeenWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.muslim_deen_widget)
            
            // Set up click intent to open the app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            // Get data from SharedPreferences (set by Flutter)
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // Get theme mode from settings (respects user's theme choice)
            val themeMode = widgetData.getString("theme_mode", "system")
            val isDarkMode = when (themeMode) {
                "dark" -> true
                "light" -> false
                else -> { // "system" - follow device theme
                    val configuration = context.resources.configuration
                    val currentNightMode = configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
                    currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES
                }
            }
            
            // Apply theme-appropriate colors and backgrounds
            applyThemeColors(context, views, isDarkMode)
            
            // Update current prayer info
            views.setTextViewText(
                R.id.current_prayer_name, 
                widgetData.getString("current_prayer_name", "---")
            )
            views.setTextViewText(
                R.id.current_prayer_time, 
                widgetData.getString("current_prayer_time", "--:--")
            )
            
            // Update next prayer info
            views.setTextViewText(
                R.id.next_prayer_name, 
                widgetData.getString("next_prayer_name", "---")
            )
            views.setTextViewText(
                R.id.next_prayer_time, 
                widgetData.getString("next_prayer_time", "--:--")
            )
            
            // Update time remaining
            views.setTextViewText(
                R.id.time_remaining, 
                widgetData.getString("time_remaining", "--:--")
            )
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    
    private fun applyThemeColors(context: Context, views: RemoteViews, isDarkMode: Boolean) {
        try {
            if (isDarkMode) {
                // Dark theme - set background color dynamically
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#2D2D2D"))
                views.setInt(R.id.widget_content_container, "setBackgroundColor", Color.TRANSPARENT)
                
                // Dark theme text colors
                views.setTextColor(R.id.current_prayer_name, Color.parseColor("#66BB6A"))
                views.setTextColor(R.id.current_prayer_time, Color.parseColor("#FFFFFF"))
                views.setTextColor(R.id.next_prayer_name, Color.parseColor("#66BB6A"))
                views.setTextColor(R.id.next_prayer_time, Color.parseColor("#FFFFFF"))
                views.setTextColor(R.id.time_remaining, Color.parseColor("#66BB6A"))
                views.setTextColor(R.id.prayer_separator, Color.parseColor("#B0B0B0"))
            } else {
                // Light theme - set background color dynamically
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#F0F8F0"))
                views.setInt(R.id.widget_content_container, "setBackgroundColor", Color.TRANSPARENT)
                
                // Light theme text colors
                views.setTextColor(R.id.current_prayer_name, Color.parseColor("#4CAF50"))
                views.setTextColor(R.id.current_prayer_time, Color.parseColor("#000000"))
                views.setTextColor(R.id.next_prayer_name, Color.parseColor("#4CAF50"))
                views.setTextColor(R.id.next_prayer_time, Color.parseColor("#000000"))
                views.setTextColor(R.id.time_remaining, Color.parseColor("#4CAF50"))
                views.setTextColor(R.id.prayer_separator, Color.parseColor("#757575"))
            }
            
        } catch (e: Exception) {
            // Fallback to light theme colors if there's any issue
            views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#F0F8F0"))
            views.setTextColor(R.id.current_prayer_name, Color.parseColor("#4CAF50"))
            views.setTextColor(R.id.current_prayer_time, Color.parseColor("#000000"))
            views.setTextColor(R.id.next_prayer_name, Color.parseColor("#4CAF50"))
            views.setTextColor(R.id.next_prayer_time, Color.parseColor("#000000"))
            views.setTextColor(R.id.time_remaining, Color.parseColor("#4CAF50"))
            views.setTextColor(R.id.prayer_separator, Color.parseColor("#757575"))
        }
    }
}

class MuslimDeenWidgetProviderCurrentNext : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.muslim_deen_widget)
            
            // Set up click intent to open the app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            // Get data from SharedPreferences (set by Flutter)
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // Get theme mode from settings (respects user's theme choice)
            val themeMode = widgetData.getString("theme_mode", "system")
            val isDarkMode = when (themeMode) {
                "dark" -> true
                "light" -> false
                else -> { // "system" - follow device theme
                    val configuration = context.resources.configuration
                    val currentNightMode = configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
                    currentNightMode == android.content.res.Configuration.UI_MODE_NIGHT_YES
                }
            }
            
            // Apply theme-appropriate colors and backgrounds
            applyThemeColors(context, views, isDarkMode)
            
            // Update current prayer info
            views.setTextViewText(
                R.id.current_prayer_name, 
                widgetData.getString("current_prayer_name", "---")
            )
            views.setTextViewText(
                R.id.current_prayer_time, 
                widgetData.getString("current_prayer_time", "--:--")
            )
            
            // Update next prayer info
            views.setTextViewText(
                R.id.next_prayer_name, 
                widgetData.getString("next_prayer_name", "---")
            )
            views.setTextViewText(
                R.id.next_prayer_time, 
                widgetData.getString("next_prayer_time", "--:--")
            )
            
            // Update time remaining
            views.setTextViewText(
                R.id.time_remaining, 
                widgetData.getString("time_remaining", "--:--")
            )
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    
    private fun applyThemeColors(context: Context, views: RemoteViews, isDarkMode: Boolean) {
        try {
            if (isDarkMode) {
                // Dark theme - set background color dynamically
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#2D2D2D"))
                views.setInt(R.id.widget_content_container, "setBackgroundColor", Color.TRANSPARENT)
                
                // Dark theme text colors
                views.setTextColor(R.id.current_prayer_name, Color.parseColor("#66BB6A"))
                views.setTextColor(R.id.current_prayer_time, Color.parseColor("#FFFFFF"))
                views.setTextColor(R.id.next_prayer_name, Color.parseColor("#66BB6A"))
                views.setTextColor(R.id.next_prayer_time, Color.parseColor("#FFFFFF"))
                views.setTextColor(R.id.time_remaining, Color.parseColor("#66BB6A"))
                views.setTextColor(R.id.prayer_separator, Color.parseColor("#B0B0B0"))
            } else {
                // Light theme - set background color dynamically
                views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#F0F8F0"))
                views.setInt(R.id.widget_content_container, "setBackgroundColor", Color.TRANSPARENT)
                
                // Light theme text colors
                views.setTextColor(R.id.current_prayer_name, Color.parseColor("#4CAF50"))
                views.setTextColor(R.id.current_prayer_time, Color.parseColor("#000000"))
                views.setTextColor(R.id.next_prayer_name, Color.parseColor("#4CAF50"))
                views.setTextColor(R.id.next_prayer_time, Color.parseColor("#000000"))
                views.setTextColor(R.id.time_remaining, Color.parseColor("#4CAF50"))
                views.setTextColor(R.id.prayer_separator, Color.parseColor("#757575"))
            }
        } catch (e: Exception) {
            // Fallback to light theme colors if there's any issue
            views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#F0F8F0"))
            views.setTextColor(R.id.current_prayer_name, Color.parseColor("#4CAF50"))
            views.setTextColor(R.id.current_prayer_time, Color.parseColor("#000000"))
            views.setTextColor(R.id.next_prayer_name, Color.parseColor("#4CAF50"))
            views.setTextColor(R.id.next_prayer_time, Color.parseColor("#000000"))
            views.setTextColor(R.id.time_remaining, Color.parseColor("#4CAF50"))
            views.setTextColor(R.id.prayer_separator, Color.parseColor("#757575"))
        }
    }
} 