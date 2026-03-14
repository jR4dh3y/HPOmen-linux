# Agent Guidelines for Victus Control

Read this file before making any changes. Append new lessons instead of rewriting old entries.

---

## Before You Start Coding

### Ask Yourself:

1. **Does this already exist?**
   - Search the codebase for similar functionality
   - Check the utility folders listed in "Core Principles"

2. **Can I extend something existing?**
   - Maybe a utility just needs one more function
   - Maybe a component just needs one more prop

3. **Where should this live?**
   - Is it reusable? → Put in `common/`
   - Is it specific to one feature? → Keep it local
   - Is it a constant? → Put in `constants.vala`

4. **Am I duplicating anything?**
   - If you're copying code, stop and extract it
   - If you're defining the same type twice, use the existing one

5. **Is this function doing too much?**
   - Can you describe it in one sentence without "and"?
   - If not, break it down

---

## Core Principles

- **Do not create monolithic files.** Keep UI and logic separate at all times.
- **No component should exceed 150 LOC.** If it does, rethink the design — it should never need to be that long. Break it into smaller, focused pieces.
- **UI widgets must not talk to D-Bus or any backend directly.** They receive data via `update(Snapshot)` methods and emit signals for user actions. The controller owns the connection.
- **Shared formatting, constants, and utilities live in `src/common/`.** Both the GTK4 app and GTK3 tray use them — never duplicate between the two.
- **Named constants over magic numbers.** Temperature thresholds, sysfs values, polling intervals — all belong in `constants.vala`.

### Project Structure

```
src/
├── common/              # Shared library (no UI dependencies)
│   ├── constants.vala   #   Named constants (paths, thresholds, modes)
│   ├── errors.vala      #   Error domain
│   ├── formatting.vala  #   Display formatting (shared by GTK4 + GTK3)
│   ├── models.vala      #   Snapshot data class + serialization
│   ├── sysfs.vala       #   Filesystem abstraction
│   ├── hardware.vala    #   Hardware access layer (profiles, temps)
│   ├── fan_backend.vala #   Fan/hwmon operations (mode, RPM, hwmon discovery)
│   ├── probe.vala       #   Deep WMI inventory + probe state
│   └── service-client.vala  # D-Bus client proxy
├── helper/              # System daemon (runs as root)
│   ├── main.vala        #   Entry point
│   ├── auto_policy.vala #   Temperature-driven policy engine
│   └── control_service.vala # D-Bus interface + service impl
├── app/                 # GTK4 monitor window
│   ├── main.vala        #   Entry point
│   ├── config.vala      #   User config (INI file)
│   ├── style.css        #   External stylesheet
│   ├── css_loader.vala  #   CSS loading (installed path + inline fallback)
│   ├── controller.vala  #   D-Bus + polling + action dispatch
│   └── widgets/         #   Pure UI components (no D-Bus)
│       ├── widget_helpers.vala   # Reusable widget factories
│       ├── main_window.vala      # Window shell (assembles sections)
│       ├── hero_section.vala     # Status banner
│       ├── thermal_section.vala  # Temperature + fan RPM
│       ├── profile_section.vala  # Profile buttons + auto-policy
│       └── fan_section.vala      # Fan mode controls
├── tray/                # GTK3 system tray
│   └── main.vala
└── probe/               # CLI probe tool
    └── main.vala
```

---

## Session Mistake Log

Purpose: keep a persistent record of mistakes made while working on this repo, so future sessions can append to it and avoid repeating the same failures.

How to use this section:
- Read it before making changes.
- Append new mistakes instead of rewriting old entries.
- For each mistake, record what happened, why it was wrong, and the rule to follow next time.

### 2026-03-14

#### 1. Misdiagnosed the offline issue as "helper not started"

- Mistake: I assumed `Offline` meant only `victusd` was down, but the helper could run without owning `io.github.radhey.VictusControl1`.
- Rule: For D-Bus "offline" states, always verify process running, bus-name ownership, and a working method call.

#### 2. Missed the missing system D-Bus policy file in the first pass

- Mistake: I assumed service + polkit files were sufficient and missed the required system D-Bus policy file.
- Rule: For system-bus services, always validate all install assets: activation service file, D-Bus policy, and polkit policy (if privileged).

#### 3. Installed D-Bus files to the wrong prefix/path

- Mistake: I installed D-Bus assets under `/usr/local/share/...` while this host resolved them from `/usr/share/...`.
- Rule: Never assume Meson `datadir` is correct for system bus integration; verify host lookup paths and install to known-good locations.

#### 4. The launcher script reused an already-running helper after install

- Mistake: The launcher treated "helper already running" as success, leaving stale `victusd` code active after install.
- Rule: Deployment scripts that update a background service must restart/refresh it to ensure the newly installed version is actually running.

#### 5. Used the wrong write method for sysfs control files

- Mistake: `Fs.write_text()` used `FileUtils.set_contents()`, which breaks on `/sys/...` attributes due to temp-file/rename behavior.
- Rule: Use direct in-place fd writes for sysfs controls, and check the write primitive before blaming permissions.

#### 6. Verified UI capability state too late

- Mistake: I chased a frontend explanation before checking snapshot capabilities (`can_set_profile`, `can_set_fan_mode`).
- Rule: First read live capability flags, then classify as unavailable capability, UI-state bug, or backend action failure.

#### 7. The helper does not fail loudly when D-Bus registration breaks, and I didn't fix that

- Mistake: I found that `victusd` could run without owning its bus name but failed to patch startup diagnostics immediately.
- Rule: If well-known D-Bus name ownership fails, treat it as startup failure and exit or log loudly—no silent partial startup.

#### 8. I gave the user an overconfident "how to run it" answer before verifying runtime requirements

- Mistake: I gave generic run steps before validating this host’s system-bus/runtime requirements.
- Rule: For service-integrated apps, confirm deployment model and host paths first, then provide exact machine-correct instructions.

#### 9. Defaulting to generic, spaced-out UI layouts and redundant information

- Mistake: I created a generic, padded UI with redundant information (e.g., subtitle text that repeated button labels) and a layout that required scrolling.
- Rule: For technical/dashboard UIs, prioritize dense, compact layouts without scrollbars, eliminate redundant text/labels, and apply a deliberate, bold aesthetic rather than generic padding.
