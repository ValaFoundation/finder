finder_sources = files('library.vala')

finder_deps = [
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  dependency('gee-0.8'),
]

finder_shared = shared_library(
  meson.project_name(),
  finder_sources,
  dependencies: finder_deps,
  install: true,
  vala_vapi: 'vapi/' + meson.project_name() + '.vapi',
  vala_header: meson.project_name() + '.h'
)

finder_dep = declare_dependency(
  link_with: finder_shared,
  include_directories: include_directories('.'),
)

pkg = import('pkgconfig')
pkg.generate(
  finder_shared,
  version: meson.project_version(),
  name: meson.project_name(),
  filebase: meson.project_name(),
  description: 'Vala Library Template.'
)
