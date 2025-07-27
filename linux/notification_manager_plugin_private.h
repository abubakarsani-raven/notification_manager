#ifndef FLUTTER_PLUGIN_NOTIFICATION_MANAGER_PLUGIN_PRIVATE_H_
#define FLUTTER_PLUGIN_NOTIFICATION_MANAGER_PLUGIN_PRIVATE_H_

#include <flutter_linux/flutter_linux.h>

G_DECLARE_FINAL_TYPE(NotificationManagerPlugin, notification_manager_plugin,
                     NOTIFICATION_MANAGER, PLUGIN, GObject)

G_BEGIN_DECLS

FlMethodResponse* initialize_notification_manager();
FlMethodResponse* request_permissions();
FlMethodResponse* are_notifications_enabled();
FlMethodResponse* show_notification(NotificationManagerPlugin* self, FlMethodCall* method_call);
FlMethodResponse* schedule_notification(NotificationManagerPlugin* self, FlMethodCall* method_call);
FlMethodResponse* get_scheduled_notifications(NotificationManagerPlugin* self);
FlMethodResponse* update_scheduled_notification(NotificationManagerPlugin* self, FlMethodCall* method_call);
FlMethodResponse* cancel_notification(NotificationManagerPlugin* self, FlMethodCall* method_call);
FlMethodResponse* cancel_scheduled_notification(NotificationManagerPlugin* self, FlMethodCall* method_call);
FlMethodResponse* cancel_all_notifications(NotificationManagerPlugin* self);
FlMethodResponse* cancel_all_scheduled_notifications(NotificationManagerPlugin* self);
FlMethodResponse* get_badge_count();
FlMethodResponse* set_badge_count(FlMethodCall* method_call);
FlMethodResponse* clear_badge_count();
FlMethodResponse* is_duplicate_notification_method(NotificationManagerPlugin* self, FlMethodCall* method_call);
FlMethodResponse* clear_notification_history(NotificationManagerPlugin* self);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_NOTIFICATION_MANAGER_PLUGIN_PRIVATE_H_
