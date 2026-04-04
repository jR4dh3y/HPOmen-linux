## Victus Control (Reverse Engineering)

### How does this project approach HP WMI?

This repo is not a full clone of HP's Windows OMEN tooling, and it does not currently depend on Windows-only WMI class reverse engineering to ship its main features.

The current project is a Linux-first control surface for HP Victus hardware. Its working model comes from inspecting what Linux already exposes through `hp_wmi`, validating those interfaces on real hardware, and wrapping the stable parts in a small D-Bus service plus desktop UI.

In practice, the project relies on these Linux-visible paths:

1. `/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0/profile` for the active HP hardware profile.
2. `/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0/choices` for the supported profile list.
3. `/sys/devices/platform/hp-wmi/hwmon/.../fan1_input` and `fan2_input` for fan RPM telemetry.
4. `/sys/devices/platform/hp-wmi/hwmon/.../pwm1_enable` for the validated fan modes exposed by Linux on this machine.
5. `/sys/bus/wmi/devices` for raw WMI device GUID and object inventory.

The reverse-engineering work captured in this repo is therefore mostly:

- inspecting Linux `hp_wmi` behavior
- reading kernel driver source
- checking sysfs and WMI inventory on the target laptop
- validating which writes actually work on the host

Current validated findings for this project are:

- hardware profiles available on the target host: `cool`, `quiet`, `balanced`, `performance`
- fan modes validated on Linux: `auto` and `max`
- granular manual fan levels are not implemented or validated here

Deeper ACPI or Windows-side WMI tracing may still be useful in the future, but that is follow-up investigation, not the basis of the current app.

### What tools are actually used here?

The repo and notes show a Linux-heavy workflow:

- `victus-probe` to capture inventory and snapshots from the current machine
- `modinfo hp_wmi`, `lsmod`, and `sudo modprobe hp_wmi` to verify kernel support
- direct sysfs inspection under `/sys/devices/platform/hp-wmi`, `/sys/class/hwmon`, and `/sys/bus/wmi/devices`
- kernel source review of `drivers/platform/x86/hp/hp-wmi.c` or local DKMS copies of `hp-wmi.c`
- `dmidecode` for system and board identity
- `powerprofilesctl` and `/sys/firmware/acpi/platform_profile*` for profile validation
- `busctl` or similar D-Bus inspection tools when checking the helper API
- Vala, GTK4, GTK3, Meson, and GLib to build the user-facing software

Tools such as `acpidump` and `iasl` are relevant for future low-level investigation, but they are not the core mechanism used by the shipping code paths in this repo.

### How does the project talk to the hardware?

The current implementation talks to hardware through Linux sysfs, not through direct Windows WMI APIs.

Specifically:

1. The shared backend reads DMI identity, temperatures, HP WMI profile state, WMI inventory, and fan telemetry from sysfs.
2. Profile switching is done by writing the requested profile to HP's platform-profile sysfs node.
3. Fan mode switching is done by writing validated values to `pwm1_enable`.
4. The currently supported fan writes are mode-based only:
   - `2` -> automatic fan control
   - `0` -> max fan mode
5. The helper intentionally rejects granular fan-level control because this repo does not have a validated per-fan manual write path.

So the project does not currently use:

- a custom kernel module
- raw ACPI method calls from userspace
- direct `/proc/acpi/` fan control
- reverse-engineered Windows WMI class calls in production code

### Why D-Bus?

This repo uses a privileged helper, `victusd`, on the system bus and keeps the GTK apps unprivileged.

That design fits the project for a few concrete reasons:

1. Privilege separation: the helper performs root-only sysfs writes, while `victus-control` and `victus-tray` run as the user.
2. One hardware API for multiple frontends: the GTK4 window, the GTK3 tray app, and other clients can all use the same `dev.radhey.VictusControl1` interface.
3. Safer UI architecture: widgets never touch sysfs directly; they only consume snapshots and emit user actions.
4. Standard Linux integration: D-Bus fits the desktop environment, service activation model, and policy-file packaging already used by the repo.

One important correction to the earlier generic write-up: this project currently uses polling through `GetSnapshot` rather than a rich event-driven signal model for hardware updates. Also, the repo includes policy assets, but per-call polkit authorization is still noted as unfinished follow-up work.
