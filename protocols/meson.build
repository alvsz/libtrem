wayland_scanner = find_program('wayland-scanner')

dwl_ipc_header = custom_target('dwl-ipc-unstable-v2-protocol.h',
  input: './dwl-ipc-unstable-v2.xml',
  output: '../include/dwl-ipc-unstable-v2-protocol.h',
  command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@']
)

dwl_ipc_private_code = custom_target('dwl-ipc-unstable-v2-protocol.c',
  input: './dwl-ipc-unstable-v2.xml',
  output: '../src/dwl-ipc-unstable-v2-protocol.c',
  command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@']
)
