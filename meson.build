project(
  'libtrem',
  'vala',
  version: run_command('cat', join_paths(meson.project_source_root(), 'version')).stdout().strip(),
  meson_version: '>= 0.62.0',
  default_options: [
    'warning_level=2',
    'werror=false',
    'c_std=gnu11',
  ],
)

libtrem_sources = []

subdir('protocols')
subdir('data')
subdir('src')

