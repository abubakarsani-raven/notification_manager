#ifndef FLUTTER_PLUGIN_NOTIFICATION_MANAGER_PLUGIN_H_
#define FLUTTER_PLUGIN_NOTIFICATION_MANAGER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/event_channel.h>

#include <memory>
#include <string>

namespace notification_manager {

class NotificationManagerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NotificationManagerPlugin();

  virtual ~NotificationManagerPlugin();

  // Disallow copy and assign.
  NotificationManagerPlugin(const NotificationManagerPlugin&) = delete;
  NotificationManagerPlugin& operator=(const NotificationManagerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  void ShowNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::string GetStringValue(const flutter::EncodableMap& map, const std::string& key);
  bool GetBoolValue(const flutter::EncodableMap& map, const std::string& key, bool default_value = false);

  void OnListen(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events);
  void OnCancel();

  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

}  // namespace notification_manager

#endif  // FLUTTER_PLUGIN_NOTIFICATION_MANAGER_PLUGIN_H_
