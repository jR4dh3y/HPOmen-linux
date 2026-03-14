# Session Mistake Log

Purpose: keep a persistent record of mistakes made while working on this repo, so future sessions can append to it and avoid repeating the same failures.

How to use this file in future sessions:
- Read it before making changes.
- Append new mistakes instead of rewriting old entries.
- For each mistake, record what happened, why it was wrong, and the rule to follow next time.

## 2026-03-14

### 1. Misdiagnosed the offline issue as “helper not started”

What happened:
- I initially told the user that `Offline` mainly meant `victusd` was not running.
- I then started the helper with `sudo`, but the GUI still stayed offline.

Why this was wrong:
- The real failure was that the helper could run but still not own `io.github.radhey.VictusControl1` on the system bus.
- I did not verify bus name ownership first.

What to do next time:
- When a GUI talks to a D-Bus helper and shows “offline”, verify all three separately:
- process is running
- bus name is owned
- target method responds
- Do not stop at “the daemon process exists”.

### 2. Missed the missing system D-Bus policy file in the first pass

What happened:
- I saw the repo had a service file and a polkit policy and assumed the D-Bus setup was close to complete.
- Only after runtime debugging did I add the missing system D-Bus policy file.

Why this was wrong:
- A custom system-bus service needs a bus policy path that allows name ownership and message routing.
- Service file + polkit policy alone was not enough.

What to do next time:
- For any system D-Bus service, explicitly check for all required install assets:
- service activation file
- D-Bus policy file
- polkit policy if privileged actions are involved

### 3. Installed D-Bus files to the wrong prefix/path

What happened:
- I first installed the D-Bus service and policy under `/usr/local/share/...`.
- On this machine, the system bus was using `/usr/share/...`, so the service stayed invisible.

Why this was wrong:
- I relied on a generic Meson `datadir` assumption without checking the host’s D-Bus search paths.

What to do next time:
- Before choosing install paths for D-Bus assets, verify the host’s actual lookup paths.
- Do not assume `/usr/local/share` is valid for system D-Bus integration.
- If the project is meant to integrate with the host service manager or bus, prefer explicit known-good system paths.

### 4. The launcher script reused an already-running helper after install

What happened:
- The first version of `run-victus-control.sh` skipped restarting `victusd` if it was already responding.
- After code changes, that allowed an old helper binary/process to stay active.

Why this was wrong:
- Installer scripts that deploy background services must refresh the running service, not just the files on disk.

What to do next time:
- After install, restart the helper/service if the point of the script is “run the newly installed version”.
- Do not treat “already running” as success after deploying a new build.

### 5. Used the wrong write method for sysfs control files

What happened:
- `Fs.write_text()` used `FileUtils.set_contents()`.
- That failed for `/sys/...` control files because it uses temp-file and rename semantics.

Why this was wrong:
- sysfs attributes usually require direct in-place writes through an open file descriptor.
- This caused the UI controls to appear non-functional even though the helper method calls were reaching the backend.

What to do next time:
- Never use `FileUtils.set_contents()` for sysfs writes.
- Use direct file writes for kernel control files.
- When a privileged control path fails on `/sys`, inspect the exact write primitive before assuming permissions are the whole issue.

### 6. Verified UI capability state too late

What happened:
- I initially treated the non-interactive UI as a frontend issue.
- Only later did I inspect the live probe snapshot and confirm the machine actually exposed `can_set_profile=true` and `can_set_fan_mode=true`.

Why this was wrong:
- The snapshot already had the capability truth needed to separate “disabled by design” from “backend action failure”.

What to do next time:
- When controls appear dead or disabled, inspect the live capability snapshot first.
- Separate these cases early:
- unavailable capability
- UI state bug
- backend action failure

### 7. The helper does not fail loudly when D-Bus registration breaks, and I didn’t fix that

What happened:
- `victusd` could stay running even when the bus name was not owned, which made diagnosis slower.
- I identified this but did not patch the helper to surface bus ownership failure clearly.

Why this was wrong:
- A daemon that depends on a well-known D-Bus name should make loss of that name obvious.
- Silent partial startup wastes debugging time and misleads the user.

What to do next time:
- Treat incomplete startup diagnostics as part of the bug, not just a follow-up idea.
- If D-Bus name ownership is critical, surface failure clearly and exit or log loudly.

### 8. I gave the user an overconfident “how to run it” answer before verifying runtime requirements

What happened:
- I initially gave straightforward run instructions without first confirming the system-bus requirement and installation/runtime path details on this host.

Why this was wrong:
- The command sequence was incomplete for the actual deployment model.
- The user lost time following instructions that were not sufficient for this machine.

What to do next time:
- For apps with system services, privileged helpers, D-Bus integration, or host-installed assets, verify the runtime model before giving a short “just run this” answer.
- Prefer exact, host-correct instructions over generic quick-start commands.
