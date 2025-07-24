version_split = meson.project_version().split('.')
api_version = version_split[0] + '.' + version_split[1]
gir = 'libTrem-' + api_version + '.gir'
typelib = 'libTrem-' + api_version + '.typelib'

deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('libgeoclue-2.0'),
  dependency('gweather4'),
  dependency('libecal-2.0'),
  dependency('libedataserver-1.2'),
  dependency('libical-glib'),
  dependency('gtk4'),
  dependency('astal-mpris-0.1'),
  dependency('astal-cava-0.1'),
  dependency('gdk-pixbuf-2.0'),
  dependency('gio-unix-2.0'),
  dependency('gio-2.0'),
  dependency('libnm'),
  dependency('libsecret-1'),
  dependency('wayland-client'),
]

vala_services = [
  'services/weather.vala',
  'services/evolutionDataServer.vala',
  'services/calendar.vala',
  'services/remoteSearch.vala',
  'services/networkAgent.vala',
  'services/nm-secret-utils.vala',
]
vala_widgets = [
  # './widgets/lockscreenMpris.vala',
  # './widgets/teste.vala',
  # './widgets/notification.vala',
  # './widgets/notificationCenter.vala',
]
dwl_ipc = [
  dwl_ipc_header,
  dwl_ipc_private_code,
]

lib = library(
  meson.project_name(),
  libtrem_sources + vala_services + vala_widgets + dwl_ipc,
  dependencies: deps,
  vala_header: meson.project_name() + '.h',
  vala_vapi: meson.project_name() + '-' + api_version + '.vapi',
  vala_gir: gir,
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


