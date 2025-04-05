subdir('ui')

gnome = import('gnome')

libtrem_sources += gnome.compile_resources(
    meson.project_name(),
    'libtrem.gresource.xml',
    dependencies: [blueprints],
    source_dir: meson.current_build_dir(),
)
