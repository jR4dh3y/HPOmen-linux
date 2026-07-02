namespace VictusControl {
    /**
     * Manual per-fan RPM target control via HP WMI hwmon sysfs files.
     */
    public class FanTargetBackend : Object {
        public bool has_manual_rpm_control (out string reason) {
            var hwmon_dir = FanBackend.locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                reason = "HP WMI hwmon fan directory was not found.";
                return false;
            }

            var missing = new Gee.ArrayList<string>();
            require_file(hwmon_dir, "pwm1_enable", missing);
            require_file(hwmon_dir, "fan1_target", missing);
            require_file(hwmon_dir, "fan2_target", missing);
            if (missing.size > 0) {
                reason = "Manual RPM control is unavailable; missing %s.".printf(join_names(missing));
                return false;
            }

            reason = "Manual RPM control is available via fan1_target and fan2_target.";
            return true;
        }

        public void set_manual_mode () throws Error {
            ensure_supported();
            Fs.write_text(mode_path(), SYSFS_FAN_MODE_MANUAL);
        }

        public void set_fan_target (uint16 fan, uint16 rpm) throws Error {
            if (fan != 1 && fan != 2) {
                throw new ControlError.INVALID_ARGUMENT("Unsupported fan number: %u".printf(fan));
            }
            ensure_supported();
            Fs.write_text(target_path(fan), "%u".printf(clamp_rpm(fan, rpm)));
        }

        public void set_fan_levels (uint16 fan1_rpm, uint16 fan2_rpm) throws Error {
            ensure_supported();
            Fs.write_text(target_path(1), "%u".printf(clamp_rpm(1, fan1_rpm)));
            Fs.write_text(target_path(2), "%u".printf(clamp_rpm(2, fan2_rpm)));
        }

        private void ensure_supported () throws Error {
            string reason;
            if (!has_manual_rpm_control(out reason)) {
                throw new ControlError.UNSUPPORTED(reason);
            }
        }

        private uint16 clamp_rpm (uint16 fan, uint16 rpm) {
            uint16 max = FanBackend.read_fan_max_rpm(fan);
            return uint16.min(uint16.max(rpm, MANUAL_FAN_MIN_RPM), max);
        }

        private string hwmon_dir () {
            return FanBackend.locate_hp_hwmon_dir() ?? "";
        }

        private string mode_path () {
            return Path.build_filename(hwmon_dir(), "pwm1_enable");
        }

        private string target_path (uint16 fan) {
            return Path.build_filename(hwmon_dir(), "fan%u_target".printf(fan));
        }

        private void require_file (string dir, string name, Gee.ArrayList<string> missing) {
            if (!Fs.exists(Path.build_filename(dir, name))) {
                missing.add(name);
            }
        }

        private string join_names (Gee.ArrayList<string> names) {
            var builder = new StringBuilder();
            for (int index = 0; index < names.size; index++) {
                if (index > 0) {
                    builder.append(", ");
                }
                builder.append(names[index]);
            }
            return builder.str;
        }
    }
}
