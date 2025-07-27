import Flutter
import UIKit
import UserNotifications
import Foundation

public class NotificationManagerPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private var eventSink: FlutterEventSink?
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private let userDefaults = UserDefaults.standard
  private let duplicateKeyPrefix = "notification_duplicate_"
  private let scheduledKeyPrefix = "scheduled_notification_"
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "notification_manager", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "notification_manager_events", binaryMessenger: registrar.messenger())
    let instance = NotificationManagerPlugin()
    
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
    
    instance.methodChannel = channel
    instance.eventChannel = eventChannel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      initialize(result: result)
    case "requestPermissions":
      requestPermissions(result: result)
    case "areNotificationsEnabled":
      areNotificationsEnabled(result: result)
    case "showNotification":
      showNotification(call: call, result: result)
    case "scheduleNotification":
      scheduleNotification(call: call, result: result)
    case "getScheduledNotifications":
      getScheduledNotifications(result: result)
    case "updateScheduledNotification":
      updateScheduledNotification(call: call, result: result)
    case "cancelNotification":
      cancelNotification(call: call, result: result)
    case "cancelScheduledNotification":
      cancelScheduledNotification(call: call, result: result)
    case "cancelAllNotifications":
      cancelAllNotifications(result: result)
    case "cancelAllScheduledNotifications":
      cancelAllScheduledNotifications(result: result)
    case "getBadgeCount":
      getBadgeCount(result: result)
    case "setBadgeCount":
      setBadgeCount(call: call, result: result)
    case "clearBadgeCount":
      clearBadgeCount(result: result)
    case "isDuplicateNotification":
      isDuplicateNotification(call: call, result: result)
    case "clearNotificationHistory":
      clearNotificationHistory(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func initialize(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().delegate = self
    result(true)
  }
  
  private func requestPermissions(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }
  
  private func areNotificationsEnabled(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        result(settings.authorizationStatus == .authorized)
      }
    }
  }
  
  private func showNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let id = arguments["id"] as? String,
          let title = arguments["title"] as? String,
          let body = arguments["body"] as? String else {
      result(false)
      return
    }
    
    let actions = arguments["actions"] as? [[String: Any]] ?? []
    let payload = arguments["payload"] as? [String: Any]
    let category = arguments["category"] as? String ?? "default"
    let badgeNumber = arguments["badgeNumber"] as? Int
    let duplicateKey = arguments["duplicateKey"] as? String
    let duplicateWindow = arguments["duplicateWindow"] as? Int
    
    // Check for duplicates if duplicateKey is provided
    if let duplicateKey = duplicateKey {
      if isDuplicateNotificationInternal(duplicateKey: duplicateKey, timeWindow: duplicateWindow) {
        result(false)
        return
      }
      markNotificationAsSent(duplicateKey: duplicateKey)
    }
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    if let payload = payload {
      content.userInfo = payload
    }
    
    if let badgeNumber = badgeNumber {
      content.badge = NSNumber(value: badgeNumber)
    }
    
    // Create notification category with actions
    if !actions.isEmpty {
      var notificationActions: [UNNotificationAction] = []
      
      for actionData in actions {
        guard let actionId = actionData["id"] as? String,
              let actionTitle = actionData["title"] as? String else { continue }
        
        let isDestructive = actionData["isDestructive"] as? Bool ?? false
        let requiresAuthentication = actionData["requiresAuthentication"] as? Bool ?? false
        
        let action = UNNotificationAction(
          identifier: actionId,
          title: actionTitle,
          options: isDestructive ? [.destructive] : []
        )
        notificationActions.append(action)
      }
      
      let notificationCategory = UNNotificationCategory(
        identifier: category,
        actions: notificationActions,
        intentIdentifiers: [],
        options: []
      )
      
      UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
      content.categoryIdentifier = notificationCategory.identifier
    }
    
    // Create trigger (immediate)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    
    // Create request
    let request = UNNotificationRequest(
      identifier: id,
      content: content,
      trigger: trigger
    )
    
    // Schedule notification
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if error != nil {
          result(false)
        } else {
          result(true)
        }
      }
    }
  }
  
  private func scheduleNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let id = arguments["id"] as? String,
          let requestData = arguments["request"] as? [String: Any],
          let title = requestData["title"] as? String,
          let body = requestData["body"] as? String,
          let scheduledDate = arguments["scheduledDate"] as? Double else {
      result(false)
      return
    }
    
    let actions = requestData["actions"] as? [[String: Any]] ?? []
    let payload = requestData["payload"] as? [String: Any]
    let category = requestData["category"] as? String ?? "default"
    let badgeNumber = requestData["badgeNumber"] as? Int
    let isRepeating = arguments["isRepeating"] as? Bool ?? false
    let repeatInterval = arguments["repeatInterval"] as? Int
    
    // Calculate time interval
    let scheduledTime = Date(timeIntervalSince1970: scheduledDate / 1000.0)
    let timeInterval = scheduledTime.timeIntervalSinceNow
    
    if timeInterval <= 0 {
      result(false)
      return
    }
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    
    if let payload = payload {
      content.userInfo = payload
    }
    
    if let badgeNumber = badgeNumber {
      content.badge = NSNumber(value: badgeNumber)
    }
    
    // Create notification category with actions
    if !actions.isEmpty {
      var notificationActions: [UNNotificationAction] = []
      
      for actionData in actions {
        guard let actionId = actionData["id"] as? String,
              let actionTitle = actionData["title"] as? String else { continue }
        
        let isDestructive = actionData["isDestructive"] as? Bool ?? false
        
        let action = UNNotificationAction(
          identifier: actionId,
          title: actionTitle,
          options: isDestructive ? [.destructive] : []
        )
        notificationActions.append(action)
      }
      
      let notificationCategory = UNNotificationCategory(
        identifier: category,
        actions: notificationActions,
        intentIdentifiers: [],
        options: []
      )
      
      UNUserNotificationCenter.current().setNotificationCategories([notificationCategory])
      content.categoryIdentifier = notificationCategory.identifier
    }
    
    // Create trigger
    let trigger: UNNotificationTrigger
    if isRepeating, let repeatInterval = repeatInterval {
      trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(repeatInterval), repeats: true)
    } else {
      trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
    }
    
    // Create request
    let request = UNNotificationRequest(
      identifier: id,
      content: content,
      trigger: trigger
    )
    
    // Schedule notification
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if error != nil {
          result(false)
        } else {
          // Store scheduled notification info
          let scheduledNotification: [String: Any] = [
            "id": id,
            "scheduledDate": scheduledDate,
            "isRepeating": isRepeating,
            "repeatInterval": repeatInterval ?? 0,
            "request": requestData
          ]
          
          if let data = try? JSONSerialization.data(withJSONObject: scheduledNotification),
             let jsonString = String(data: data, encoding: .utf8) {
            self.userDefaults.set(jsonString, forKey: "\(self.scheduledKeyPrefix)\(id)")
          }
          
          result(true)
        }
      }
    }
  }
  
  private func getScheduledNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      var scheduledNotifications: [[String: Any]] = []
      
      for request in requests {
        if let scheduledData = self.userDefaults.string(forKey: "\(self.scheduledKeyPrefix)\(request.identifier)"),
           let data = scheduledData.data(using: .utf8),
           let notificationData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
          scheduledNotifications.append(notificationData)
        }
      }
      
      DispatchQueue.main.async {
        result(scheduledNotifications)
      }
    }
  }
  
  private func updateScheduledNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let id = arguments["id"] as? String else {
      result(false)
      return
    }
    
    // Cancel existing notification
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    
    // Schedule new notification with updated data
    scheduleNotification(call: call, result: result)
  }
  
  private func cancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let id = arguments["id"] as? String else {
      result(false)
      return
    }
    
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    result(true)
  }
  
  private func cancelScheduledNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let id = arguments["id"] as? String else {
      result(false)
      return
    }
    
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    userDefaults.removeObject(forKey: "\(scheduledKeyPrefix)\(id)")
    result(true)
  }
  
  private func cancelAllNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    result(true)
  }
  
  private func cancelAllScheduledNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    
    // Clear all scheduled notification data
    let allKeys = userDefaults.dictionaryRepresentation().keys
    for key in allKeys {
      if key.hasPrefix(scheduledKeyPrefix) {
        userDefaults.removeObject(forKey: key)
      }
    }
    
    result(true)
  }
  
  private func getBadgeCount(result: @escaping FlutterResult) {
    result(UIApplication.shared.applicationIconBadgeNumber)
  }
  
  private func setBadgeCount(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let count = arguments["count"] as? Int else {
      result(false)
      return
    }
    
    UIApplication.shared.applicationIconBadgeNumber = count
    result(true)
  }
  
  private func clearBadgeCount(result: @escaping FlutterResult) {
    UIApplication.shared.applicationIconBadgeNumber = 0
    result(true)
  }
  
  private func isDuplicateNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let duplicateKey = arguments["duplicateKey"] as? String else {
      result(false)
      return
    }
    
    let timeWindow = arguments["timeWindow"] as? Int
    let isDuplicate = isDuplicateNotificationInternal(duplicateKey: duplicateKey, timeWindow: timeWindow)
    result(isDuplicate)
  }
  
  private func clearNotificationHistory(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    
    // Clear all duplicate tracking data
    let allKeys = userDefaults.dictionaryRepresentation().keys
    for key in allKeys {
      if key.hasPrefix(duplicateKeyPrefix) {
        userDefaults.removeObject(forKey: key)
      }
    }
    
    result(true)
  }
  
  // MARK: - Helper Methods
  
  private func isDuplicateNotificationInternal(duplicateKey: String, timeWindow: Int?) -> Bool {
    let key = "\(duplicateKeyPrefix)\(duplicateKey)"
    let lastSentTime = userDefaults.double(forKey: key)
    
    if lastSentTime == 0 {
      return false
    }
    
    let currentTime = Date().timeIntervalSince1970
    let window = timeWindow ?? 300 // Default 5 minutes
    
    return (currentTime - lastSentTime) < Double(window)
  }
  
  private func markNotificationAsSent(duplicateKey: String) {
    let key = "\(duplicateKeyPrefix)\(duplicateKey)"
    userDefaults.set(Date().timeIntervalSince1970, forKey: key)
  }
  
  // MARK: - UNUserNotificationCenterDelegate
  
  public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }
  
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let notificationId = response.notification.request.identifier
    let userInfo = response.notification.request.content.userInfo
    
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      // Notification was tapped
      let event: [String: Any] = [
        "type": "tap",
        "notificationId": notificationId,
        "payload": userInfo
      ]
      eventSink?(event)
    } else {
      // Action button was tapped
      let event: [String: Any] = [
        "type": "action",
        "notificationId": notificationId,
        "actionId": response.actionIdentifier
      ]
      eventSink?(event)
    }
    
    completionHandler()
  }
}

// MARK: - FlutterStreamHandler

extension NotificationManagerPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
