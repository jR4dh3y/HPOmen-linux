namespace VictusControl {
    /**
     * HP hwmon fan discovery, RPM reads, and pwm1_enable mode control.
     */
    public class FanBackend : Object {
        public const string MODE_AUTO = "auto";
        public const string MODE_MANUAL = "manual";
        public const string MODE_MAX = "max";

        public static string? locate_hp_hwmon_dir () {
            foreach (var dir in Fs.list_directories(HP_WMI_HWMON_PATH)) {
                if (Fs.exists(Path.build_filename(dir, "fan1_input")) || Fs.exists(Path.build_filename(dir, "fan2_input"))) {
                    return dir;
                }
            }
            return null;
        }

        public void read_fan_speeds (string? hwmon_dir, Snapshot snapshot) {
            if (hwmon_dir == null) {
                snapshot.can_read_rpm = false;
                return;
            }
            snapshot.fan1_rpm = Fs.read_int(Path.build_filename(hwmon_dir, "fan1_input"));
            snapshot.fan2_rpm = Fs.read_int(Path.build_filename(hwmon_dir, "fan2_input"));
            snapshot.can_read_rpm = snapshot.fan1_rpm >= 0 || snapshot.fan2_rpm >= 0;
        }

        public void read_fan_mode (string? hwmon_dir, Snapshot snapshot) {
            if (hwmon_dir == null || !Fs.exists(mode_path(hwmon_dir))) {
                snapshot.can_set_fan_mode = false;
                snapshot.active_fan_mode = "unavailable";
                return;
            }
            snapshot.can_set_fan_mode = true;
            switch (Fs.read_int(mode_path(hwmon_dir))) {
            case SYSFS_FAN_MODE_AUTO_INT:
                snapshot.active_fan_mode = MODE_AUTO;
                break;
            case SYSFS_FAN_MODE_MANUAL_INT:
                snapshot.active_fan_mode = MODE_MANUAL;
                break;
            case SYSFS_FAN_MODE_MAX_INT:
                snapshot.active_fan_mode = MODE_MAX;
                break;
            default:
                snapshot.active_fan_mode = "unknown";
                break;
            }
        }

        public void write_mode (string? hwmon_dir, string mode) throws Error {
            if (hwmon_dir == null || !Fs.exists(mode_path(hwmon_dir))) {
                throw new ControlError.UNSUPPORTED("HP fan mode control is unavailable on this host.");
            }
            switch (mode) {
            case MODE_AUTO:
                Fs.write_text(mode_path(hwmon_dir), SYSFS_FAN_MODE_AUTO);
                break;
            case MODE_MAX:
                Fs.write_text(mode_path(hwmon_dir), SYSFS_FAN_MODE_MAX);
                break;
            case MODE_MANUAL:
                enter_manual(hwmon_dir);
                break;
            default:
                throw new ControlError.INVALID_ARGUMENT("Unsupported fan mode: %s".printf(mode));
            }
        }

        /**
         * Switch to manual only when needed: upstream hp-wmi reseeds both
         * fans from their current RPM on every write of 1.
         */
        private void enter_manual (string hwmon_dir) throws Error {
            if (Fs.read_int(mode_path(hwmon_dir)) != SYSFS_FAN_MODE_MANUAL_INT) {
                Fs.write_text(mode_path(hwmon_dir), SYSFS_FAN_MODE_MANUAL);
            }
        }

        private static string mode_path (string hwmon_dir) {
            return Path.build_filename(hwmon_dir, "pwm1_enable");
        }
    }
}
