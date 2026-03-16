# Vala Victus Control Implementation Plan

## Status Key

- `[done]` implemented in the current tree
- `[partial]` partially implemented or implemented with known gaps
- `[todo]` planned but not yet implemented

## Git History Reviewed

- `[done]` `c12b887` `Initial project import`
- `[done]` `c3f3b63` `Document hp_wmi fan mode findings`
- `[done]` `5c8e894` `Expose HP fan auto/max mode in app`

These commits cover both the base app scaffold and your manual follow-up work exposing HP fan mode state and auto/max toggles.

## Summary

Build a tray-first Linux desktop app in Vala for HP Victus laptops, with:

- `[done]` a GTK4 monitor window
- `[done]` a separate tray companion for Linux tray compatibility
- `[done]` a helper process exposing normalized hardware state and control actions
- `[done]` a probe CLI for WMI/sysfs discovery and capability checks

The plan is intentionally staged around current Linux reality on this machine:

- `[done]` fan RPM telemetry is possible when `hp_wmi` is active
- `[done]` HP WMI hardware profiles are now the primary profile control path used by the app and helper
- `[done]` granular manual fan writes remain unvalidated and blocked
- `[done]` HP fan `auto` and `max` modes are now exposed in the app where the kernel interface exists

## Product Shape

- `[done]` Start with a monitor/profile app that works even when direct fan control is unavailable.
- `[done]` Keep the main monitor UI in GTK4 without Libadwaita.
- `[done]` Keep the tray as a separate process because Ayatana/AppIndicator in Vala depends on GTK3, which conflicts with GTK4 in one process.
- `[partial]` Treat direct fan control as capability-gated and disabled by default until probing proves a safe write path.
  - `auto` and `max` mode switching is implemented.
  - granular fan level control is still disabled.

## Architecture

### Binaries

- `[done]` `victus-control`: GTK4 monitor window
- `[done]` `victus-tray`: GTK3 Ayatana tray companion
- `[done]` `victusd`: helper exposing machine state and control actions
- `[done]` `victus-probe`: CLI for inventory and probe workflows

### Shared responsibilities

- `[done]` Centralize sysfs/WMI discovery in shared source files.
- `[done]` Normalize temperature, fan, profile, and machine identity into a single snapshot model.
- `[done]` Keep tray and GUI thin; they call the helper instead of duplicating hardware logic.

### Helper interface

Expose these operations through the helper:

- `[done]` `GetSnapshot`
- `[done]` `SetHardwareProfile`
- `[done]` `SetPlatformProfile` compatibility alias
- `[done]` `SetAutoPolicy`
- `[done]` `SetFanMode`
- `[done]` `SetFanLevels`
- `[done]` `RunProbe`

Current behavior:

- `[done]` `SetFanMode` supports HP fan `auto` and `max` modes.
- `[done]` `SetFanLevels` returns unsupported for granular control.
- `[partial]` The helper exports the D-Bus API, but per-call polkit authorization is not fully enforced yet.

### Capability policy

- `[done]` Always expose telemetry when available.
- `[done]` Allow profile switching only when the HP WMI hardware-profile path exists.
- `[partial]` Return explicit unsupported errors for granular direct fan control until a validated machine-specific path exists.
  - HP fan mode switching is an implemented exception.

## UI Behavior

### Monitor window

- `[done]` Show product, board, BIOS, active profile, and available profiles.
- `[done]` Show CPU, GPU, and max temperature.
- `[done]` Show fan 1 and fan 2 RPM when available.
- `[done]` Provide `Cool`, `Quiet`, `Balanced`, and `Performance` actions.
- `[done]` Provide an auto-policy toggle.
- `[done]` Show fan mode state and HP fan `Auto` / `Max` actions.
- `[partial]` Show the direct-fan-control state clearly.
  - supported for mode-based `auto` / `max`
  - unavailable for granular fan levels

### Tray

- `[done]` Poll the helper for the current snapshot.
- `[done]` Show current temperature/profile/RPM summary in the tray menu label.
- `[done]` Provide quick actions for all exposed hardware profiles.
- `[done]` Provide an auto-policy toggle.
- `[done]` Provide `Open Monitor` and `Quit`.
- `[todo]` Expose HP fan `Auto` / `Max` controls in the tray as well.

## Probe Strategy

- `[done]` Support host inventory collection from `/sys/bus/wmi/devices`, `hp_wmi`, DMI, and HP WMI hardware-profile paths.
- `[done]` Save probe findings to a machine-local state file.
- `[done]` Keep dangerous fan-write experiments out of the default path.
- `[partial]` Do not enable granular direct fan controls until:
  - `[done]` the machine identity matches
  - `[todo]` the write path is explicitly validated
  - `[todo]` readback confirms success

## Build And Packaging

- `[done]` Use Meson.
- `[done]` Install desktop metadata, polkit policy, and D-Bus service files with the project.
- `[done]` Keep GTK4 and tray dependencies split by binary.
- `[partial]` Metadata exists, but AppStream validation still reports missing homepage and related metadata polish.

## Validation

- `[done]` Build the whole tree with Meson.
- `[done]` Verify the probe CLI on the local machine.
- `[done]` Verify that the helper can start and serve snapshots.
- `[partial]` Verify that the GUI and tray can consume live polled snapshots.
  - build is green
  - helper/probe were exercised locally
  - no full interactive desktop verification was completed in this session
- `[done]` Verify that unsupported granular fan control stays disabled instead of silently failing.

## Known Follow-Ups

- `[todo]` Finish per-call polkit authorization in the helper.
- `[todo]` Add signal-based live updates if polling is not sufficient.
- `[todo]` Extend probe workflows only after a safe HP granular fan-control path is understood.
- `[todo]` Add tray actions for HP fan mode switching.
- `[todo]` Decide whether `hp_wmi` loading should be automated or only documented as a prerequisite.
