# Victus Control

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

## Run

1. Use the One-Shot Script:

  ```bash
  ./run-victus-control.sh
  ```
  it will handle building the project, reloading the system bus, and starting the helper, tray companion, and monitor window together.

Or 

2. Run components manually:

  Probe the current machine:
  
  ```bash
  ./build/src/victus-probe snapshot
  ./build/src/victus-probe inventory
  ```
  
  Launch the helper:
  
  ```bash
  ./build/src/victusd
  ```
  
  Launch the monitor window or tray:
  
  ```bash
  ./build/src/victus-control
  ./build/src/victus-tray
  ```

## AUR

The repository now includes a binary-package scaffold for AUR under `packaging/aur/victus-control-bin`.

- `scripts/build-release-archive.sh <version>` builds a release tarball with the installed `/usr` tree inside it.
- Pushing a tag like `v0.1.0` triggers `.github/workflows/release.yml`, which uploads that tarball and a matching `.sha256` file to GitHub Releases.
- The AUR package then repackages that release archive as `victus-control-bin`.

The current PKGBUILD keeps `sha256sums=('SKIP')` so the template works before the first release exists. For a stricter AUR submission, replace it with the generated release checksum.

## Current Behavior

- Reads DMI identity, hwmon temperatures, HP WMI hardware-profile state, and HP WMI inventory.
- Exposes HP WMI hardware-profile switching and a temperature-driven auto-policy mode in the helper.
- Exposes the four validated HP WMI hardware profiles seen on this host: `cool`, `quiet`, `balanced`, and `performance`.
- Exposes validated HP fan modes where available: `Auto` and `Max`.
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

## Current Limitations

- Manual/granular fan level writes are still blocked. The helper only supports validated fan modes such as `auto` and `max`.
- The helper currently exports the D-Bus API without a finished polkit authorization gate. The policy file and system-bus install assets are included, but the per-call authorization hardening is still a follow-up item.
- If `hp_wmi` is not loaded on the host, fan RPM and HP WMI hardware-profile controls will appear unavailable and the app will fall back to temperature-only monitoring.
- The tray companion requires a desktop session with a working StatusNotifier/AppIndicator host. If the session has no tray host, `victus-tray` may run without a visible icon.
