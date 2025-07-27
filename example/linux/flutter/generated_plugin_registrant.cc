//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <notification_manager/notification_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) notification_manager_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NotificationManagerPlugin");
  notification_manager_plugin_register_with_registrar(notification_manager_registrar);
}
