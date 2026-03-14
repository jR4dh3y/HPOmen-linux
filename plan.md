# Linux OMEN-Like Profile Script Plan

## Goal
Create a single script that approximates OMEN modes on Linux by combining:
- HP platform profile (`/sys/firmware/acpi/platform_profile`)
- AMD pstate governor/EPP
- CPU max frequency cap

This does not provide direct fan PWM control on this HP Victus model, but it can change thermal/noise behavior indirectly.

## Script Name
`/usr/local/bin/hp-profile`

## Modes
1. `quiet`
2. `balanced`
3. `performance`
4. `status`

## Behavior by Mode

### quiet
- `platform_profile`: `quiet` (fallback to `cool`)
- `scaling_governor`: `powersave`
- `energy_performance_preference`: `power`
- `scaling_max_freq`: cap to `2200000`
- `boost`: `0` (if available)

### balanced
- `platform_profile`: `balanced` (fallback to `cool`)
- `scaling_governor`: `powersave`
- `energy_performance_preference`: `balance_power`
- `scaling_max_freq`: cap to `3000000`
- `boost`: `1`

### performance
- `platform_profile`: `performance`
- `scaling_governor`: `performance`
- `energy_performance_preference`: `performance`
- `scaling_max_freq`: set to per-policy `cpuinfo_max_freq`
- `boost`: `1`

### status
- Print current:
  - platform profile
  - governor/EPP on `policy0`
  - boost state
  - min/max freq on `policy0`

## Implementation Notes
- Bash script with:
  - `set -euo pipefail`
  - root check (`id -u`)
  - helper `set_all_policies <file> <value>`
  - helper `set_platform_profile <preferred> <fallback>`
- Validate writable sysfs files before writing.
- Ignore unsupported values gracefully with clear warning.

## Safety
- Keep changes runtime-only by default.
- Optional persistence via systemd service only if user asks.
- Log applied settings to stdout after each mode change.

## Usage
- `sudo hp-profile quiet`
- `sudo hp-profile balanced`
- `sudo hp-profile performance`
- `hp-profile status`

## Verification
After mode switch, verify:
- `cat /sys/firmware/acpi/platform_profile`
- `cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
- `cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference`
- `cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq`
- monitor temps/fan acoustics for 5-10 minutes under load
