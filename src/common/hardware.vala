namespace VictusControl {
    /**
     * Single entry point for HP WMI profile, fan, and temperature I/O.
     *
     * Not thread-safe: victusd calls it only from its hardware worker thread.
     */
    public class HardwareBackend : Object {
        private FanBackend fan = new FanBackend();
        private ManualFanDriver[] manual_drivers = { new FanPwmBackend(), new FanTargetBackend() };

        public string[] get_hardware_profiles () {
            return PlatformProfile.choices();
        }

        public string get_active_hardware_profile () {
            return PlatformProfile.active();
        }

        public Snapshot read_snapshot () {
            var snapshot = new Snapshot();
            snapshot.product_name = Fs.read_text(DMI_PRODUCT_NAME_PATH) ?? "";
            snapshot.board_name = Fs.read_text(DMI_BOARD_NAME_PATH) ?? "";
            snapshot.bios_version = Fs.read_text(DMI_BIOS_VERSION_PATH) ?? "";
            snapshot.active_hardware_profile = PlatformProfile.active();
            snapshot.available_hardware_profiles = PlatformProfile.choices();
            snapshot.can_set_hardware_profile = PlatformProfile.profile_path() != null;
            snapshot.helper_state = "ready";

            var hwmon_dir = FanBackend.locate_hp_hwmon_dir();
            fan.read_fan_speeds(hwmon_dir, snapshot);
            fan.read_fan_mode(hwmon_dir, snapshot);
            read_manual_capability(hwmon_dir, snapshot);
            ThermalReader.read(snapshot);
            return snapshot;
        }

        public void set_hardware_profile (string requested) throws Error {
            foreach (var profile in PlatformProfile.choices()) {
                if (profile == requested) {
                    PlatformProfile.write(requested);
                    return;
                }
            }
            throw new ControlError.INVALID_ARGUMENT("Unsupported HP WMI hardware profile: %s".printf(requested));
        }

        public void set_fan_mode (string requested) throws Error {
            var hwmon_dir = FanBackend.locate_hp_hwmon_dir();
            if (requested == FanBackend.MODE_MANUAL) {
                require_manual_driver(hwmon_dir);
            }
            fan.write_mode(hwmon_dir, requested);
        }

        /**
         * Enter manual mode and apply both fan levels in the active driver's unit.
         *
         * Returns whether the levels must be reapplied periodically.
         */
        public bool set_fan_levels (uint16 fan1, uint16 fan2) throws Error {
            var hwmon_dir = FanBackend.locate_hp_hwmon_dir();
            var driver = require_manual_driver(hwmon_dir);
            fan.write_mode(hwmon_dir, FanBackend.MODE_MANUAL);
            driver.apply_levels(hwmon_dir, fan1, fan2);
            return driver.needs_reapply;
        }

        public string choose_hardware_profile_for_policy (string requested) {
            var choices = PlatformProfile.choices();
            foreach (var choice in choices) {
                if (choice == requested) {
                    return requested;
                }
            }
            if (Formatting.is_low_power_profile(requested)) {
                string[] fallback_profiles = { "low-power", "quiet", "cool", "balanced" };
                foreach (var fallback in fallback_profiles) {
                    foreach (var choice in choices) {
                        if (choice == fallback) {
                            return choice;
                        }
                    }
                }
            }
            return choices.length > 0 ? choices[0] : requested;
        }

        private ManualFanDriver? find_manual_driver (string? hwmon_dir) {
            if (hwmon_dir == null) {
                return null;
            }
            foreach (var driver in manual_drivers) {
                if (driver.is_available(hwmon_dir)) {
                    return driver;
                }
            }
            return null;
        }

        private ManualFanDriver require_manual_driver (string? hwmon_dir) throws Error {
            var driver = find_manual_driver(hwmon_dir);
            if (driver == null) {
                throw new ControlError.UNSUPPORTED(unsupported_reason(hwmon_dir));
            }
            return driver;
        }

        private void read_manual_capability (string? hwmon_dir, Snapshot snapshot) {
            var driver = find_manual_driver(hwmon_dir);
            snapshot.can_direct_fan_control = driver != null;
            if (driver == null) {
                snapshot.fan_control_reason = unsupported_reason(hwmon_dir);
                return;
            }
            snapshot.fan_level_unit = driver.unit;
            snapshot.fan1_level_max = driver.level_max(hwmon_dir, 1);
            snapshot.fan2_level_max = driver.level_max(hwmon_dir, 2);
            snapshot.fan1_level = driver.current_level(hwmon_dir, 1);
            snapshot.fan2_level = driver.current_level(hwmon_dir, 2);
        }

        private static string unsupported_reason (string? hwmon_dir) {
            if (hwmon_dir == null) {
                return "The hp-wmi driver did not register an HP fan hwmon device.";
            }
            var board = Fs.read_text(DMI_BOARD_NAME_PATH) ?? "unknown";
            if (!Fs.exists(Path.build_filename(hwmon_dir, "pwm1_enable"))) {
                return "The running hp-wmi driver exposes only fan readings for board %s.".printf(board);
            }
            return "The running hp-wmi driver exposes only Auto and Max fan modes for board %s.".printf(board);
        }
    }
}
