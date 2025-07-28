package com.example.flutter_system_notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class FlutterSystemNotificationsBootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED || 
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            context?.let { ctx ->
                restoreScheduledNotifications(ctx)
            }
        }
    }
    
    private fun restoreScheduledNotifications(context: Context) {
        try {
            val sharedPreferences = context.getSharedPreferences("notification_manager_prefs", Context.MODE_PRIVATE)
            val allPrefs = sharedPreferences.all
            
            for ((key, value) in allPrefs) {
                if (key.startsWith("scheduled_")) {
                    try {
                        val notificationData = JSONObject(value.toString())
                        val id = notificationData.getString("id")
                        val scheduledDate = notificationData.getLong("scheduledDate")
                        val isRepeating = notificationData.optBoolean("isRepeating", false)
                        val repeatInterval = notificationData.optInt("repeatInterval", 0)
                        val request = notificationData.getJSONObject("request")
                        
                        val currentTime = System.currentTimeMillis()
                        val delayMillis = scheduledDate - currentTime
                        
                        // Only restore if the notification hasn't expired
                        if (delayMillis > 0) {
                            val workData = Data.Builder()
                                .putString("id", id)
                                .putString("title", request.getString("title"))
                                .putString("body", request.getString("body"))
                                .putString("actions", request.optString("actions", "[]"))
                                .putString("payload", request.optString("payload", "{}"))
                                .putInt("badgeNumber", request.optInt("badgeNumber", 0))
                                .putBoolean("isRepeating", isRepeating)
                                .putInt("repeatInterval", repeatInterval)
                                .build()
                            
                            val workRequest = OneTimeWorkRequestBuilder<FlutterSystemNotificationsWorker>()
                                .setInputData(workData)
                                .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
                                .addTag("notification_$id")
                                .build()
                            
                            WorkManager.getInstance(context).enqueue(workRequest)
                        } else {
                            // Remove expired notifications
                            sharedPreferences.edit().remove(key).apply()
                        }
                    } catch (e: Exception) {
                        // Remove corrupted data
                        sharedPreferences.edit().remove(key).apply()
                    }
                }
            }
        } catch (e: Exception) {
            // Handle any errors during restoration
        }
    }
} 