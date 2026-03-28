dbus_service = configure_file(
  input: 'dev.radhey.VictusControl1.service.in',
  output: 'dev.radhey.VictusControl1.service',
  configuration: {
    'bindir': get_option('prefix') / get_option('bindir'),
  },
)

desktop_file = configure_file(
  input: 'dev.radhey.VictusControl.desktop.in',
  output: 'dev.radhey.VictusControl.desktop',
  configuration: {
    'bindir': get_option('prefix') / get_option('bindir'),
  },
)

install_data(
  dbus_service,
  install_dir: '/usr/share/dbus-1/system-services',
)

install_data(
  'dev.radhey.VictusControl1.conf',
  install_dir: '/usr/share/dbus-1/system.d',
)

install_data(
  'dev.radhey.VictusControl.policy',
  install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions'),
)

install_data(
  desktop_file,
  install_dir: join_paths(get_option('datadir'), 'applications'),
)

install_data(
  'dev.radhey.VictusControl.metainfo.xml',
  install_dir: join_paths(get_option('datadir'), 'metainfo'),
)
