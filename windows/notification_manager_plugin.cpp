#include "notification_manager_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <winrt/Windows.UI.Notifications.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.ApplicationModel.Activation.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>

#include <memory>
#include <sstream>
#include <string>
#include <map>

using namespace winrt::Windows::UI::Notifications;
using namespace winrt::Windows::Data::Xml::Dom;

namespace notification_manager {

// static
void NotificationManagerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "notification_manager",
          &flutter::StandardMethodCodec::GetInstance());

  auto eventChannel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "notification_manager_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NotificationManagerPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  eventChannel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [plugin_pointer = plugin.get()](
              const flutter::EncodableValue* arguments,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            plugin_pointer->OnListen(std::move(events));
            return nullptr;
          },
          [plugin_pointer = plugin.get()](const flutter::EncodableValue* arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            plugin_pointer->OnCancel();
            return nullptr;
          }));

  registrar->AddPlugin(std::move(plugin));
}

NotificationManagerPlugin::NotificationManagerPlugin() {
  // Initialize WinRT
  winrt::init_apartment();
}

NotificationManagerPlugin::~NotificationManagerPlugin() {}

void NotificationManagerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method_name = method_call.method_name();
  
  if (method_name == "initialize") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "requestPermissions") {
    // Windows 10+ doesn't require explicit permission for toast notifications
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "areNotificationsEnabled") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "showNotification") {
    ShowNotification(method_call, std::move(result));
  } else if (method_name == "cancelNotification") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(&method_call.arguments());
    if (arguments) {
      auto id_it = arguments->find(flutter::EncodableValue("id"));
      if (id_it != arguments->end()) {
        std::string id = std::get<std::string>(id_it->second);
        ToastNotificationManager::History().Remove(id);
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Success(flutter::EncodableValue(false));
      }
    } else {
      result->Success(flutter::EncodableValue(false));
    }
  } else if (method_name == "cancelAllNotifications") {
    ToastNotificationManager::History().Clear();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "getBadgeCount") {
    // Windows doesn't have a built-in badge count
    result->Success(flutter::EncodableValue(0));
  } else if (method_name == "setBadgeCount") {
    // Windows doesn't have a built-in badge count
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "clearBadgeCount") {
    // Windows doesn't have a built-in badge count
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

void NotificationManagerPlugin::ShowNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto* arguments = std::get_if<flutter::EncodableMap>(&method_call.arguments());
  if (!arguments) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  try {
    // Extract notification data
    std::string id = GetStringValue(*arguments, "id");
    std::string title = GetStringValue(*arguments, "title");
    std::string body = GetStringValue(*arguments, "body");
    
    // Create XML template
    std::wstring xml_template = L"<toast>";
    xml_template += L"<visual>";
    xml_template += L"<binding template='ToastGeneric'>";
    xml_template += L"<text id='1'>" + std::wstring(title.begin(), title.end()) + L"</text>";
    xml_template += L"<text id='2'>" + std::wstring(body.begin(), body.end()) + L"</text>";
    xml_template += L"</binding>";
    xml_template += L"</visual>";
    
    // Add actions if present
    auto actions_it = arguments->find(flutter::EncodableValue("actions"));
    if (actions_it != arguments->end()) {
      const auto* actions = std::get_if<flutter::EncodableList>(&actions_it->second);
      if (actions && !actions->empty()) {
        xml_template += L"<actions>";
        
        for (const auto& action : *actions) {
          const auto* action_map = std::get_if<flutter::EncodableMap>(&action);
          if (action_map) {
            std::string action_id = GetStringValue(*action_map, "id");
            std::string action_title = GetStringValue(*action_map, "title");
            bool is_destructive = GetBoolValue(*action_map, "isDestructive", false);
            
            xml_template += L"<action content='" + std::wstring(action_title.begin(), action_title.end()) + L"'";
            xml_template += L" arguments='action:" + std::wstring(action_id.begin(), action_id.end()) + L"'";
            if (is_destructive) {
              xml_template += L" activationType='background'";
            }
            xml_template += L"/>";
          }
        }
        
        xml_template += L"</actions>";
      }
    }
    
    xml_template += L"</toast>";
    
    // Create XML document
    XmlDocument doc;
    doc.LoadXml(xml_template);
    
    // Create toast notification
    ToastNotification toast(doc);
    
    // Set up activation event handler
    toast.Activated([this, id](const auto& sender, const ToastActivatedEventArgs& args) {
      std::string arguments = winrt::to_string(args.Arguments());
      
      flutter::EncodableMap event;
      event[flutter::EncodableValue("type")] = flutter::EncodableValue("tap");
      event[flutter::EncodableValue("notificationId")] = flutter::EncodableValue(id);
      
      if (event_sink_) {
        event_sink_->Success(flutter::EncodableValue(event));
      }
    });
    
    // Set up dismissed event handler
    toast.Dismissed([this, id](const auto& sender, const ToastDismissedEventArgs& args) {
      // Handle dismissal if needed
    });
    
    // Show the notification
    ToastNotificationManager::CreateToastNotifier().Show(toast);
    
    result->Success(flutter::EncodableValue(true));
    
  } catch (const std::exception& e) {
    result->Error("SHOW_NOTIFICATION_ERROR", e.what());
  }
}

std::string NotificationManagerPlugin::GetStringValue(
    const flutter::EncodableMap& map, const std::string& key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it != map.end()) {
    return std::get<std::string>(it->second);
  }
  return "";
}

bool NotificationManagerPlugin::GetBoolValue(
    const flutter::EncodableMap& map, const std::string& key, bool default_value) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it != map.end()) {
    return std::get<bool>(it->second);
  }
  return default_value;
}

void NotificationManagerPlugin::OnListen(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  event_sink_ = std::move(events);
}

void NotificationManagerPlugin::OnCancel() {
  event_sink_.reset();
}

}  // namespace notification_manager
