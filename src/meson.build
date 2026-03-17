glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gobject_dep = dependency('gobject-2.0')
gee_dep = dependency('gee-0.8')
json_dep = dependency('json-glib-1.0')
gtk4_dep = dependency('gtk4')
gtk3_dep = dependency('gtk+-3.0')
ayatana_dep = dependency('ayatana-appindicator3-0.1')
polkit_dep = dependency('polkit-gobject-1')

common_sources = files(
  'common/constants.vala',
  'common/errors.vala',
  'common/formatting.vala',
  'common/fan_backend.vala',
  'common/models.vala',
  'common/runtime_paths.vala',
  'common/sysfs.vala',
  'common/hardware.vala',
  'common/probe.vala',
  'common/service-client.vala',
)

executable(
  'victusd',
  common_sources + files(
    'helper/auto_policy.vala',
    'helper/control_service.vala',
    'helper/main.vala',
  ),
  dependencies: [
    glib_dep,
    gio_dep,
    gio_unix_dep,
    gobject_dep,
    gee_dep,
    json_dep,
    polkit_dep,
  ],
  install: true,
)

executable(
  'victus-probe',
  common_sources + files(
    'probe/main.vala',
  ),
  dependencies: [
    glib_dep,
    gio_dep,
    gio_unix_dep,
    gobject_dep,
    gee_dep,
    json_dep,
  ],
  install: true,
)

executable(
  'victus-control',
  common_sources + files(
    'app/config.vala',
    'app/css_loader.vala',
    'app/controller.vala',
    'app/widgets/widget_helpers.vala',
    'app/widgets/hero_section.vala',

    'app/widgets/thermal_section.vala',
    'app/widgets/profile_section.vala',
    'app/widgets/fan_section.vala',
    'app/widgets/main_window.vala',
    'app/main.vala',
  ),
  dependencies: [
    glib_dep,
    gio_dep,
    gio_unix_dep,
    gobject_dep,
    gee_dep,
    json_dep,
    gtk4_dep,
  ],
  install: true,
)

executable(
  'victus-tray',
  common_sources + files(
    'tray/main.vala',
  ),
  dependencies: [
    glib_dep,
    gio_dep,
    gio_unix_dep,
    gobject_dep,
    gee_dep,
    json_dep,
    gtk3_dep,
    ayatana_dep,
  ],
  vala_args: [
    '--vapidir=/usr/share/vala/vapi',
  ],
  install: true,
)
