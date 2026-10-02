namespace VictusControl {
    /**
     * Out-of-tree hp-wmi manual fan control through fan1_target and fan2_target (RPM).
     *
     * That driver has no keep-alive, so the helper must rewrite targets
     * before firmware reverts them.
     */
    public class FanTargetBackend : Object, ManualFanDriver {
        public string unit { get { return FAN_LEVEL_UNIT_RPM; } }

        public bool needs_reapply { get { return true; } }

        public bool is_available (string hwmon_dir) {
            return Fs.exists(Path.build_filename(hwmon_dir, "pwm1_enable"))
                && Fs.exists(target_path(hwmon_dir, 1))
                && Fs.exists(target_path(hwmon_dir, 2));
        }

        public int level_max (string hwmon_dir, uint16 fan) {
            var value = Fs.read_int(Path.build_filename(hwmon_dir, "fan%u_max".printf(fan)));
            if (value <= 0 || value > uint16.MAX) {
                return MANUAL_FAN_MAX_RPM_FALLBACK;
            }
            return value;
        }

        public int current_level (string hwmon_dir, uint16 fan) {
            return Fs.read_int(target_path(hwmon_dir, fan));
        }

        public void apply_levels (string hwmon_dir, uint16 fan1, uint16 fan2) throws Error {
            Fs.write_text(target_path(hwmon_dir, 1), "%d".printf(clamp_rpm(hwmon_dir, 1, fan1)));
            Fs.write_text(target_path(hwmon_dir, 2), "%d".printf(clamp_rpm(hwmon_dir, 2, fan2)));
        }

        private int clamp_rpm (string hwmon_dir, uint16 fan, uint16 rpm) {
            return int.min(int.max(rpm, MANUAL_FAN_MIN_RPM), level_max(hwmon_dir, fan));
        }

        private static string target_path (string hwmon_dir, uint16 fan) {
            return Path.build_filename(hwmon_dir, "fan%u_target".printf(fan));
        }
    }
}
