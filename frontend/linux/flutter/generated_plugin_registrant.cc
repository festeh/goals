//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <record_linux/record_linux_plugin.h>
#include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
#include <tray_manager/tray_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) record_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "RecordLinuxPlugin");
  record_linux_plugin_register_with_registrar(record_linux_registrar);
  g_autoptr(FlPluginRegistrar) sqlite3_flutter_libs_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "Sqlite3FlutterLibsPlugin");
  sqlite3_flutter_libs_plugin_register_with_registrar(sqlite3_flutter_libs_registrar);
  g_autoptr(FlPluginRegistrar) tray_manager_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "TrayManagerPlugin");
  tray_manager_plugin_register_with_registrar(tray_manager_registrar);
}
