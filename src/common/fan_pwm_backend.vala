namespace VictusControl {
    /**
     * Upstream hp-wmi manual fan control through pwm1 (and pwm2 since Linux 7.3).
     *
     * The kernel maps 0..255 onto the board fan table and does not export
     * the RPM bounds, so levels are percent of that range. The kernel also
     * refreshes manual mode itself, so no userspace reapply is needed.
     */
    public class FanPwmBackend : Object, ManualFanDriver {
        public string unit { get { return FAN_LEVEL_UNIT_PERCENT; } }

        public bool needs_reapply { get { return false; } }

        public bool is_available (string hwmon_dir) {
            return Fs.exists(Path.build_filename(hwmon_dir, "pwm1_enable"))
                && Fs.exists(Path.build_filename(hwmon_dir, "pwm1"));
        }

        public int level_max (string hwmon_dir, uint16 fan) {
            return FAN_LEVEL_PERCENT_MAX;
        }

        public int current_level (string hwmon_dir, uint16 fan) {
            var path = pwm_path(hwmon_dir, fan);
            var pwm = Fs.read_int(Fs.exists(path) ? path : pwm_path(hwmon_dir, 1));
            if (pwm < 0) {
                return -1;
            }
            return (int.min(pwm, MANUAL_FAN_PWM_MAX) * FAN_LEVEL_PERCENT_MAX + MANUAL_FAN_PWM_MAX / 2) / MANUAL_FAN_PWM_MAX;
        }

        public void apply_levels (string hwmon_dir, uint16 fan1, uint16 fan2) throws Error {
            var pwm1 = percent_to_pwm(fan1);
            var pwm2 = percent_to_pwm(fan2);
            if (Fs.exists(pwm_path(hwmon_dir, 2))) {
                Fs.write_text(pwm_path(hwmon_dir, 1), "%d".printf(pwm1));
                Fs.write_text(pwm_path(hwmon_dir, 2), "%d".printf(pwm2));
            } else {
                Fs.write_text(pwm_path(hwmon_dir, 1), "%d".printf(int.max(pwm1, pwm2)));
            }
        }

        private static int percent_to_pwm (uint16 percent) {
            var clamped = int.min(percent, FAN_LEVEL_PERCENT_MAX);
            return (clamped * MANUAL_FAN_PWM_MAX + FAN_LEVEL_PERCENT_MAX / 2) / FAN_LEVEL_PERCENT_MAX;
        }

        private static string pwm_path (string hwmon_dir, uint16 fan) {
            return Path.build_filename(hwmon_dir, "pwm%u".printf(fan));
        }
    }
}
