# Victus Control
![ss](ss.png)


Victus Control is a Linux-first control surface for HP Victus hardware written in Vala. This repo contains four binaries:

- `victus-control`: GTK4 monitor window
- `victus-tray`: GTK3 + Ayatana AppIndicator tray companion
- `victusd`: D-Bus helper exposing normalized hardware state and profile actions
- `victus-probe`: probe CLI for WMI/sysfs inventory and host snapshots

## Build

Install the required build dependencies first:

- Meson
- Ninja
- Vala (`valac`)
- `pkg-config`
- C compiler toolchain (`gcc`/`cc`)
- `glib-2.0`
- `gio-2.0`
- `gio-unix-2.0`
- `gobject-2.0`
- `gee-0.8`
- `json-glib-1.0`
- `gtk4`
- `gtk+-3.0`
- `ayatana-appindicator3-0.1`
- `polkit-gobject-1`

Then configure and compile:

```bash
meson setup build
meson compile -C build
```

## Installation

Install the released binary package from AUR:

```bash
yay -S victus-control-bin
```

Or clone the repo and run the local install/launch script:

```bash
./run-victus-control.sh
```

The script builds the project, installs the D-Bus/polkit assets, reloads the system bus, restarts the helper, and starts the tray companion plus monitor window.


## Current Behavior

- Reads DMI identity, hwmon temperatures, HP WMI hardware-profile state, and HP WMI inventory.
- Exposes HP WMI hardware-profile switching and a temperature-driven auto-policy mode in the helper.
- Exposes HP WMI hardware profiles through compact GTK controls and the tray menu.
- Exposes validated fan modes where available: `Auto`, `Manual`, and `Max`.
- Sets both manual fan levels with one Apply, in the unit the running driver supports:
  - Percent on upstream hp-wmi `pwm1`/`pwm2` (Linux 7.3+ for Victus 15-fb0xxx, board 8A3D). The kernel maps the range onto the board fan table and keeps manual mode alive itself.
  - RPM on the out-of-tree `fan1_target`/`fan2_target` driver, which victusd rewrites every 90 s because firmware drops them.
- Restores the last hardware profile chosen through Victus Control when victusd starts, because hp-wmi resets Victus S boards to `balanced` at boot.
- Never blocks the window or tray on hardware: D-Bus calls are asynchronous, victusd runs hardware I/O on one worker thread, and a newer request of the same kind replaces a queued one. Buttons waiting on the helper are outlined until it answers.
- Shows separate tray readouts for temperature and fan RPM, with active and pending profile/fan mode marked in the menu label.
- Keeps tray and GTK4 window as separate processes to avoid GTK3/GTK4 AppIndicator conflicts.

## Project Structure

```text
src/
├── common/              # Shared library
├── helper/              # System daemon
├── app/                 # GTK4 monitor window
│   ├── widgets/         # UI components
│   ├── style.css        # stylesheet
│   └── ...
├── tray/                # GTK3 system tray
└── probe/               # CLI probe tool
```

## Notes

- Fan and profile controls depend on the host kernel exposing compatible `hp_wmi` sysfs attributes.
- An out-of-tree `hp-wmi` DKMS module installs under `updates/` and shadows the in-tree driver. Remove it after moving to a kernel with upstream support; `victus-probe inventory` reports `hp_wmi_out_of_tree`, and victusd logs a warning at start.
- The tray companion requires a desktop session with a working StatusNotifier/AppIndicator host.
- The helper runs on the system bus and must be installed with the D-Bus service, D-Bus policy, and polkit policy files.
