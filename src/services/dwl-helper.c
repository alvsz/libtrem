#include "dwl-helper.h"

static const struct wl_registry_listener global_listener_impl = {
    .global = dwl_ipc_client_global_add,
    .global_remove = dwl_ipc_client_global_remove,
};

static const struct dwl_ipc_listener dwl_listener_impl = {
    .frame = dwl_ipc_on_frame,
    .monitor_added = dwl_ipc_on_monitor_added,
    .monitor_removed = dwl_ipc_on_monitor_removed,
    .client_opened = dwl_ipc_on_client_opened,
    .client_closed = dwl_ipc_on_client_closed,
    .client_title_changed = dwl_ipc_on_client_title_changed,
    .client_state_changed = dwl_ipc_on_client_state_changed,
};

const struct wl_registry_listener *get_global_listener(void) {
  return &global_listener_impl;
}

const struct dwl_ipc_listener *get_dwl_listener(void) {
  return &dwl_listener_impl;
}
