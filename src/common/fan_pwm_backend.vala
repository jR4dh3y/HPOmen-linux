namespace VictusControl {
    /**
     * Upstream Linux manual fan control via hp-wmi PWM hwmon files.
     */
    public class FanPwmBackend : Object {
        public bool has_manual_pwm_control (out string reason) {
            var hwmon_dir = FanBackend.locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                reason = "HP WMI hwmon fan directory was not found.";
                return false;
            }
            if (!Fs.exists(Path.build_filename(hwmon_dir, "pwm1_enable"))) {
                reason = "Manual PWM control is unavailable; missing pwm1_enable.";
                return false;
            }
            if (!Fs.exists(Path.build_filename(hwmon_dir, "pwm1"))) {
                reason = "Manual PWM control is unavailable; missing pwm1.";
                return false;
            }
            if (Fs.exists(Path.build_filename(hwmon_dir, "pwm2"))) {
                reason = "Manual dual-channel PWM control is available via upstream hp-wmi pwm1 and pwm2.";
            } else {
                reason = "Manual single-channel PWM control is available via upstream hp-wmi pwm1.";
            }
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
            Fs.write_text(pwm_path(fan), "%d".printf(rpm_to_pwm(fan, rpm)));
        }

        public void set_fan_levels (uint16 fan1_rpm, uint16 fan2_rpm) throws Error {
            ensure_supported();
            var fan1_pwm = rpm_to_pwm(1, fan1_rpm);
            var fan2_pwm = rpm_to_pwm(2, fan2_rpm);
            if (has_pwm_channel(2)) {
                Fs.write_text(pwm_path(1), "%d".printf(fan1_pwm));
                Fs.write_text(pwm_path(2), "%d".printf(fan2_pwm));
            } else {
                Fs.write_text(pwm_path(1), "%d".printf(int.max(fan1_pwm, fan2_pwm)));
            }
        }

        private int rpm_to_pwm (uint16 fan, uint16 rpm) {
            var max_rpm = FanBackend.read_fan_max_rpm(fan);
            var clamped = int.min(int.max(rpm, MANUAL_FAN_MIN_RPM), max_rpm);
            var rpm_range = max_rpm - MANUAL_FAN_MIN_RPM;
            if (rpm_range <= 0) {
                return MANUAL_FAN_PWM_MAX;
            }
            return ((clamped - MANUAL_FAN_MIN_RPM) * MANUAL_FAN_PWM_MAX) / rpm_range;
        }

        private void ensure_supported () throws Error {
            string reason;
            if (!has_manual_pwm_control(out reason)) {
                throw new ControlError.UNSUPPORTED(reason);
            }
        }

        private string hwmon_dir () {
            return FanBackend.locate_hp_hwmon_dir() ?? "";
        }

        private string mode_path () {
            return Path.build_filename(hwmon_dir(), "pwm1_enable");
        }

        private bool has_pwm_channel (uint16 fan) {
            return Fs.exists(raw_pwm_path(fan));
        }

        private string pwm_path (uint16 fan) {
            if (fan == 2 && !has_pwm_channel(2)) {
                return raw_pwm_path(1);
            }
            return raw_pwm_path(fan);
        }

        private string raw_pwm_path (uint16 fan) {
            return Path.build_filename(hwmon_dir(), "pwm%u".printf(fan));
        }
    }
}
