package com.example.notification_manager

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/** NotificationManagerPlugin */
class NotificationManagerPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private lateinit var notificationManager: NotificationManager
  private lateinit var sharedPreferences: SharedPreferences
  private var eventSink: EventChannel.EventSink? = null

  companion object {
    private const val CHANNEL_ID = "notification_manager_channel"
    private const val CHANNEL_NAME = "Notification Manager"
    private const val CHANNEL_DESCRIPTION = "Notifications from Flutter app"
    private const val ACTION_NOTIFICATION_TAP = "notification_tap"
    private const val ACTION_NOTIFICATION_ACTION = "notification_action"
    private const val PREF_NAME = "notification_manager_prefs"
    private const val PREF_DUPLICATE_PREFIX = "duplicate_"
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    sharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "notification_manager")
    channel.setMethodCallHandler(this)
    
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "notification_manager_events")
    eventChannel.setStreamHandler(this)
    
    createNotificationChannel()
    registerBroadcastReceivers()
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> {
        result.success(true)
      }
      "requestPermissions" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          // For Android 13+, we need to request POST_NOTIFICATIONS permission
          val permission = android.Manifest.permission.POST_NOTIFICATIONS
          if (context.checkSelfPermission(permission) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            // Permission not granted, return false
            result.success(false)
          } else {
            result.success(true)
          }
        } else {
          // For older versions, notifications are enabled by default
          result.success(true)
        }
      }
      "areNotificationsEnabled" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          val permission = android.Manifest.permission.POST_NOTIFICATIONS
          val hasPermission = context.checkSelfPermission(permission) == android.content.pm.PackageManager.PERMISSION_GRANTED
          result.success(hasPermission)
        } else {
          // For older versions, assume notifications are enabled
          result.success(true)
        }
      }
      "showNotification" -> {
        val arguments = call.arguments as Map<*, *>
        showNotification(arguments, result)
      }
      "scheduleNotification" -> {
        val arguments = call.arguments as Map<*, *>
        scheduleNotification(arguments, result)
      }
      "getScheduledNotifications" -> {
        getScheduledNotifications(result)
      }
      "updateScheduledNotification" -> {
        val arguments = call.arguments as Map<*, *>
        updateScheduledNotification(arguments, result)
      }
      "cancelNotification" -> {
        val id = call.argument<String>("id")
        if (id != null) {
          notificationManager.cancel(id.hashCode())
          result.success(true)
        } else {
          result.success(false)
        }
      }
      "cancelScheduledNotification" -> {
        val id = call.argument<String>("id")
        if (id != null) {
          cancelScheduledNotification(id, result)
        } else {
          result.success(false)
        }
      }
      "cancelAllNotifications" -> {
        notificationManager.cancelAll()
        result.success(true)
      }
      "cancelAllScheduledNotifications" -> {
        cancelAllScheduledNotifications(result)
      }
      "getBadgeCount" -> {
        // Android doesn't have a built-in badge count, return 0
        result.success(0)
      }
      "setBadgeCount" -> {
        val count = call.argument<Int>("count") ?: 0
        // Android doesn't have a built-in badge count, just return success
        result.success(true)
      }
      "clearBadgeCount" -> {
        // Android doesn't have a built-in badge count, just return success
        result.success(true)
      }
      "isDuplicateNotification" -> {
        val duplicateKey = call.argument<String>("duplicateKey")
        val timeWindow = call.argument<Int>("timeWindow")
        if (duplicateKey != null) {
          val isDuplicate = checkDuplicateNotification(duplicateKey, timeWindow)
          result.success(isDuplicate)
        } else {
          result.success(false)
        }
      }
      "clearNotificationHistory" -> {
        clearNotificationHistory(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        CHANNEL_NAME,
        NotificationManager.IMPORTANCE_HIGH
      ).apply {
        description = CHANNEL_DESCRIPTION
        enableLights(true)
        enableVibration(true)
        setShowBadge(true)
        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        setSound(android.provider.Settings.System.DEFAULT_NOTIFICATION_URI, null)
      }
      notificationManager.createNotificationChannel(channel)
      android.util.Log.d("NotificationManager", "Notification channel created: $CHANNEL_ID with importance: ${channel.importance}")
    }
  }

  private fun registerBroadcastReceivers() {
    val tapFilter = IntentFilter(ACTION_NOTIFICATION_TAP)
    val actionFilter = IntentFilter(ACTION_NOTIFICATION_ACTION)
    
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      context.registerReceiver(notificationTapReceiver, tapFilter, Context.RECEIVER_NOT_EXPORTED)
      context.registerReceiver(notificationActionReceiver, actionFilter, Context.RECEIVER_NOT_EXPORTED)
    } else {
      context.registerReceiver(notificationTapReceiver, tapFilter)
      context.registerReceiver(notificationActionReceiver, actionFilter)
    }
  }

  private fun showNotification(arguments: Map<*, *>, result: Result) {
    try {
      // Debug: Log the arguments received
      android.util.Log.d("NotificationManager", "Received arguments: $arguments")
      
      // Extract fields from NotificationRequest structure
      val id = arguments["id"] as String
      val title = arguments["title"] as String
      val body = arguments["body"] as String
      val actions = arguments["actions"] as? List<Map<*, *>>
      val payload = arguments["payload"] as? Map<*, *>
      val badgeNumber = arguments["badgeNumber"] as? Int
      val duplicateKey = arguments["duplicateKey"] as? String
      val duplicateWindow = arguments["duplicateWindow"] as? Int

      // Check for duplicates if duplicateKey is provided
      if (duplicateKey != null) {
        val isDuplicate = checkDuplicateNotification(duplicateKey, duplicateWindow)
        if (isDuplicate) {
          result.success(false)
          return
        }
        // Mark this notification as sent
        markNotificationAsSent(duplicateKey)
      }

      // Ensure notification channel exists
      createNotificationChannel()

      val builder = NotificationCompat.Builder(context, CHANNEL_ID)
        .setContentTitle(title)
        .setContentText(body)
        .setSmallIcon(android.R.drawable.ic_dialog_info)
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .setAutoCancel(true)
        .setDefaults(NotificationCompat.DEFAULT_ALL)

      // Add tap intent
      val tapIntent = Intent(ACTION_NOTIFICATION_TAP).apply {
        putExtra("notification_id", id)
        if (payload != null) {
          putExtra("payload", JSONObject(payload as Map<String, Any>).toString())
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
      actions?.forEachIndexed { index, action ->
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
      if (badgeNumber != null && badgeNumber > 0) {
        builder.setNumber(badgeNumber)
      }

      val notification = builder.build()
      notificationManager.notify(id.hashCode(), notification)
      
      // Log for debugging
      android.util.Log.d("NotificationManager", "Notification sent: $id - $title")
      
      result.success(true)
    } catch (e: Exception) {
      android.util.Log.e("NotificationManager", "Error showing notification: ${e.message}")
      result.error("SHOW_NOTIFICATION_ERROR", e.message, null)
    }
  }

  private fun scheduleNotification(arguments: Map<*, *>, result: Result) {
    try {
      val id = arguments["id"] as String
      val request = arguments["request"] as Map<*, *>
      val scheduledDate = arguments["scheduledDate"] as Long
      val isRepeating = arguments["isRepeating"] as? Boolean ?: false
      val repeatInterval = arguments["repeatInterval"] as? Int

      val delayMillis = scheduledDate - System.currentTimeMillis()
      if (delayMillis <= 0) {
        result.success(false)
        return
      }

      // Create work data
      val workData = Data.Builder()
        .putString("id", id)
        .putString("title", request["title"] as String)
        .putString("body", request["body"] as String)
        .putString("actions", request["actions"]?.toString() ?: "[]")
        .putString("payload", request["payload"]?.toString() ?: "{}")
        .putInt("badgeNumber", request["badgeNumber"] as? Int ?: 0)
        .putBoolean("isRepeating", isRepeating)
        .putInt("repeatInterval", repeatInterval ?: 0)
        .build()

      // Create work request
      val workRequest = OneTimeWorkRequestBuilder<NotificationWorker>()
        .setInputData(workData)
        .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
        .addTag("notification_$id")
        .build()

      // Schedule the work
      WorkManager.getInstance(context).enqueue(workRequest)

      // Store scheduled notification info
      val scheduledNotification = mapOf(
        "id" to id,
        "scheduledDate" to scheduledDate,
        "isRepeating" to isRepeating,
        "repeatInterval" to repeatInterval,
        "request" to request
      )
      sharedPreferences.edit().putString("scheduled_$id", JSONObject(scheduledNotification).toString()).apply()

      result.success(true)
    } catch (e: Exception) {
      result.error("SCHEDULE_NOTIFICATION_ERROR", e.message, null)
    }
  }

  private fun getScheduledNotifications(result: Result) {
    try {
      val scheduledNotifications = mutableListOf<Map<String, Any>>()
      val allPrefs = sharedPreferences.all

      for ((key, value) in allPrefs) {
        if (key.startsWith("scheduled_")) {
          val notificationData = JSONObject(value.toString())
          scheduledNotifications.add(notificationData.toMap())
        }
      }

      result.success(scheduledNotifications)
    } catch (e: Exception) {
      result.error("GET_SCHEDULED_NOTIFICATIONS_ERROR", e.message, null)
    }
  }

  private fun updateScheduledNotification(arguments: Map<*, *>, result: Result) {
    try {
      val id = arguments["id"] as String
      val scheduledDate = arguments["scheduledDate"] as Long
      val isRepeating = arguments["isRepeating"] as? Boolean ?: false
      val repeatInterval = arguments["repeatInterval"] as? Int

      // Cancel existing scheduled notification
      WorkManager.getInstance(context).cancelAllWorkByTag("notification_$id")

      // Schedule updated notification
      val delayMillis = scheduledDate - System.currentTimeMillis()
      if (delayMillis > 0) {
        val workData = Data.Builder()
          .putString("id", id)
          .putLong("scheduledDate", scheduledDate)
          .putBoolean("isRepeating", isRepeating)
          .putInt("repeatInterval", repeatInterval ?: 0)
          .build()

        val workRequest = OneTimeWorkRequestBuilder<NotificationWorker>()
          .setInputData(workData)
          .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
          .addTag("notification_$id")
          .build()

        WorkManager.getInstance(context).enqueue(workRequest)

        // Update stored notification info
        val updatedNotification = mapOf(
          "id" to id,
          "scheduledDate" to scheduledDate,
          "isRepeating" to isRepeating,
          "repeatInterval" to repeatInterval
        )
        sharedPreferences.edit().putString("scheduled_$id", JSONObject(updatedNotification).toString()).apply()
      }

      result.success(true)
    } catch (e: Exception) {
      result.error("UPDATE_SCHEDULED_NOTIFICATION_ERROR", e.message, null)
    }
  }

  private fun cancelScheduledNotification(id: String, result: Result) {
    try {
      // Cancel work
      WorkManager.getInstance(context).cancelAllWorkByTag("notification_$id")
      
      // Remove from storage
      sharedPreferences.edit().remove("scheduled_$id").apply()
      
      result.success(true)
    } catch (e: Exception) {
      result.error("CANCEL_SCHEDULED_NOTIFICATION_ERROR", e.message, null)
    }
  }

  private fun cancelAllScheduledNotifications(result: Result) {
    try {
      // Cancel all scheduled work
      WorkManager.getInstance(context).cancelAllWork()
      
      // Clear all scheduled notifications from storage
      val allPrefs = sharedPreferences.all
      val editor = sharedPreferences.edit()
      for ((key, _) in allPrefs) {
        if (key.startsWith("scheduled_")) {
          editor.remove(key)
        }
      }
      editor.apply()
      
      result.success(true)
    } catch (e: Exception) {
      result.error("CANCEL_ALL_SCHEDULED_NOTIFICATIONS_ERROR", e.message, null)
    }
  }

  private fun checkDuplicateNotification(duplicateKey: String, timeWindowSeconds: Int?): Boolean {
    val key = PREF_DUPLICATE_PREFIX + duplicateKey
    val lastSentTime = sharedPreferences.getLong(key, 0)
    val currentTime = System.currentTimeMillis()
    val windowMillis = (timeWindowSeconds ?: 300) * 1000L // Default 5 minutes

    return (currentTime - lastSentTime) < windowMillis
  }

  private fun markNotificationAsSent(duplicateKey: String) {
    val key = PREF_DUPLICATE_PREFIX + duplicateKey
    sharedPreferences.edit().putLong(key, System.currentTimeMillis()).apply()
  }

  private fun clearNotificationHistory(result: Result) {
    try {
      // Clear all notifications
      notificationManager.cancelAll()
      
      // Clear duplicate tracking
      val allPrefs = sharedPreferences.all
      val editor = sharedPreferences.edit()
      for ((key, _) in allPrefs) {
        if (key.startsWith(PREF_DUPLICATE_PREFIX)) {
          editor.remove(key)
        }
      }
      editor.apply()
      
      result.success(true)
    } catch (e: Exception) {
      result.error("CLEAR_NOTIFICATION_HISTORY_ERROR", e.message, null)
    }
  }

  private val notificationTapReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
      val notificationId = intent?.getStringExtra("notification_id")
      val payloadString = intent?.getStringExtra("payload")
      
      val event = mapOf(
        "type" to "tap",
        "notificationId" to notificationId,
        "payload" to if (payloadString != null) JSONObject(payloadString).toMap() else null
      )
      
      eventSink?.success(event)
    }
  }

  private val notificationActionReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
      val notificationId = intent?.getStringExtra("notification_id")
      val actionId = intent?.getStringExtra("action_id")
      
      val event = mapOf(
        "type" to "action",
        "notificationId" to notificationId,
        "actionId" to actionId
      )
      
      eventSink?.success(event)
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    
    try {
      context.unregisterReceiver(notificationTapReceiver)
      context.unregisterReceiver(notificationActionReceiver)
    } catch (e: Exception) {
      // Receiver might not be registered
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
