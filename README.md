# Victus Control

Victus Control is a Linux-first control surface for HP Victus hardware written in Vala. This repo now contains four binaries:

- `victus-control`: GTK4 monitor window
- `victus-tray`: GTK3 + Ayatana AppIndicator tray companion
- `victusd`: D-Bus helper exposing normalized hardware state and profile actions
- `victus-probe`: probe CLI for WMI/sysfs inventory and host snapshots

## Build

```bash
meson setup build
meson compile -C build
```

## Run

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

## Current Behavior

- Reads DMI identity, hwmon temperatures, platform profile state, and HP WMI inventory.
- Exposes profile switching and a temperature-driven auto-policy mode in the helper.
- Shows direct fan control in the UI as unavailable until a validated write path is discovered and persisted.
- Keeps tray and GTK4 window as separate processes to avoid the GTK3/GTK4 AppIndicator conflict.

## Current Limitations

- Direct fan writes are intentionally blocked. The helper returns an unsupported error for manual fan mode and fan level requests.
- The helper currently exports the D-Bus API without a finished polkit authorization gate. The policy file and system-bus install assets are included, but the per-call authorization hardening is still a follow-up item.
- If `hp_wmi` is not loaded on the host, fan RPM and platform profile controls will appear unavailable and the app will fall back to temperature-only monitoring.
