dbus_service = configure_file(
  input: 'io.github.radhey.VictusControl1.service.in',
  output: 'io.github.radhey.VictusControl1.service',
  configuration: {
    'bindir': get_option('prefix') / get_option('bindir'),
  },
)

desktop_file = configure_file(
  input: 'io.github.radhey.VictusControl.desktop.in',
  output: 'io.github.radhey.VictusControl.desktop',
  configuration: {
    'bindir': get_option('prefix') / get_option('bindir'),
  },
)

install_data(
  dbus_service,
  install_dir: join_paths(get_option('datadir'), 'dbus-1', 'system-services'),
)

install_data(
  'io.github.radhey.VictusControl.policy',
  install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions'),
)

install_data(
  desktop_file,
  install_dir: join_paths(get_option('datadir'), 'applications'),
)

install_data(
  'io.github.radhey.VictusControl.metainfo.xml',
  install_dir: join_paths(get_option('datadir'), 'metainfo'),
)
