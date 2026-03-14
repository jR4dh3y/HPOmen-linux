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

If you use `run-victus-control.sh`, it should start the helper, tray companion, and monitor window together.

## Current Behavior

- Reads DMI identity, hwmon temperatures, HP WMI hardware-profile state, and HP WMI inventory.
- Exposes HP WMI hardware-profile switching and a temperature-driven auto-policy mode in the helper.
- Exposes the four validated HP WMI hardware profiles seen on this host: `cool`, `quiet`, `balanced`, and `performance`.
- Exposes validated HP fan modes where available: `Auto` and `Max`.
- Reports granular fan-level control as unavailable unless a per-host write path is validated.
- Keeps tray and GTK4 window as separate processes to avoid the GTK3/GTK4 AppIndicator conflict.

## Current Limitations

- Manual/granular fan level writes are still blocked. The helper only supports validated fan modes such as `auto` and `max`.
- The helper currently exports the D-Bus API without a finished polkit authorization gate. The policy file and system-bus install assets are included, but the per-call authorization hardening is still a follow-up item.
- If `hp_wmi` is not loaded on the host, fan RPM and HP WMI hardware-profile controls will appear unavailable and the app will fall back to temperature-only monitoring.
- The tray companion requires a desktop session with a working StatusNotifier/AppIndicator host. If the session has no tray host, `victus-tray` may run without a visible icon.
