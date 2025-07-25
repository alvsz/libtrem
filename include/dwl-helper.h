#include "dwl-ipc-client-protocol.h"
#include <wayland-client.h>

void dwl_ipc_client_global_add(void *data, struct wl_registry *registry,
                               uint32_t name, const char *interface,
                               uint32_t version);
void dwl_ipc_client_global_remove(void *data, struct wl_registry *registry,
                                  uint32_t name);

void dwl_ipc_on_frame(void *data, struct dwl_ipc *ipc);
void dwl_ipc_on_monitor_added(void *data, struct dwl_ipc *ipc,
                              const char *address);
void dwl_ipc_on_monitor_removed(void *data, struct dwl_ipc *ipc,
                                const char *address);
void dwl_ipc_on_client_opened(void *data, struct dwl_ipc *ipc,
                              const char *address);
void dwl_ipc_on_client_closed(void *data, struct dwl_ipc *ipc,
                              const char *address);
void dwl_ipc_on_client_title_changed(void *data, struct dwl_ipc *ipc,
                                     const char *address);
void dwl_ipc_on_client_state_changed(void *data, struct dwl_ipc *ipc,
                                     const char *address);
const struct wl_registry_listener *get_global_listener(void);
const struct dwl_ipc_listener *get_dwl_listener(void);
