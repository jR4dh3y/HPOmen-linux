# HP Victus 15-fb0xxx Linux Power / WMI Notes

Last updated: 2026-03-10
Host: `HP Victus by HP Gaming Laptop 15-fb0xxx`
Board: `HP 8A3D`
BIOS: `F.22` dated `2024-07-23`
Kernel seen during inspection: `6.18.13-zen1-1-zen`

## Purpose

This file captures the current findings about:

- HP WMI interfaces exposed to Linux
- Existing fan telemetry and partial fan-control exposure
- Power-profile support
- Gaps that block granular fan control on Linux today

The goal is to preserve enough detail that future work can continue from here without having to rediscover the current state.

## Executive Summary

- `hp_wmi` works on this laptop.
- `hp_wmi` exposes:
  - platform profiles
  - two fan RPM sensors
  - one `pwm1_enable` control node
- Linux does **not** currently expose a standard granular fan target such as `pwm1`, `fan1_target`, or `fan2_target`.
- A test write to `pwm1_enable` with value `1` failed with `Invalid argument`.
- This strongly suggests that Windows has access to vendor-specific WMI methods that Linux does not currently expose in a standard way.

## System Identity

Collected via `dmidecode`:

- Manufacturer: `HP`
- Product Name: `Victus by HP Gaming Laptop 15-fb0xxx`
- Family: `103C_5335M7 HP VICTUS`
- SKU: `7K4W8PA#ACJ`
- Board: `8A3D`
- BIOS version: `F.22`
- BIOS date: `07/23/2024`

## Power Profile Findings

After loading `hp_wmi`, platform profile support became visible.

### Userspace daemon

Service state:

- `power-profiles-daemon.service`: active
- `tlp`: not installed
- `thermald`: not installed
- `tuned`: not installed

### `powerprofilesctl`

Available profiles:

```text
performance
balanced
power-saver
```

The daemon reported:

- `CpuDriver: amd_pstate`
- current profile was observed as `performance` during one check

### ACPI platform profile

After `hp_wmi` load:

`/sys/firmware/acpi/platform_profile`:

```text
balanced
```

`/sys/firmware/acpi/platform_profile_choices`:

```text
cool quiet balanced performance
```

Interpretation:

- HP firmware exposes vendor platform profiles
- Linux can already switch among them through the platform-profile layer
- these profiles may affect thermals/fan behavior indirectly

## CPU Power Driver

From `/sys/devices/system/cpu/amd_pstate/status`:

```text
active
```

Observed governors for all CPU policies:

```text
performance
```

Interpretation:

- system is using `amd_pstate`
- the CPU frequency/power side is already under modern AMD control

## Thermal / hwmon Findings

Before `hp_wmi` was loaded, visible `hwmon` devices included:

- `ACAD`
- `acpitz`
- `BAT0`
- `nvme`
- `amdgpu`
- `k10temp`
- `mt7921_phy0`
- `ucsi_source_psy_USBC000:001`
- `hidpp_battery_0`

Visible sensors included temperatures, but initially no explicit fan control nodes were noticed.

Thermal zones observed:

- `/sys/class/thermal/thermal_zone0`
  - `type=acpitz`
  - observed `temp=85000`

Interpretation:

- Linux sees only minimal standard thermal-zone exposure
- HP-specific fan telemetry is not visible until `hp_wmi` is active

## HP WMI Findings

### Module status

`hp_wmi` exists in the kernel:

```text
/lib/modules/6.18.13-zen1-1-zen/kernel/drivers/platform/x86/hp/hp-wmi.ko.zst
```

`modinfo hp_wmi` confirmed:

- description: `HP laptop WMI driver`
- aliases include:
  - `wmi:5FB7F034-2C63-45E9-BE91-3D44E2C707E4`
  - `wmi:95F24279-4D7B-4334-9387-ACCDC67EF61C`

Initially `hp_wmi` was not loaded.

After:

```bash
sudo modprobe hp_wmi
```

the kernel reported:

```text
hp_wmi: Registered as platform profile handler
```

### hp-wmi sysfs path

After loading, this appeared:

```text
/sys/devices/platform/hp-wmi
```

Interesting exposed files included:

- `als`
- `display`
- `dock`
- `hddtemp`
- `tablet`
- `postcode`

Most important subtrees:

- `/sys/devices/platform/hp-wmi/hwmon/hwmon9`
- `/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0`

## Fan Exposure Under hp_wmi

### Available nodes

Under `/sys/devices/platform/hp-wmi/hwmon/hwmon9`:

- `fan1_input`
- `fan2_input`
- `name`
- `pwm1_enable`

Permissions observed:

- `fan1_input`: read-only
- `fan2_input`: read-only
- `pwm1_enable`: writable by root

### Live values observed

Example readings:

```text
name: hp
fan1_input: 3617
fan2_input: 3317
pwm1_enable: 2
```

Another sample:

```text
fan1_input: 3593
fan2_input: 3322
```

Interpretation:

- there are at least two physical fan RPM sensors available
- HP firmware exports them through Linux hwmon once `hp_wmi` is loaded

### Important missing interfaces

Not observed:

- `pwm1`
- `pwm2`
- `fan1_target`
- `fan2_target`
- any duty-cycle percentage file
- any obvious manual curve table

This is the key limitation.

### `pwm1_enable` write test

Test performed:

```bash
echo 1 > /sys/devices/platform/hp-wmi/hwmon/hwmon9/pwm1_enable
```

Result:

```text
write error: Invalid argument
```

The file still read back as:

```text
2
```

The test immediately restored state by writing `2` again.

Interpretation:

- `pwm1_enable` is not behaving like a normal generic hwmon PWM mode switch
- either only specific values are allowed
- or the driver is exposing a mode/status field without full manual support
- or HP firmware requires a different control path entirely

## Raw WMI Device Inventory

Enumerated under `/sys/bus/wmi/devices`.

### Devices seen

- `05901221-D566-11D1-B2F0-00A0C9062910-14`
- `05901221-D566-11D1-B2F0-00A0C9062910-2`
- `05901221-D566-11D1-B2F0-00A0C9062910-6`
- `14EA9746-CE1F-4098-A0E0-7045CB4DA745-10`
- `1E2A0DA0-2B9E-424F-9C87-B1DAC3F4E9DA-1`
- `1F4C91EB-DC5C-460B-951D-C7CB9B4B8D5E-7`
- `2B814318-4BE8-4707-9D84-A190A859B5D0-5`
- `2D114B49-2DFB-4130-B8FE-4A3C09E75133-8`
- `322F2028-0F84-4901-988E-015176049E2D-11`
- `5FB7F034-2C63-45E9-BE91-3D44E2C707E4-3`
- `8232DE3D-663D-4327-A8F4-E293ADB9BF05-12`
- `95F24279-4D7B-4334-9387-ACCDC67EF61C-4`
- `988D08E3-68F4-4C35-AF3E-6A1B8106F83C-9`
- `ABBC0F6A-8EA1-11D1-00A0-C90629100000-13`
- `B2526ED4-CB45-49FA-9230-8D2FE8AFB8EC-0`

### GUID/object/notify mapping collected

```text
05901221-D566-11D1-B2F0-00A0C9062910-14  guid=05901221-D566-11D1-B2F0-00A0C9062910  object_id=BA  setable=0
05901221-D566-11D1-B2F0-00A0C9062910-2   guid=05901221-D566-11D1-B2F0-00A0C9062910  object_id=MM  setable=0
05901221-D566-11D1-B2F0-00A0C9062910-6   guid=05901221-D566-11D1-B2F0-00A0C9062910  object_id=AB  setable=0
14EA9746-CE1F-4098-A0E0-7045CB4DA745-10  guid=14EA9746-CE1F-4098-A0E0-7045CB4DA745  object_id=BE  setable=0
1E2A0DA0-2B9E-424F-9C87-B1DAC3F4E9DA-1   guid=1E2A0DA0-2B9E-424F-9C87-B1DAC3F4E9DA  notify_id=B0
1F4C91EB-DC5C-460B-951D-C7CB9B4B8D5E-7   guid=1F4C91EB-DC5C-460B-951D-C7CB9B4B8D5E  object_id=BA
2B814318-4BE8-4707-9D84-A190A859B5D0-5   guid=2B814318-4BE8-4707-9D84-A190A859B5D0  notify_id=A0
2D114B49-2DFB-4130-B8FE-4A3C09E75133-8   guid=2D114B49-2DFB-4130-B8FE-4A3C09E75133  object_id=BC  setable=0
322F2028-0F84-4901-988E-015176049E2D-11  guid=322F2028-0F84-4901-988E-015176049E2D  object_id=BF  setable=0
5FB7F034-2C63-45E9-BE91-3D44E2C707E4-3   guid=5FB7F034-2C63-45E9-BE91-3D44E2C707E4  object_id=AA
8232DE3D-663D-4327-A8F4-E293ADB9BF05-12  guid=8232DE3D-663D-4327-A8F4-E293ADB9BF05  object_id=BG  setable=0
95F24279-4D7B-4334-9387-ACCDC67EF61C-4   guid=95F24279-4D7B-4334-9387-ACCDC67EF61C  notify_id=80
988D08E3-68F4-4C35-AF3E-6A1B8106F83C-9   guid=988D08E3-68F4-4C35-AF3E-6A1B8106F83C  object_id=BD  setable=0
ABBC0F6A-8EA1-11D1-00A0-C90629100000-13  guid=ABBC0F6A-8EA1-11D1-00A0-C90629100000  object_id=AA
B2526ED4-CB45-49FA-9230-8D2FE8AFB8EC-0   guid=B2526ED4-CB45-49FA-9230-8D2FE8AFB8EC  object_id=MK
```

### Notes on meaning

- `notify_id=*` entries are likely event/notification channels
- `object_id=*` entries are likely method/data blocks
- many entries report `setable=0`
- that suggests the generic WMI sysfs layer does not treat them as directly writable objects

## BMOF Findings

The standard WMI GUID `05901221-D566-11D1-B2F0-00A0C9062910` had `bmof` files on several instances:

- `...-14/bmof`
- `...-2/bmof`
- `...-6/bmof`

`strings` output from those BMOF blobs was mostly binary noise and did not reveal obvious class or method names related to fan control.

Interpretation:

- useful metadata may still be present
- but casual `strings` inspection is insufficient
- proper WMI/BMOF decoding is likely needed

## Why Windows May Still Have More Fan Control

Most likely reasons:

1. HP’s Windows utility uses proprietary WMI methods not surfaced by the current Linux `hp_wmi` driver.
2. Those methods may require exact argument structures not exposed through generic sysfs.
3. Some control path may go through EC/WMI combinations that Linux has not implemented for this model.

So the current Linux state is:

- RPM readings: yes
- profile switching: yes
- standard granular manual fan speed: no

## Likely Reverse-Engineering Paths

### Path 1: Inspect Linux kernel `hp_wmi` driver source

Goal:

- identify which GUIDs and methods are already known
- understand what `pwm1_enable` value `2` means
- see whether additional fan capabilities exist but are not exported

Targets:

- kernel source for `drivers/platform/x86/hp/hp-wmi.c`
- any related platform profile or hwmon code paths

Questions to answer:

- what exact WMI calls does `hp_wmi` make for fan telemetry
- what values are accepted for `pwm1_enable`
- whether there are model-specific capability checks blocking manual fan mode

### Path 2: Proper ACPI/WMI table decode

Goal:

- map the HP GUIDs/object IDs to meaningful class or method names

Tools to use:

- `acpidump`
- `iasl`
- any Linux WMI/BMOF decoders

Questions to answer:

- do ACPI/WMI tables define thermal or fan control methods
- do they reference method names that map to Windows software behavior

### Path 3: Trace Windows HP utility behavior

Goal:

- identify the exact WMI methods Windows calls to control fans

Potential approaches:

- observe WMI provider activity under Windows
- inspect HP utility binaries/strings/imports
- compare behavior while changing fan modes in the HP Windows tool

Questions to answer:

- which GUID/object/method IDs are used
- what payload format they expect
- whether control is mode-based or truly percentage-based

### Path 4: Build a Linux proof-of-concept caller

Goal:

- invoke raw HP WMI methods directly from Linux once the right method path is known

Possible outcomes:

- simple CLI to switch fan modes
- daemon that integrates with temperature thresholds
- eventual kernel patch if functionality is stable and useful

## Recommended Next Steps

If this work is resumed later, the best order is:

1. Inspect the current kernel’s `hp_wmi` source.
2. Determine the semantics of `pwm1_enable`.
3. Decode the HP-related WMI/ACPI metadata more deeply.
4. If needed, trace the HP Windows utility for the missing fan-control method.
5. Implement a small Linux test tool for raw WMI method invocation.

## Commands Already Used

These are the main commands used during this investigation.

### Platform profile and power

```bash
powerprofilesctl list
cat /sys/devices/system/cpu/amd_pstate/status
ls /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
cat /sys/firmware/acpi/platform_profile
cat /sys/firmware/acpi/platform_profile_choices
```

### HP WMI

```bash
modinfo hp_wmi
sudo modprobe hp_wmi
find /sys/devices/platform/hp-wmi -maxdepth 3 -type f | sort
cat /sys/devices/platform/hp-wmi/hwmon/hwmon9/fan1_input
cat /sys/devices/platform/hp-wmi/hwmon/hwmon9/fan2_input
cat /sys/devices/platform/hp-wmi/hwmon/hwmon9/pwm1_enable
sudo sh -c 'echo 1 > /sys/devices/platform/hp-wmi/hwmon/hwmon9/pwm1_enable'
```

### WMI enumeration

```bash
for d in /sys/bus/wmi/devices/*; do
  printf '%s guid=' "$d"
  cat "$d/guid"
  if [ -f "$d/object_id" ]; then printf ' object_id='; cat "$d/object_id"; fi
  if [ -f "$d/notify_id" ]; then printf ' notify_id='; cat "$d/notify_id"; fi
  if [ -f "$d/setable" ]; then printf ' setable='; cat "$d/setable"; fi
  printf '\n'
done
```

### DMI identity

```bash
sudo dmidecode -t system -t baseboard -t chassis
sudo dmesg | grep -i 'hp\|wmi'
```

## Current Bottom Line

This laptop is in a good position for deeper Linux fan-control work because:

- HP vendor WMI is present
- `hp_wmi` already exposes real fan RPM telemetry
- platform profiles are available

But granular manual fan control is not yet available via normal Linux interfaces because:

- only `pwm1_enable` is exposed
- it does not accept the tested manual value
- no actual PWM duty or target-speed node is exported

The next phase requires reverse engineering rather than simple sysfs scripting.
