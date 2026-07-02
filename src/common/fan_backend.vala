namespace VictusControl {
    /**
     * Fan and hwmon sensor operations via sysfs.
     *
     * Handles fan mode control (auto/max), RPM reads, and
     * HP-specific hwmon directory discovery.
     */
    public class FanBackend : Object {
        private const string FAN_MODE_AUTO = "auto";
        private const string FAN_MODE_MANUAL = "manual";
        private const string FAN_MODE_MAX = "max";

        public void set_fan_mode (string requested) throws Error {
            var hwmon_dir = locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                throw new ControlError.UNSUPPORTED("HP fan mode control is unavailable on this host.");
            }

            string value;
            switch (requested) {
            case FAN_MODE_AUTO:
                value = SYSFS_FAN_MODE_AUTO;
                break;
            case FAN_MODE_MANUAL:
                set_manual_mode();
                return;
            case FAN_MODE_MAX:
                value = SYSFS_FAN_MODE_MAX;
                break;
            default:
                throw new ControlError.INVALID_ARGUMENT("Unsupported fan mode: %s".printf(requested));
            }

            var path = Path.build_filename(hwmon_dir, "pwm1_enable");
            if (!Fs.exists(path)) {
                throw new ControlError.UNSUPPORTED("HP fan mode control is unavailable on this host.");
            }

            Fs.write_text(path, value);
        }

        public void read_fan_speeds (Snapshot snapshot) {
            var hwmon_dir = locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                snapshot.can_read_rpm = false;
                return;
            }

            snapshot.fan1_rpm = Fs.read_int(Path.build_filename(hwmon_dir, "fan1_input"));
            snapshot.fan2_rpm = Fs.read_int(Path.build_filename(hwmon_dir, "fan2_input"));
            snapshot.fan1_max_rpm = read_fan_max_rpm(1);
            snapshot.fan2_max_rpm = read_fan_max_rpm(2);
            snapshot.can_read_rpm = snapshot.fan1_rpm >= 0 || snapshot.fan2_rpm >= 0;
        }

        public void read_fan_mode (Snapshot snapshot) {
            var hwmon_dir = locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                snapshot.can_set_fan_mode = false;
                snapshot.active_fan_mode = "unavailable";
                return;
            }

            var path = Path.build_filename(hwmon_dir, "pwm1_enable");
            if (!Fs.exists(path)) {
                snapshot.can_set_fan_mode = false;
                snapshot.active_fan_mode = "unavailable";
                return;
            }

            snapshot.can_set_fan_mode = true;
            switch (Fs.read_int(path)) {
            case SYSFS_FAN_MODE_AUTO_INT:
                snapshot.active_fan_mode = FAN_MODE_AUTO;
                break;
            case SYSFS_FAN_MODE_MANUAL_INT:
                snapshot.active_fan_mode = FAN_MODE_MANUAL;
                break;
            case SYSFS_FAN_MODE_MAX_INT:
                snapshot.active_fan_mode = FAN_MODE_MAX;
                break;
            default:
                snapshot.active_fan_mode = "unknown";
                break;
            }
        }

        public static string? locate_hp_hwmon_dir () {
            foreach (var dir in Fs.list_directories(HP_WMI_HWMON_PATH)) {
                if (Fs.exists(Path.build_filename(dir, "fan1_input")) || Fs.exists(Path.build_filename(dir, "fan2_input"))) {
                    return dir;
                }
            }
            return null;
        }

        public static uint16 read_fan_max_rpm (uint16 fan) {
            var hwmon_dir = locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                return MANUAL_FAN_MAX_RPM_FALLBACK;
            }
            var value = Fs.read_int(Path.build_filename(hwmon_dir, "fan%u_max".printf(fan)));
            if (value <= 0 || value > uint16.MAX) {
                return MANUAL_FAN_MAX_RPM_FALLBACK;
            }
            return (uint16) value;
        }

        private void set_manual_mode () throws Error {
            string reason;
            var pwm = new FanPwmBackend();
            if (pwm.has_manual_pwm_control(out reason)) {
                pwm.set_manual_mode();
                return;
            }
            new FanTargetBackend().set_manual_mode();
        }

    }
}
