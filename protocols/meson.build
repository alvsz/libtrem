wayland_scanner = find_program('wayland-scanner')

dwl_ipc_header = custom_target('dwl-ipc-protocol.h',
  input: './dwl-ipc.xml',
  output: 'dwl-ipc-protocol.h',
  command: [wayland_scanner, 'client-header', '@INPUT@', '@OUTPUT@']
)

dwl_ipc_private_code = custom_target('dwl-ipc-protocol.c',
  input: './dwl-ipc.xml',
  output: 'dwl-ipc-protocol.c',
  command: [wayland_scanner, 'private-code', '@INPUT@', '@OUTPUT@']
)
