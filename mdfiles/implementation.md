# Implementation

This implementation plan is derived from all markdown docs currently in the repo:

- `README.md`
- `plan.md`
- `hp-victus-linux-power-wmi-notes.md`
- `IMPLEMENTATION_PLAN.md`
- `log.md`

## Direction

Use HP WMI hardware profiles as the source of truth for profile control, not generic power-profile plumbing.

Primary paths:

- `/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0/profile`
- `/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0/choices`

## Scope

1. Read active and available hardware profiles from the HP WMI profile path.
2. Write profile changes to the HP WMI profile path.
3. Keep helper auto-policy targeting `quiet`, `balanced`, and `performance`, but resolve those against the HP WMI set that includes `cool`, `quiet`, `balanced`, and `performance`.
4. Update the D-Bus surface, probe output, tray, and GTK window to present all exposed hardware profiles.
5. Preserve compatibility aliases where useful so existing callers are not broken unnecessarily.

## Non-Goals

- Do not reintroduce `powerprofilesctl` or generic ACPI platform-profile control as the primary backend path.
- Do not expand granular fan writes beyond the already validated HP `auto` and `max` fan modes.
