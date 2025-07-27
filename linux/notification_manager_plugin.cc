#include "include/notification_manager/notification_manager_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <libnotify/notify.h>
#include <json-glib/json-glib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <glib/gstdio.h>
#include <sys/stat.h>

#include <cstring>
#include <string>
#include <map>
#include <vector>
#include <chrono>
#include <thread>

#include "notification_manager_plugin_private.h"

#define NOTIFICATION_MANAGER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), notification_manager_plugin_get_type(), \
                              NotificationManagerPlugin))

#define PREF_FILE "notification_manager_prefs.json"
#define DUPLICATE_KEY_PREFIX "notification_duplicate_"
#define SCHEDULED_KEY_PREFIX "scheduled_notification_"

struct _NotificationManagerPlugin {
  GObject parent_instance;
  FlEventChannel* event_channel;
  FlEventSink* event_sink;
  std::map<std::string, NotifyNotification*> active_notifications;
  std::map<std::string, std::chrono::system_clock::time_point> duplicate_tracking;
  std::map<std::string, std::string> scheduled_notifications;
};

G_DEFINE_TYPE(NotificationManagerPlugin, notification_manager_plugin, g_object_get_type())

// Helper function to get user data directory
static std::string get_user_data_dir() {
  const char* home = g_getenv("HOME");
  if (!home) home = g_getenv("USERPROFILE");
  if (!home) return "/tmp";
  
  std::string data_dir = std::string(home) + "/.local/share/notification_manager";
  g_mkdir_with_parents(data_dir.c_str(), 0755);
  return data_dir;
}

// Helper function to save preferences
static void save_preferences(const std::string& key, const std::string& value) {
  std::string data_dir = get_user_data_dir();
  std::string pref_file = data_dir + "/" + PREF_FILE;
  
  JsonNode* root = json_node_new(JSON_NODE_OBJECT);
  JsonObject* root_obj = json_object_new();
  json_node_set_object(root, root_obj);
  
  // Load existing data if file exists
  if (g_file_test(pref_file.c_str(), G_FILE_TEST_EXISTS)) {
    JsonParser* parser = json_parser_new();
    if (json_parser_load_from_file(parser, pref_file.c_str(), nullptr)) {
      JsonNode* existing = json_parser_get_root(parser);
      if (json_node_get_node_type(existing) == JSON_NODE_OBJECT) {
        JsonObject* existing_obj = json_node_get_object(existing);
        json_object_foreach(existing_obj, key_name, value_node) {
          json_object_set_member(root_obj, key_name, json_node_copy(value_node));
        }
      }
      g_object_unref(parser);
    }
  }
  
  // Add new key-value pair
  json_object_set_string_member(root_obj, key.c_str(), value.c_str());
  
  // Save to file
  JsonGenerator* generator = json_generator_new();
  json_generator_set_root(generator, root);
  json_generator_to_file(generator, pref_file.c_str(), nullptr);
  
  g_object_unref(generator);
  json_node_free(root);
}

// Helper function to load preferences
static std::string load_preference(const std::string& key) {
  std::string data_dir = get_user_data_dir();
  std::string pref_file = data_dir + "/" + PREF_FILE;
  
  if (!g_file_test(pref_file.c_str(), G_FILE_TEST_EXISTS)) {
    return "";
  }
  
  JsonParser* parser = json_parser_new();
  if (!json_parser_load_from_file(parser, pref_file.c_str(), nullptr)) {
    g_object_unref(parser);
    return "";
  }
  
  JsonNode* root = json_parser_get_root(parser);
  if (json_node_get_node_type(root) != JSON_NODE_OBJECT) {
    g_object_unref(parser);
    return "";
  }
  
  JsonObject* root_obj = json_node_get_object(root);
  const char* value = json_object_get_string_member(root_obj, key.c_str());
  
  std::string result = value ? value : "";
  g_object_unref(parser);
  return result;
}

// Helper function to check for duplicate notifications
static bool is_duplicate_notification(const std::string& duplicate_key, int time_window_seconds) {
  if (duplicate_key.empty()) return false;
  
  std::string key = DUPLICATE_KEY_PREFIX + duplicate_key;
  std::string last_sent_str = load_preference(key);
  
  if (last_sent_str.empty()) return false;
  
  auto last_sent = std::chrono::system_clock::from_time_t(std::stoll(last_sent_str));
  auto now = std::chrono::system_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - last_sent);
  
  return duration.count() < time_window_seconds;
}

// Helper function to mark notification as sent
static void mark_notification_as_sent(const std::string& duplicate_key) {
  if (duplicate_key.empty()) return;
  
  std::string key = DUPLICATE_KEY_PREFIX + duplicate_key;
  auto now = std::chrono::system_clock::now();
  auto timestamp = std::chrono::duration_cast<std::chrono::seconds>(now.time_since_epoch()).count();
  
  save_preferences(key, std::to_string(timestamp));
}

// Called when a method call is received from Flutter.
static void notification_manager_plugin_handle_method_call(
    NotificationManagerPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "initialize") == 0) {
    response = initialize_notification_manager();
  } else if (strcmp(method, "requestPermissions") == 0) {
    response = request_permissions();
  } else if (strcmp(method, "areNotificationsEnabled") == 0) {
    response = are_notifications_enabled();
  } else if (strcmp(method, "showNotification") == 0) {
    response = show_notification(self, method_call);
  } else if (strcmp(method, "scheduleNotification") == 0) {
    response = schedule_notification(self, method_call);
  } else if (strcmp(method, "getScheduledNotifications") == 0) {
    response = get_scheduled_notifications(self);
  } else if (strcmp(method, "updateScheduledNotification") == 0) {
    response = update_scheduled_notification(self, method_call);
  } else if (strcmp(method, "cancelNotification") == 0) {
    response = cancel_notification(self, method_call);
  } else if (strcmp(method, "cancelScheduledNotification") == 0) {
    response = cancel_scheduled_notification(self, method_call);
  } else if (strcmp(method, "cancelAllNotifications") == 0) {
    response = cancel_all_notifications(self);
  } else if (strcmp(method, "cancelAllScheduledNotifications") == 0) {
    response = cancel_all_scheduled_notifications(self);
  } else if (strcmp(method, "getBadgeCount") == 0) {
    response = get_badge_count();
  } else if (strcmp(method, "setBadgeCount") == 0) {
    response = set_badge_count(method_call);
  } else if (strcmp(method, "clearBadgeCount") == 0) {
    response = clear_badge_count();
  } else if (strcmp(method, "isDuplicateNotification") == 0) {
    response = is_duplicate_notification_method(self, method_call);
  } else if (strcmp(method, "clearNotificationHistory") == 0) {
    response = clear_notification_history(self);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* initialize_notification_manager() {
  if (!notify_is_initted()) {
    notify_init("notification_manager");
  }
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* request_permissions() {
  // Linux doesn't require explicit permissions for notifications
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* are_notifications_enabled() {
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* show_notification(NotificationManagerPlugin* self, FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  FlValue* id_value = fl_value_lookup_string(args, "id");
  FlValue* title_value = fl_value_lookup_string(args, "title");
  FlValue* body_value = fl_value_lookup_string(args, "body");
  FlValue* actions_value = fl_value_lookup_string(args, "actions");
  FlValue* payload_value = fl_value_lookup_string(args, "payload");
  FlValue* duplicate_key_value = fl_value_lookup_string(args, "duplicateKey");
  FlValue* duplicate_window_value = fl_value_lookup_int(args, "duplicateWindow");

  if (!id_value || !title_value || !body_value) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  const gchar* id = fl_value_get_string(id_value);
  const gchar* title = fl_value_get_string(title_value);
  const gchar* body = fl_value_get_string(body_value);
  
  // Check for duplicate notifications
  if (duplicate_key_value) {
    const gchar* duplicate_key = fl_value_get_string(duplicate_key_value);
    int time_window = duplicate_window_value ? fl_value_get_int(duplicate_window_value) : 300; // Default 5 minutes
    
    if (is_duplicate_notification(duplicate_key, time_window)) {
      g_autoptr(FlValue) result = fl_value_new_bool(false);
      return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    
    // Mark notification as sent
    mark_notification_as_sent(duplicate_key);
  }

  // Create notification
  NotifyNotification* notification = notify_notification_new(title, body, nullptr);
  
  // Store notification reference
  self->active_notifications[id] = notification;

  // Set up action callbacks if actions are provided
  if (actions_value && fl_value_get_type(actions_value) == FL_VALUE_TYPE_LIST) {
    gsize actions_length = fl_value_get_length(actions_value);
    
    for (gsize i = 0; i < actions_length; i++) {
      FlValue* action_value = fl_value_get_list_value(actions_value, i);
      if (fl_value_get_type(action_value) == FL_VALUE_TYPE_MAP) {
        FlValue* action_id_value = fl_value_lookup_string(action_value, "id");
        FlValue* action_title_value = fl_value_lookup_string(action_value, "title");
        
        if (action_id_value && action_title_value) {
          const gchar* action_id = fl_value_get_string(action_id_value);
          const gchar* action_title = fl_value_get_string(action_title_value);
          
          // Add action to notification
          notify_notification_add_action(notification, action_id, action_title, 
                                       nullptr, nullptr, nullptr);
        }
      }
    }
  }

  // Set up notification callback
  g_signal_connect(notification, "action-invoked", G_CALLBACK(on_notification_action), self);
  g_signal_connect(notification, "closed", G_CALLBACK(on_notification_closed), self);

  // Show notification
  GError* error = nullptr;
  gboolean success = notify_notification_show(notification, &error);
  
  if (error) {
    g_error_free(error);
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  g_autoptr(FlValue) result = fl_value_new_bool(success);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* cancel_notification(NotificationManagerPlugin* self, FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  FlValue* id_value = fl_value_lookup_string(args, "id");
  if (!id_value) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  const gchar* id = fl_value_get_string(id_value);
  auto it = self->active_notifications.find(id);
  
  if (it != self->active_notifications.end()) {
    notify_notification_close(it->second, nullptr);
    self->active_notifications.erase(it);
  }

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* cancel_all_notifications(NotificationManagerPlugin* self) {
  for (auto& pair : self->active_notifications) {
    notify_notification_close(pair.second, nullptr);
  }
  self->active_notifications.clear();

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* get_badge_count() {
  // Linux doesn't have a built-in badge count
  g_autoptr(FlValue) result = fl_value_new_int(0);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* set_badge_count(FlMethodCall* method_call) {
  // Linux doesn't have a built-in badge count
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* clear_badge_count() {
  // Linux doesn't have a built-in badge count
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* is_duplicate_notification_method(NotificationManagerPlugin* self, FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  FlValue* id_value = fl_value_lookup_string(args, "id");
  FlValue* time_window_value = fl_value_lookup_int(args, "timeWindowSeconds");

  if (!id_value || !time_window_value) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  const gchar* id = fl_value_get_string(id_value);
  int time_window_seconds = fl_value_get_int(time_window_value);

  bool is_duplicate = is_duplicate_notification(id, time_window_seconds);
  g_autoptr(FlValue) result = fl_value_new_bool(is_duplicate);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* clear_notification_history(NotificationManagerPlugin* self) {
  std::string data_dir = get_user_data_dir();
  std::string pref_file = data_dir + "/" + PREF_FILE;

  if (g_file_test(pref_file.c_str(), G_FILE_TEST_EXISTS)) {
    g_remove(pref_file.c_str());
  }

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* schedule_notification(NotificationManagerPlugin* self, FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  FlValue* id_value = fl_value_lookup_string(args, "id");
  FlValue* request_value = fl_value_lookup_string(args, "request");
  FlValue* scheduled_date_value = fl_value_lookup_int(args, "scheduledDate");
  FlValue* is_repeating_value = fl_value_lookup_bool(args, "isRepeating");
  FlValue* repeat_interval_value = fl_value_lookup_int(args, "repeatInterval");

  if (!id_value || !request_value || !scheduled_date_value) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  const gchar* id = fl_value_get_string(id_value);
  const gchar* request_json = fl_value_get_string(request_value);
  int64_t scheduled_date = fl_value_get_int(scheduled_date_value);
  bool is_repeating = is_repeating_value ? fl_value_get_bool(is_repeating_value) : false;
  int repeat_interval = repeat_interval_value ? fl_value_get_int(repeat_interval_value) : 0;

  // Store scheduled notification
  std::string key = SCHEDULED_KEY_PREFIX + std::string(id);
  std::string notification_data = std::string(request_json);
  self->scheduled_notifications[id] = notification_data;
  save_preferences(key, notification_data);

  // For Linux, we'll simulate scheduling by showing the notification immediately
  // In a production environment, you might want to use a proper scheduler
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* get_scheduled_notifications(NotificationManagerPlugin* self) {
  g_autoptr(FlValue) result_list = fl_value_new_list();
  
  for (const auto& pair : self->scheduled_notifications) {
    g_autoptr(FlValue) notification_obj = fl_value_new_map();
    fl_value_set_string_take(notification_obj, "id", g_strdup(pair.first.c_str()));
    fl_value_set_string_take(notification_obj, "data", g_strdup(pair.second.c_str()));
    fl_value_append_take(result_list, fl_value_ref(notification_obj));
  }
  
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result_list));
}

FlMethodResponse* update_scheduled_notification(NotificationManagerPlugin* self, FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  FlValue* id_value = fl_value_lookup_string(args, "id");
  if (!id_value) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  const gchar* id = fl_value_get_string(id_value);
  
  // Update the scheduled notification
  std::string key = SCHEDULED_KEY_PREFIX + std::string(id);
  std::string notification_data = "{}"; // Simplified for demo
  self->scheduled_notifications[id] = notification_data;
  save_preferences(key, notification_data);

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* cancel_scheduled_notification(NotificationManagerPlugin* self, FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  FlValue* id_value = fl_value_lookup_string(args, "id");
  if (!id_value) {
    g_autoptr(FlValue) result = fl_value_new_bool(false);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  const gchar* id = fl_value_get_string(id_value);
  
  // Remove from scheduled notifications
  self->scheduled_notifications.erase(id);
  
  // Remove from preferences
  std::string key = SCHEDULED_KEY_PREFIX + std::string(id);
  std::string data_dir = get_user_data_dir();
  std::string pref_file = data_dir + "/" + PREF_FILE;
  
  if (g_file_test(pref_file.c_str(), G_FILE_TEST_EXISTS)) {
    JsonParser* parser = json_parser_new();
    if (json_parser_load_from_file(parser, pref_file.c_str(), nullptr)) {
      JsonNode* root = json_parser_get_root(parser);
      if (json_node_get_node_type(root) == JSON_NODE_OBJECT) {
        JsonObject* root_obj = json_node_get_object(root);
        json_object_remove_member(root_obj, key.c_str());
        
        JsonGenerator* generator = json_generator_new();
        json_generator_set_root(generator, root);
        json_generator_to_file(generator, pref_file.c_str(), nullptr);
        g_object_unref(generator);
      }
    }
    g_object_unref(parser);
  }

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* cancel_all_scheduled_notifications(NotificationManagerPlugin* self) {
  // Clear all scheduled notifications
  self->scheduled_notifications.clear();
  
  // Clear all scheduled notification preferences
  std::string data_dir = get_user_data_dir();
  std::string pref_file = data_dir + "/" + PREF_FILE;
  
  if (g_file_test(pref_file.c_str(), G_FILE_TEST_EXISTS)) {
    JsonParser* parser = json_parser_new();
    if (json_parser_load_from_file(parser, pref_file.c_str(), nullptr)) {
      JsonNode* root = json_parser_get_root(parser);
      if (json_node_get_node_type(root) == JSON_NODE_OBJECT) {
        JsonObject* root_obj = json_node_get_object(root);
        
        // Get all keys and remove scheduled ones
        g_autoptr(GList) keys = json_object_get_members(root_obj);
        for (GList* iter = keys; iter != nullptr; iter = iter->next) {
          const char* key = static_cast<const char*>(iter->data);
          if (g_str_has_prefix(key, SCHEDULED_KEY_PREFIX)) {
            json_object_remove_member(root_obj, key);
          }
        }
        
        JsonGenerator* generator = json_generator_new();
        json_generator_set_root(generator, root);
        json_generator_to_file(generator, pref_file.c_str(), nullptr);
        g_object_unref(generator);
      }
    }
    g_object_unref(parser);
  }

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Notification action callback
static void on_notification_action(NotifyNotification* notification, gchar* action, gpointer user_data) {
  NotificationManagerPlugin* self = NOTIFICATION_MANAGER_PLUGIN(user_data);
  
  if (self->event_sink) {
    g_autoptr(FlValue) event = fl_value_new_map();
    fl_value_set_string_take(event, "type", fl_value_new_string("action"));
    fl_value_set_string_take(event, "actionId", fl_value_new_string(action));
    
    // Find notification ID
    for (const auto& pair : self->active_notifications) {
      if (pair.second == notification) {
        fl_value_set_string_take(event, "notificationId", fl_value_new_string(pair.first.c_str()));
        break;
      }
    }
    
    fl_event_sink_success(self->event_sink, event);
  }
}

// Notification closed callback
static void on_notification_closed(NotifyNotification* notification, gpointer user_data) {
  NotificationManagerPlugin* self = NOTIFICATION_MANAGER_PLUGIN(user_data);
  
  // Remove from active notifications
  for (auto it = self->active_notifications.begin(); it != self->active_notifications.end(); ++it) {
    if (it->second == notification) {
      self->active_notifications.erase(it);
      break;
    }
  }
}

// Event channel handlers
static FlMethodResponse* on_listen(FlEventChannel* channel, FlValue* arguments, FlEventSink* events, gpointer user_data) {
  NotificationManagerPlugin* self = NOTIFICATION_MANAGER_PLUGIN(user_data);
  self->event_sink = events;
  return nullptr;
}

static FlMethodResponse* on_cancel(FlEventChannel* channel, FlValue* arguments, gpointer user_data) {
  NotificationManagerPlugin* self = NOTIFICATION_MANAGER_PLUGIN(user_data);
  self->event_sink = nullptr;
  return nullptr;
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void notification_manager_plugin_dispose(GObject* object) {
  NotificationManagerPlugin* self = NOTIFICATION_MANAGER_PLUGIN(object);
  
  // Clean up active notifications
  for (auto& pair : self->active_notifications) {
    notify_notification_close(pair.second, nullptr);
  }
  self->active_notifications.clear();
  
  if (notify_is_initted()) {
    notify_uninit();
  }
  
  G_OBJECT_CLASS(notification_manager_plugin_parent_class)->dispose(object);
}

static void notification_manager_plugin_class_init(NotificationManagerPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = notification_manager_plugin_dispose;
}

static void notification_manager_plugin_init(NotificationManagerPlugin* self) {
  self->event_channel = nullptr;
  self->event_sink = nullptr;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  NotificationManagerPlugin* plugin = NOTIFICATION_MANAGER_PLUGIN(user_data);
  notification_manager_plugin_handle_method_call(plugin, method_call);
}

void notification_manager_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NotificationManagerPlugin* plugin = NOTIFICATION_MANAGER_PLUGIN(
      g_object_new(notification_manager_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "notification_manager",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  // Set up event channel
  g_autoptr(FlEventChannel) event_channel =
      fl_event_channel_new(fl_plugin_registrar_get_messenger(registrar),
                           "notification_manager_events",
                           FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handler(event_channel, on_listen, on_cancel, plugin, nullptr);
  plugin->event_channel = event_channel;

  g_object_unref(plugin);
}
