# Agent Guidelines for Victus Control

Read this file before making any changes. Append new lessons to the Mistake Log instead of rewriting old entries.

## Build Commands

The project uses **Meson** with a Vala toolchain. No tests exist yet.

```bash
# First-time setup (from repo root)
meson setup build --prefix /usr

# Compile all four binaries (victusd, victus-control, victus-tray, victus-probe)
meson compile -C build

# Install (requires sudo; installs D-Bus service, polkit policy, desktop file)
sudo meson install -C build

# Full build-install-run cycle (the canonical way to launch)
./run-victus-control.sh

# Reconfigure an existing build directory
meson configure build --prefix /usr

# Clean rebuild
rm -rf build && meson setup build --prefix /usr && meson compile -C build
```

There is **no test suite, no linter, and no CI pipeline**. Validate changes by compiling successfully with `meson compile -C build`. The Vala compiler (`valac`) is the only static checker — build warnings at `warning_level=2` are the closest thing to a lint pass.

### System Integration

D-Bus files **must** install to `/usr/share/dbus-1/` (not `/usr/local/share/`). After install, reload the system bus: `sudo systemctl reload dbus`. The helper (`victusd`) runs as root on the system bus; kill stale instances before testing new code: `sudo pkill -x victusd`.

---

## Project Structure

```
src/
  common/       Shared code: models, constants, sysfs I/O, formatting, D-Bus client
  helper/       victusd — privileged D-Bus service (system bus, runs as root)
  app/          victus-control — GTK4 monitoring GUI
    widgets/    UI components (each receives Snapshot, emits signals)
  tray/         victus-tray — GTK3 + Ayatana AppIndicator tray app
  probe/        victus-probe — CLI hardware inventory tool
data/           D-Bus service/policy files, desktop entry, metainfo
```

Four executables are built: `victusd`, `victus-control`, `victus-tray`, `victus-probe`. All share `common_sources` from `src/common/`.

---

## Code Style

### Language and Namespace

- **Language**: Vala (compiles to C via valac, targets GLib/GObject)
- **Single namespace**: All code lives in `namespace VictusControl { }`. No sub-namespaces.
- **No explicit imports**: Dependencies come from Meson `dependency()` declarations and GIR. Never use `using` directives.

### Naming Conventions

| Element        | Convention          | Example                            |
|----------------|---------------------|------------------------------------|
| Classes        | `PascalCase`        | `HardwareBackend`, `FanSection`    |
| Methods        | `snake_case`        | `read_snapshot`, `set_fan_mode`    |
| Properties     | `snake_case`        | `active_hardware_profile`          |
| Signals        | `snake_case`        | `snapshot_updated`, `action_failed`|
| Constants      | `UPPER_SNAKE_CASE`  | `DEFAULT_POLL_INTERVAL_SECONDS`    |
| Local variables| `snake_case`        | `hwmon_dir`, `snapshot`            |
| Error domains  | `PascalCase`        | `ControlError`                     |

### Formatting

- 4-space indentation (no tabs).
- Opening braces on the same line: `public void foo () {`.
- Space before parentheses in method declarations: `public void foo ()`, not `public void foo()`.
- `switch` cases aligned with `case` at same indent as `switch`, body indented once.
- Blank line between methods. No trailing whitespace.

### Types and Nullability

- Use `?` suffix for nullable types: `string?`, `ControlClient?`.
- Provide `default =` values on GObject properties: `public int fan1_rpm { get; set; default = -1; }`.
- Use `-1` for unavailable integer metrics; `""` for unavailable strings; `"unknown"` for state fields.
- Prefer `string[]` over `GenericArray<string>` for simple lists.

### Error Handling

- Custom error domain: `ControlError { FAILED, IO, INVALID_ARGUMENT, NOT_AUTHORIZED, UNSUPPORTED }`.
- Mark fallible methods with `throws Error`.
- Catch with `try { ... } catch (Error error) { ... }`. Use `error.message` for logging.
- Print errors to `stderr`: `stderr.printf("victusd: %s\n", error.message)`.
- Never silently swallow errors. Log or propagate.

### Architecture Rules

- **UI widgets never touch D-Bus or sysfs.** Widgets receive data via `update(Snapshot)` and emit signals for user actions. `AppController` owns the D-Bus connection and dispatches.
- **Controller pattern**: `AppController` polls via `ControlClient`, emits `snapshot_updated` / `connection_lost` / `action_failed` signals. Widgets subscribe.
- **Shared code belongs in `src/common/`.** Both GTK4 app and GTK3 tray depend on it. Never duplicate between the two.
- **All magic numbers go in `src/common/constants.vala`.** Paths, thresholds, polling intervals, sysfs values.

### File Size and Organization

- **150 LOC max per file.** If a file exceeds this, split it. The only exception is embedded CSS fallbacks.
- **Keep UI and logic separate.** No business logic in widget files; no GTK in common/ or helper/.
- **One class per file** (with minor helpers allowed in the same file).
- **New source files must be added to `src/meson.build`** in the appropriate executable's source list.

### sysfs I/O

- Use `Fs.write_text()` (which uses `FileStream.open` + `puts`) for sysfs writes. Never use `FileUtils.set_contents()` — it does temp-file + rename which breaks on `/sys/` attributes.
- Use `Fs.read_text()` / `Fs.read_int()` for sysfs reads. They handle null and strip whitespace.

---

## Before You Start Coding

1. **Does this already exist?** Search `src/common/` for similar functionality first.
2. **Can I extend something existing?** Add a method/property rather than a new file.
3. **Where should this live?** Reusable -> `common/`. Feature-specific -> local. Constant -> `constants.vala`.
4. **Am I duplicating anything?** If copying code, extract a shared utility.
5. **Is this function doing too much?** Describe it in one sentence without "and". If you can't, split it.

---

## Session Mistake Log

Append new mistakes here. Do not rewrite old entries.

### 2026-03-14

1. **Misdiagnosed offline as "helper not started"** — `victusd` can run without owning its bus name. Rule: verify process + bus-name ownership + a working method call.
2. **Missed system D-Bus policy file** — Service + polkit files aren't sufficient alone. Rule: validate all install assets (activation service, D-Bus policy, polkit policy).
3. **Installed D-Bus files to wrong prefix** — `/usr/local/share/` vs `/usr/share/`. Rule: verify host lookup paths; never assume Meson `datadir` is correct for system bus.
4. **Launcher reused stale helper** — "Already running" != "running new code". Rule: restart/refresh background services after install.
5. **Wrong write method for sysfs** — `FileUtils.set_contents()` breaks on `/sys/` due to temp-file/rename. Rule: use direct fd writes (FileStream).
6. **Verified UI capability state too late** — Rule: check live capability flags (`can_set_profile`, `can_set_fan_mode`) before investigating UI code.
7. **Helper silent on D-Bus registration failure** — Rule: if bus-name ownership fails, exit or log loudly. No silent partial startup.
8. **Overconfident run instructions before verifying runtime** — Rule: confirm deployment model and host paths before giving instructions.
9. **Generic UI layouts** — Rule: dense, compact dashboard layouts. No scrollbars, no redundant labels, deliberate aesthetic.

### 2026-03-17

10. **Stale D-Bus proxy not invalidated on action failure** — `refresh()` nulled the client on error but action methods (`set_profile`, `set_fan_mode`, `set_auto_policy`) did not. Stale proxy persisted across retries. Rule: every D-Bus call path must invalidate (`client = null`) on failure, not just the polling path. Same bug existed in both `AppController` and `TrayApp.try_call`.
11. **Helper zombie on bus name loss** — `Bus.own_name` had no `name_lost` callback. If another victusd stole the name, the old process looped forever serving nothing. Rule: always provide `name_lost` that exits.
12. **Infinite D-Bus timeout freezes GUI** — `call_sync` used `timeout: -1` (wait forever). A stalled kernel driver blocks the entire main thread permanently. Rule: always set a finite timeout on synchronous D-Bus calls.
13. **Error messages discarded in hero section** — `show_error()` received the message but displayed only "Error". Next poll cycle (3s) overwrote it with "Online". Rule: display the actual message and hold it long enough to read.
14. **Config accepts poll_interval_seconds=0** — No validation after load. Zero causes a tight CPU-burning poll loop. Rule: clamp user-supplied intervals to sane minimums.
15. **Auto-policy threshold flapping** — No hysteresis on temperature thresholds. Oscillating at a boundary caused a sysfs write every 5 seconds. Rule: require temperature to cross threshold minus a margin before switching back down.
16. **Dead CSS installed-path branch** — `css_loader.vala` looked for an installed stylesheet that was never installed by meson. Rule: don't code paths for files that aren't deployed.
