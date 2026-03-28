# Victus Control — Bug Audit

Audit date: 2026-03-17

---

## BUG-1: Helper runs as zombie if bus name is lost

**Severity:** HIGH
**File:** `src/helper/main.vala:6-18`
**Status:** FIXED

### Description

`Bus.own_name` is called with only a `bus_acquired` callback. There is no `name_lost` callback. If another `victusd` instance takes the bus name, or the system bus disconnects, the process keeps running the main loop forever — alive but unable to serve any D-Bus requests.

The launcher script (`run-victus-control.sh`) does `pkill -x victusd` before starting a new one, but if the kill fails or is skipped, the old process becomes a zombie that holds resources without serving requests.

### Reproduction

```bash
# Terminal 1: start helper
sudo victusd &

# Terminal 2: start another instance — steals the bus name
sudo victusd &

# Terminal 1's instance is now a zombie: alive, looping, serving nothing
```

### Root cause

```vala
Bus.own_name(
    BusType.SYSTEM,
    SERVICE_NAME,
    BusNameOwnerFlags.NONE,
    (connection) => {        // bus_acquired
        ...
    }
    // name_acquired → null (implicit)
    // name_lost     → null (implicit) ← process never exits
);
```

### Fix

Add a `name_lost` callback that quits the main loop:

```vala
Bus.own_name(
    BusType.SYSTEM,
    SERVICE_NAME,
    BusNameOwnerFlags.NONE,
    (connection) => {
        try {
            service.export(connection);
        } catch (Error error) {
            critical("Failed to export D-Bus service: %s", error.message);
            loop.quit();
        }
    },
    () => {},                              // name_acquired — no action needed
    () => {                                // name_lost
        stderr.printf("victusd: lost bus name, exiting\n");
        loop.quit();
    }
);
```

### Notes

This was logged as mistake #7 on 2026-03-14 but the code was never patched.

---

## BUG-2: Infinite D-Bus timeout freezes GUI

**Severity:** HIGH
**File:** `src/common/service-client.vala:18,43`
**Status:** FIXED

### Description

Every D-Bus call in `ControlClient` uses `timeout: -1` (wait forever):

```vala
var result = proxy.call_sync(method, parameters, DBusCallFlags.NONE, -1, null);
```

If `victusd` hangs (e.g. kernel driver stalls on a sysfs read/write), the calling process blocks indefinitely. Since all calls are synchronous and run on the main thread:

- The GTK4 app freezes completely — no repaints, no input, no poll recovery.
- The GTK3 tray freezes completely — menu stops responding.
- The user must `kill -9` the frozen process.

This affects both polling (`get_snapshot`) and user-initiated actions (`set_hardware_profile`, `set_fan_mode`, etc.).

### Reproduction

Hard to reproduce on demand — requires a kernel driver stall. But any slow sysfs response (e.g. during suspend/resume transitions) can trigger it.

### Fix

Replace `-1` with a reasonable timeout (e.g. 5000ms):

```vala
// In get_snapshot:
var result = proxy.call_sync("GetSnapshot", null, DBusCallFlags.NONE, 5000, null);

// In call_bool:
var result = proxy.call_sync(method, parameters, DBusCallFlags.NONE, 5000, null);
```

5 seconds is generous for any sysfs operation. If it takes longer than that, the kernel driver is stuck and waiting forever won't help.

### Notes

Ideally these would be async calls, but that's a larger refactor. A sync timeout is the minimal fix.

---

## BUG-3: Error messages thrown away — user sees "Error" with no detail

**Severity:** MEDIUM
**File:** `src/app/widgets/hero_section.vala:41-43`
**Status:** FIXED

### Description

When `action_failed` fires, the hero section receives the error message but discards it:

```vala
public void show_error (string error_message) {
    status_label.label = "Error";
    // error_message is completely ignored
}
```

The user sees the status pill briefly flash "Error" (until the next 3-second poll cycle overwrites it with "Online") with no explanation of what went wrong. This makes debugging impossible from the user's perspective.

### Fix

Display the error message in the status pill, or show it as a subtitle:

```vala
public void show_error (string error_message) {
    status_label.label = "Error";
    hero_title_label.label = error_message;
}
```

Alternatively, add a timed auto-dismiss so the error stays visible for longer than one poll cycle (e.g. 5 seconds) before the next `update()` overwrites it.

---

## BUG-4: Config accepts `poll_interval_seconds = 0` — CPU burn loop

**Severity:** MEDIUM
**File:** `src/app/config.vala:15`
**Status:** FIXED

### Description

No validation is performed on the loaded config value. If the user writes `poll_interval_seconds=0` in `~/.config/victus-control/config.ini`:

```ini
[ui]
poll_interval_seconds=0
```

Then `Timeout.add_seconds(0, ...)` fires on every GLib main loop idle iteration — a tight CPU-burning loop that floods the system D-Bus with `GetSnapshot` calls and pins a CPU core at 100%.

Negative values from the config file would be cast to a very large `uint`, causing the poll to essentially never fire (opposite problem but still wrong).

### Fix

Clamp the value after loading:

```vala
config.poll_interval_seconds = (uint) key_file.get_integer("ui", "poll_interval_seconds");
if (config.poll_interval_seconds < 1) {
    config.poll_interval_seconds = DEFAULT_POLL_INTERVAL_SECONDS;
}
```

---

## BUG-5: Polkit policy defined but never enforced

**Severity:** MEDIUM
**File:** `src/helper/control_service.vala` (missing code)
**Status:** Documented — intentionally deferred (design decision)

### Description

The polkit infrastructure exists but is completely unwired:

- `data/io.github.radhey.VictusControl.policy` defines action `io.github.radhey.VictusControl1.manage`
- `src/common/constants.vala:7` defines `POLKIT_ACTION_ID`
- `src/meson.build` links `polkit_dep` into the `victusd` binary

But `ControlService` never calls `polkit_authority_check_authorization_sync()` before executing any privileged operation. Combined with the D-Bus policy file allowing `send_destination` from `context="default"`, any local user or process can call `SetHardwareProfile`, `SetFanMode`, etc. without authentication. The root helper blindly executes whatever any process on the system bus requests.

### Impact

On a single-user laptop this is low risk. On a multi-user system, any user could change hardware profiles or fan modes without authorization.

### Fix

Add a polkit authorization check in `ControlService` before mutating operations. Example:

```vala
private void authorize (GLib.BusName sender) throws Error {
    var authority = Polkit.Authority.get_sync();
    var subject = new Polkit.SystemBusName(sender);
    var result = authority.check_authorization_sync(
        subject,
        POLKIT_ACTION_ID,
        null,
        Polkit.CheckAuthorizationFlags.ALLOW_USER_INTERACTION,
        null
    );
    if (!result.get_is_authorized()) {
        throw new ControlError.NOT_AUTHORIZED("Authorization denied");
    }
}
```

### Notes

If this is intentionally skipped for simplicity on a single-user device, the polkit policy file, the `POLKIT_ACTION_ID` constant, and the `polkit_dep` in meson.build should all be removed to avoid confusion.

---

## BUG-6: Auto-policy flaps at threshold boundaries

**Severity:** LOW
**File:** `src/helper/auto_policy.vala:42-48`
**Status:** FIXED

### Description

The auto-policy uses hard thresholds with no hysteresis:

```
>= 78°C → performance
>= 64°C → balanced
<  64°C → quiet
```

A temperature oscillating at a threshold boundary (e.g. 77-78°C) causes a hardware profile sysfs write every 5 seconds, flipping between "balanced" and "performance" indefinitely. Each write hits the kernel driver.

### Fix

Add hysteresis — require the temperature to cross a wider band before switching. For example, switch to "performance" at 78°C but don't switch back to "balanced" until the temperature drops below 73°C.

```vala
// Only switch down if we've dropped sufficiently below the threshold
private const int HYSTERESIS = 5;

// When currently at "performance", stay there until temp < HIGH - HYSTERESIS
if (current_profile == "performance" && snapshot.max_temp_c >= AUTO_POLICY_TEMP_HIGH - HYSTERESIS) {
    return; // don't flap
}
```

---

## BUG-7: CSS installed-path lookup is dead code

**Severity:** LOW
**File:** `src/app/css_loader.vala:10-13`
**Status:** FIXED

### Description

The CSS loader constructs a path for an installed stylesheet:

```vala
var installed_css_path = Path.build_filename(
    Path.get_dirname(Environment.find_program_in_path("victus-control") ?? ""),
    "..", "share", "victus-control", "style.css"
);
```

This resolves to something like `/usr/share/victus-control/style.css`. But `data/meson.build` never installs `style.css` anywhere — there's no `install_data` directive for it. This code path can never succeed.

The fallback CSS (the embedded `FALLBACK_CSS` string constant) handles the case, so there's no visible failure. But the logic is misleading and the `installed_css_path` branch is dead code.

### Fix

Either:
1. Add an `install_data` rule in `data/meson.build` to install `src/app/style.css` to the expected path, or
2. Remove the dead `installed_css_path` branch entirely

---

## Previously fixed

### FIXED: Stale D-Bus proxy not invalidated on action failure

**Fixed:** 2026-03-17
**Files:** `src/app/controller.vala`, `src/tray/main.vala`

`refresh()` nulled the client on D-Bus error but action methods (`set_profile`, `set_fan_mode`, `set_auto_policy`) did not. A stale proxy persisted across retries, causing every user action to fail until the process was restarted.

Fixed by adding retry-after-reconnect logic: on first failure, null the client, create a fresh one, and retry once. Both `AppController.run_with_retry()` and `TrayApp.try_call()` now follow this pattern.
