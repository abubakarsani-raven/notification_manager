package com.example.notification_manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class NotificationWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val CHANNEL_ID = "notification_manager_channel"
        private const val ACTION_NOTIFICATION_TAP = "notification_tap"
        private const val ACTION_NOTIFICATION_ACTION = "notification_action"
    }

    override fun doWork(): Result {
        try {
            val id = inputData.getString("id") ?: return Result.failure()
            val title = inputData.getString("title") ?: return Result.failure()
            val body = inputData.getString("body") ?: return Result.failure()
            val actionsJson = inputData.getString("actions") ?: "[]"
            val payloadJson = inputData.getString("payload") ?: "{}"
            val badgeNumber = inputData.getInt("badgeNumber", 0)
            val isRepeating = inputData.getBoolean("isRepeating", false)
            val repeatInterval = inputData.getInt("repeatInterval", 0)

            // Create notification channel if needed
            createNotificationChannel()

            // Parse actions
            val actions = try {
                if (actionsJson != "[]") {
                    JSONObject(actionsJson).getJSONArray("actions").let { jsonArray ->
                        List(jsonArray.length()) { i ->
                            jsonArray.getJSONObject(i).let { obj ->
                                mapOf(
                                    "id" to obj.getString("id"),
                                    "title" to obj.getString("title"),
                                    "isDestructive" to obj.optBoolean("isDestructive", false)
                                )
                            }
                        }
                    }
                } else {
                    emptyList<Map<String, Any>>()
                }
            } catch (e: Exception) {
                emptyList<Map<String, Any>>()
            }

            // Parse payload
            val payload = try {
                if (payloadJson != "{}") {
                    JSONObject(payloadJson).toMap()
                } else {
                    emptyMap<String, Any>()
                }
            } catch (e: Exception) {
                emptyMap<String, Any>()
            }

            // Create notification
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)

            // Add tap intent
            val tapIntent = Intent(ACTION_NOTIFICATION_TAP).apply {
                putExtra("notification_id", id)
                if (payload.isNotEmpty()) {
                    putExtra("payload", JSONObject(payload).toString())
                }
            }
            val tapPendingIntent = PendingIntent.getBroadcast(
                context,
                id.hashCode(),
                tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.setContentIntent(tapPendingIntent)

            // Add action buttons
            actions.forEach { action ->
                val actionId = action["id"] as String
                val actionTitle = action["title"] as String
                val isDestructive = action["isDestructive"] as? Boolean ?: false

                val actionIntent = Intent(ACTION_NOTIFICATION_ACTION).apply {
                    putExtra("notification_id", id)
                    putExtra("action_id", actionId)
                }
                val actionPendingIntent = PendingIntent.getBroadcast(
                    context,
                    (id + actionId).hashCode(),
                    actionIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                builder.addAction(
                    if (isDestructive) android.R.drawable.ic_menu_delete else android.R.drawable.ic_menu_send,
                    actionTitle,
                    actionPendingIntent
                )
            }

            // Set badge number if provided
            if (badgeNumber > 0) {
                builder.setNumber(badgeNumber)
            }

            // Show notification
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(id.hashCode(), builder.build())

            // If repeating, schedule next notification
            if (isRepeating && repeatInterval > 0) {
                scheduleNextRepeatingNotification(id, title, body, actionsJson, payloadJson, badgeNumber, repeatInterval)
            }

            return Result.success()
        } catch (e: Exception) {
            return Result.failure()
        }
    }

    private fun scheduleNextRepeatingNotification(
        id: String,
        title: String,
        body: String,
        actionsJson: String,
        payloadJson: String,
        badgeNumber: Int,
        repeatIntervalSeconds: Int
    ) {
        try {
            val workData = Data.Builder()
                .putString("id", id)
                .putString("title", title)
                .putString("body", body)
                .putString("actions", actionsJson)
                .putString("payload", payloadJson)
                .putInt("badgeNumber", badgeNumber)
                .putBoolean("isRepeating", true)
                .putInt("repeatInterval", repeatIntervalSeconds)
                .build()

            val workRequest = OneTimeWorkRequestBuilder<NotificationWorker>()
                .setInputData(workData)
                .setInitialDelay(repeatIntervalSeconds.toLong(), TimeUnit.SECONDS)
                .addTag("notification_$id")
                .build()

            WorkManager.getInstance(context).enqueue(workRequest)

            // Update stored notification info
            val sharedPreferences = context.getSharedPreferences("notification_manager_prefs", Context.MODE_PRIVATE)
            val nextScheduledDate = System.currentTimeMillis() + (repeatIntervalSeconds * 1000L)
            
            val scheduledNotification = mapOf(
                "id" to id,
                "scheduledDate" to nextScheduledDate,
                "isRepeating" to true,
                "repeatInterval" to repeatIntervalSeconds,
                "request" to mapOf(
                    "id" to id,
                    "title" to title,
                    "body" to body,
                    "actions" to actionsJson,
                    "payload" to payloadJson,
                    "badgeNumber" to badgeNumber
                )
            )
            
            sharedPreferences.edit()
                .putString("scheduled_$id", JSONObject(scheduledNotification).toString())
                .apply()
        } catch (e: Exception) {
            // Handle scheduling error
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Notification Manager",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications from Flutter app"
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun JSONObject.toMap(): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        val keys = this.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key] = this.get(key)
        }
        return map
    }
} 