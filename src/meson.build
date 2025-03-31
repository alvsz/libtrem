version_split = meson.project_version().split('.')
api_version = version_split[0] + '.' + version_split[1]
gir = 'libTrem-' + api_version + '.gir'
typelib = 'libTrem-' + api_version + '.typelib'

deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('libgeoclue-2.0'),
  dependency('gweather4'),
]

sources = [
  'weather.vala',
]

lib = library(
  meson.project_name(),
  sources,
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


