#include "include/notification_manager/notification_manager_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "notification_manager_plugin.h"

void NotificationManagerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  notification_manager::NotificationManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
