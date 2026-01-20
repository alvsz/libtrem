version_split = meson.project_version().split('.')
api_version = version_split[0] + '.' + version_split[1]
gir = 'libTrem-' + api_version + '.gir'
typelib = 'libTrem-' + api_version + '.typelib'

deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('gio-unix-2.0'),
  dependency('libgeoclue-2.0'),
  dependency('gweather4'),
  dependency('libecal-2.0'),
  dependency('libedataserver-1.2'),
  dependency('libical-glib'),
  dependency('gtk4'),
  dependency('astal-notifd-0.1'),
  dependency('astal-mpris-0.1'),
  dependency('astal-cava-0.1'),
  dependency('astal-network-0.1'),
  dependency('astal-bluetooth-0.1'),
  dependency('astal-battery-0.1'),
  dependency('gdk-pixbuf-2.0'),
  dependency('libnm'),
  dependency('libadwaita-1'),
  dependency('libsecret-1'),
  dependency('wayland-client'),
  dependency('polkit-agent-1'),
  dependency('json-glib-1.0'),
  dependency('accountsservice')
]

vala_services = [
  './services/weather.vala',
  './services/evolution/evolutionDataServer.vala',
  './services/evolution/calendar.vala',
  './services/evolution/task.vala',
  './services/remoteSearch.vala',
  './services/network/networkAgent.vala',
  './services/network/networkAgentHandler.vala',
  './services/function-utils.vala',
  './services/wayland/dwlIpc.vala',
  './services/wayland/wl-source.vala',
  './services/polkit/polkitAget.vala',
]
vala_widgets = [
  './widgets/lockscreenMpris.vala',
  './widgets/notification.vala',
  './widgets/notificationCenter.vala',
  './widgets/weather.vala',
  './widgets/networkInfo.vala',
  './widgets/networkButton.vala',
  './widgets/bluetoothInfo.vala',
  './widgets/bluetoothButton.vala',
  './widgets/upowerDevice.vala',
  './widgets/upowerDevices.vala',
  './widgets/userCenter.vala',
]
dwl_ipc = [
  dwl_ipc_header,
  dwl_ipc_private_code,
]

lib = library(
  meson.project_name(),
  libtrem_sources + vala_services + vala_widgets + dwl_ipc,
  dependencies: deps,
  vala_args: ['--vapidir=' + meson.project_source_root() + '/include',
    '--pkg=zdwl'
  ],
  vala_header: meson.project_name() + '.h',
  vala_vapi: meson.project_name() + '-' + api_version + '.vapi',
  vala_gir: gir,
  c_args: [
    '-DPOLKIT_AGENT_I_KNOW_API_IS_SUBJECT_TO_CHANGE'
  ],
  version: meson.project_version(),
  install: true,
  install_dir: [true, true, true, true],
  )

import('pkgconfig').generate(
  lib,
  name: meson.project_name(),
  filebase: meson.project_name() + '-' + api_version,
  version: meson.project_version(),
  subdirs: meson.project_name(),
  requires: deps,
  install_dir: get_option('libdir') / 'pkgconfig',
  )

custom_target(
  typelib,
  command: [
    find_program('g-ir-compiler'),
    '--output', '@OUTPUT@',
    '--shared-library', get_option('prefix') / get_option('libdir') / '@PLAINNAME@',
    meson.current_build_dir() / gir,
    ],
  input: lib,
  output: typelib,
  depends: lib,
  install: true,
  install_dir: get_option('libdir') / 'girepository-1.0',
  )


