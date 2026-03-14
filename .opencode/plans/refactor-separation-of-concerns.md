# Refactoring Plan: Separation of Concerns & Code Deduplication

## Goal
Restructure the Victus Control Vala codebase to eliminate duplicate code, separate UI from logic, break up monolithic files, and follow proper SW dev practices.

---

## Phase 1: Extract Shared Utilities

### 1a. Create `src/common/formatting.vala`
Extract duplicated formatting functions into a shared `Formatting` class:
- `format_profile()` (duplicated verbatim in `window.vala:563-576` and `tray/main.vala:109-122`)
- `format_profiles()` (from `window.vala:551-561`)
- `format_metric()` (from `window.vala:578-580`)
- `format_fan_mode()` (from `window.vala:582-593`)
- `fallback_text()` (from `window.vala:547-549`)

New file contents:
```vala
namespace VictusControl {
    public class Formatting : Object {
        public static string profile (string raw) {
            switch (raw.down()) {
            case "cool":    return "Cool";
            case "quiet":   return "Quiet";
            case "balanced": return "Balanced";
            case "performance": return "Performance";
            default:        return raw != "" ? raw : "Unavailable";
            }
        }

        public static string profiles (string[] list) {
            if (list.length == 0) return "Unavailable";
            string[] formatted = new string[list.length];
            for (var i = 0; i < list.length; i++) {
                formatted[i] = profile(list[i]);
            }
            return string.joinv(" / ", formatted);
        }

        public static string metric (int value, string suffix) {
            return value >= 0 ? "%d%s".printf(value, suffix) : "Unavailable";
        }

        public static string fan_mode (string mode) {
            switch (mode) {
            case "auto":        return "Auto";
            case "max":         return "Max";
            case "unavailable": return "Unavailable";
            default:            return "Unknown";
            }
        }

        public static string fallback (string value) {
            return value != null && value != "" ? value : "Unavailable";
        }
    }
}
```

### 1b. Deduplicate `locate_hp_hwmon_dir()`
- In `src/common/hardware.vala:190-197`: change `private` to `public static`
- In `src/common/probe.vala:115-122`: delete the private copy, call `HardwareBackend.locate_hp_hwmon_dir()` instead (at line 50)

### 1c. Add constants to `src/common/constants.vala`
Add these after the existing constants:
```vala
    // Auto-policy temperature thresholds (degrees C)
    public const int AUTO_POLICY_TEMP_HIGH = 78;
    public const int AUTO_POLICY_TEMP_MID = 64;

    // sysfs fan mode values for pwm1_enable
    public const string SYSFS_FAN_MODE_AUTO = "2";
    public const string SYSFS_FAN_MODE_MAX = "0";

    // Temperature normalization ceiling (degrees C)
    public const double TEMP_NORMALIZE_MAX = 100.0;
```

### 1d. Update consumers to use shared utilities
- **`window.vala`**: Replace all calls to local `format_profile()`, `format_profiles()`, `format_metric()`, `format_fan_mode()`, `fallback_text()` with `Formatting.profile()`, `Formatting.profiles()`, `Formatting.metric()`, `Formatting.fan_mode()`, `Formatting.fallback()`. Delete the local method implementations (lines 547-593).
- **`tray/main.vala`**: Replace `format_profile()` calls with `Formatting.profile()`. Delete local implementation (lines 109-122).
- **`hardware.vala`**: Replace magic strings `"2"` and `"0"` (lines 79, 82) with `SYSFS_FAN_MODE_AUTO` and `SYSFS_FAN_MODE_MAX`. Replace magic ints `2` and `0` in `read_fan_mode()` (lines 149, 152) with parsed versions of these constants.
- **`service.vala`**: Replace hardcoded `78` and `64` (lines 35, 37) with `AUTO_POLICY_TEMP_HIGH` and `AUTO_POLICY_TEMP_MID`.

---

## Phase 2: Break Up `window.vala` (735 lines -> ~6 files)

### Target structure:
```
src/app/
├── main.vala                    (unchanged)
├── config.vala                  (unchanged)
├── style.css                    (NEW - extracted CSS)
├── controller.vala              (NEW - D-Bus client mgmt, polling, actions)
├── widgets/
│   ├── main_window.vala         (NEW - top-level window, assembles sections)
│   ├── hero_section.vala        (NEW - hero/status banner)
│   ├── overview_section.vala    (NEW - system info cards)
│   ├── thermal_section.vala     (NEW - temperature & fan RPM)
│   ├── profile_section.vala     (NEW - profile buttons + auto policy)
│   └── fan_section.vala         (NEW - fan mode controls)
```

### 2a. Extract CSS to `src/app/style.css`
Move the inline CSS string from `window.vala:597-723` into a standalone CSS file. Update `load_css()` to use `provider.load_from_path()` or `load_from_resource()`.

### 2b. Create `src/app/controller.vala`
Extract from `window.vala`:
- `ControlClient? client` field and `ensure_client()` (lines 3, 511-515)
- `set_profile()` (lines 478-487)
- `set_auto_policy()` (lines 489-498)
- `set_fan_mode()` (lines 500-509)
- `refresh_snapshot()` polling logic — returns a `Snapshot` or null on error
- Timer setup (lines 76-79)

The controller exposes:
```vala
public class AppController : Object {
    public signal void snapshot_updated (Snapshot snapshot);
    public signal void connection_lost (string error_message);
    
    public AppController (AppConfig config);
    public void start_polling ();
    public void set_profile (string profile);
    public void set_auto_policy (bool enabled);
    public void set_fan_mode (string mode);
}
```

### 2c. Create widget files
Each widget section receives data via an `update(Snapshot)` method. No widget talks to D-Bus.

**`widgets/hero_section.vala`** — extracted from `build_hero_section()` (lines 82-121) + `build_hero_subtitle()` (lines 517-525)

**`widgets/overview_section.vala`** — extracted from `build_overview_section()` (lines 123-140)

**`widgets/thermal_section.vala`** — extracted from `build_thermal_section()` (lines 142-164) + `update_temperature_card()` (lines 456-459) + `normalize_temperature()` (lines 461-467) + `build_rpm_summary()` (lines 527-545)

**`widgets/profile_section.vala`** — extracted from `build_actions_section()` (lines 166-209) + `update_profile_buttons()` (lines 425-434) + `has_profile()` (lines 469-476)

**`widgets/fan_section.vala`** — extracted from `build_fan_section()` (lines 211-238)

### 2d. Create `widgets/main_window.vala`
Slim window shell that:
- Creates and owns the `AppController`
- Creates each section widget
- Connects to controller signals to call `section.update(snapshot)` on each child
- Loads CSS

Shared widget helpers (`wrap_section`, `create_card`, `create_value_label`, `create_metric_value_label`, `create_metric_bar`, `create_action_button`, `create_panel_value`, `update_active_button`, `set_profile_controls_available`) go into a `widgets/widget_helpers.vala` utility file.

---

## Phase 3: Clean Up `models.vala`

### 3a. Remove legacy alias fields
Delete from `Snapshot` class:
- `active_profile` property (line 9)
- `available_profiles` property (line 10)
- `can_set_profile` property (line 18)

### 3b. Remove alias serialization
- In `to_variant_dict()`: remove lines 34-35 (`active_profile`, `available_profiles`), line 43 (`can_set_profile`)
- In `to_json_object()`: remove lines 65-70 (`active_profile`, `available_profiles` array), line 78 (`can_set_profile`)
- In `from_variant_dict()`: remove lines 108-109 (alias assignments), line 117 (alias assignment)

### 3c. Update all consumers
- `hardware.vala:35-37`: remove the three alias assignment lines
- `window.vala` / widget files: ensure all references use `active_hardware_profile`, `available_hardware_profiles`, `can_set_hardware_profile`
- `tray/main.vala`: already uses `active_hardware_profile`

### 3d. Remove alias methods from `hardware.vala`
Delete:
- `get_platform_profiles()` (lines 11-13)
- `get_active_platform_profile()` (lines 19-21)
- `choose_profile_for_policy()` (lines 116-118)
- `set_platform_profile()` (lines 66-68)

And from `service.vala`:
- `set_platform_profile()` (lines 84-86) — keep the D-Bus interface method but have it call `set_hardware_profile()` directly to maintain backward compat on the bus

---

## Phase 4: Separate `service.vala`

### 4a. Create `src/helper/auto_policy.vala`
Move `AutoPolicyController` class (lines 2-48) into its own file. Update it to use `AUTO_POLICY_TEMP_HIGH` and `AUTO_POLICY_TEMP_MID` constants.

### 4b. Create `src/helper/control_service.vala`
Move `ControlApi` interface (lines 50-59) and `ControlService` class (lines 61-107) into this file.

### 4c. Delete `src/helper/service.vala`
Remove the original file after the split.

---

## Phase 5: Housekeeping

### 5a. Update `src/meson.build`
- Add `'common/formatting.vala'` to `common_sources`
- Update `victus-control` executable sources to list all new widget files
- Update `victusd` executable sources to list `auto_policy.vala` and `control_service.vala` instead of `service.vala`

### 5b. Update `.gitignore`
Add `build-local-verify*/` pattern.

### 5c. Build verification
Run `meson setup build-refactor && ninja -C build-refactor` to verify everything compiles.

---

## Final File Tree (after refactoring)

```
src/
├── common/
│   ├── constants.vala          (updated: +6 constants)
│   ├── errors.vala             (unchanged)
│   ├── formatting.vala         (NEW: shared formatting)
│   ├── models.vala             (updated: removed 3 alias fields)
│   ├── sysfs.vala              (unchanged)
│   ├── hardware.vala           (updated: public locate_hp_hwmon_dir, use constants, remove aliases)
│   ├── probe.vala              (updated: uses HardwareBackend.locate_hp_hwmon_dir)
│   └── service-client.vala     (unchanged)
├── helper/
│   ├── main.vala               (unchanged)
│   ├── auto_policy.vala        (NEW: extracted from service.vala)
│   └── control_service.vala    (NEW: extracted from service.vala)
├── app/
│   ├── main.vala               (unchanged)
│   ├── config.vala             (unchanged)
│   ├── style.css               (NEW: extracted from window.vala)
│   ├── controller.vala         (NEW: D-Bus + polling logic)
│   └── widgets/
│       ├── widget_helpers.vala  (NEW: shared GTK widget factories)
│       ├── main_window.vala     (NEW: window shell)
│       ├── hero_section.vala    (NEW)
│       ├── overview_section.vala(NEW)
│       ├── thermal_section.vala (NEW)
│       ├── profile_section.vala (NEW)
│       └── fan_section.vala     (NEW)
├── tray/
│   └── main.vala               (updated: uses Formatting class)
└── probe/
    └── main.vala               (unchanged)
```

## Files Deleted
- `src/helper/service.vala` (split into `auto_policy.vala` + `control_service.vala`)
- `src/app/window.vala` (split into controller + 6 widget files + CSS)
