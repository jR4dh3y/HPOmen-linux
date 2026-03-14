namespace VictusControl {
    public class HardwareBackend : Object {
        public string[] get_platform_profiles () {
            var raw = Fs.read_text(PLATFORM_PROFILE_CHOICES_PATH);
            return raw != null ? raw.split(" ") : new string[0];
        }

        public string get_active_platform_profile () {
            return Fs.read_text(PLATFORM_PROFILE_PATH) ?? "unknown";
        }

        public bool get_direct_fan_capability (out string reason) {
            return ProbeEngine.load_direct_fan_capability(out reason);
        }

        public Snapshot read_snapshot (bool auto_policy_enabled = false) {
            var snapshot = new Snapshot();
            snapshot.product_name = Fs.read_text(DMI_PRODUCT_NAME_PATH) ?? "";
            snapshot.board_name = Fs.read_text(DMI_BOARD_NAME_PATH) ?? "";
            snapshot.bios_version = Fs.read_text(DMI_BIOS_VERSION_PATH) ?? "";
            snapshot.active_profile = get_active_platform_profile();
            snapshot.available_profiles = get_platform_profiles();
            snapshot.can_set_profile = Fs.exists(PLATFORM_PROFILE_PATH);
            snapshot.helper_state = "ready";
            snapshot.auto_policy_enabled = auto_policy_enabled;

            read_fan_speeds(snapshot);
            read_temperatures(snapshot);

            string reason;
            snapshot.can_direct_fan_control = get_direct_fan_capability(out reason);
            snapshot.fan_control_reason = reason;

            return snapshot;
        }

        public void set_platform_profile (string requested) throws Error {
            var choices = get_platform_profiles();
            foreach (var profile in choices) {
                if (profile == requested) {
                    Fs.write_text(PLATFORM_PROFILE_PATH, requested);
                    return;
                }
            }
            throw new ControlError.INVALID_ARGUMENT("Unsupported platform profile: %s".printf(requested));
        }

        public string choose_profile_for_policy (string requested) {
            var choices = get_platform_profiles();
            foreach (var choice in choices) {
                if (choice == requested) {
                    return requested;
                }
            }
            if (requested == "quiet") {
                string[] fallback_profiles = { "cool", "quiet", "balanced" };
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

        private void read_fan_speeds (Snapshot snapshot) {
            var hwmon_dir = locate_hp_hwmon_dir();
            if (hwmon_dir == null) {
                snapshot.can_read_rpm = false;
                return;
            }

            snapshot.fan1_rpm = Fs.read_int(Path.build_filename(hwmon_dir, "fan1_input"));
            snapshot.fan2_rpm = Fs.read_int(Path.build_filename(hwmon_dir, "fan2_input"));
            snapshot.can_read_rpm = snapshot.fan1_rpm >= 0 || snapshot.fan2_rpm >= 0;
        }

        private void read_temperatures (Snapshot snapshot) {
            int max_temp = -1;
            foreach (var hwmon_dir in Fs.list_directories("/sys/class/hwmon")) {
                var name = Fs.read_text(Path.build_filename(hwmon_dir, "name")) ?? "";
                for (int index = 1; index <= 10; index++) {
                    var path = Path.build_filename(hwmon_dir, "temp%d_input".printf(index));
                    if (!Fs.exists(path)) {
                        continue;
                    }
                    var milli_c = Fs.read_int(path);
                    if (milli_c < 0) {
                        continue;
                    }
                    var temp_c = milli_c / 1000;
                    if (temp_c > max_temp) {
                        max_temp = temp_c;
                    }
                    if (name == "k10temp" && snapshot.cpu_temp_c < 0) {
                        snapshot.cpu_temp_c = temp_c;
                    }
                    if (name == "amdgpu" && snapshot.gpu_temp_c < 0) {
                        snapshot.gpu_temp_c = temp_c;
                    }
                }
            }
            snapshot.max_temp_c = max_temp;
            snapshot.can_read_temp = max_temp >= 0;
        }

        private string? locate_hp_hwmon_dir () {
            foreach (var dir in Fs.list_directories(HP_WMI_HWMON_PATH)) {
                if (Fs.exists(Path.build_filename(dir, "fan1_input")) || Fs.exists(Path.build_filename(dir, "fan2_input"))) {
                    return dir;
                }
            }
            return null;
        }
    }
}
