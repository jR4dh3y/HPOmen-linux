namespace VictusControl {
    /**
     * HP WMI hardware profile and temperature backend.
     *
     * Fan/hwmon operations (fan mode, RPM, hwmon discovery) live in
     * FanBackend to keep each file focused and under 150 LOC.
     */
    public class HardwareBackend : Object {
        private FanBackend fan = new FanBackend();
        private FanTargetBackend fan_targets = new FanTargetBackend();
        private FanPwmBackend fan_pwm = new FanPwmBackend();

        public string[] get_hardware_profiles () {
            var raw = Fs.read_text(HP_WMI_HARDWARE_PROFILE_CHOICES_PATH);
            return raw != null ? raw.split(" ") : new string[0];
        }

        public string get_active_hardware_profile () {
            return Fs.read_text(HP_WMI_HARDWARE_PROFILE_PATH) ?? "unknown";
        }

        public bool get_direct_fan_capability (out string reason) {
            if (fan_pwm.has_manual_pwm_control(out reason)) {
                return true;
            }
            if (fan_targets.has_manual_rpm_control(out reason)) {
                return true;
            }
            string saved_reason;
            ProbeEngine.load_direct_fan_capability(out saved_reason);
            if (reason == "" && saved_reason != "") {
                reason = saved_reason;
            }
            return false;
        }

        public Snapshot read_snapshot (bool auto_policy_enabled = false) {
            var snapshot = new Snapshot();
            snapshot.product_name = Fs.read_text(DMI_PRODUCT_NAME_PATH) ?? "";
            snapshot.board_name = Fs.read_text(DMI_BOARD_NAME_PATH) ?? "";
            snapshot.bios_version = Fs.read_text(DMI_BIOS_VERSION_PATH) ?? "";
            snapshot.active_hardware_profile = get_active_hardware_profile();
            snapshot.available_hardware_profiles = get_hardware_profiles();
            snapshot.can_set_hardware_profile = Fs.exists(HP_WMI_HARDWARE_PROFILE_PATH);
            snapshot.helper_state = "ready";
            snapshot.auto_policy_enabled = auto_policy_enabled;

            fan.read_fan_speeds(snapshot);
            fan.read_fan_mode(snapshot);
            read_temperatures(snapshot);

            string reason;
            snapshot.can_direct_fan_control = get_direct_fan_capability(out reason);
            snapshot.fan_control_reason = reason;

            return snapshot;
        }

        public void set_hardware_profile (string requested) throws Error {
            var choices = get_hardware_profiles();
            foreach (var profile in choices) {
                if (profile == requested) {
                    Fs.write_text(HP_WMI_HARDWARE_PROFILE_PATH, requested);
                    return;
                }
            }
            throw new ControlError.INVALID_ARGUMENT("Unsupported HP WMI hardware profile: %s".printf(requested));
        }

        public void set_fan_mode (string requested) throws Error {
            fan.set_fan_mode(requested);
        }

        public void set_fan_target (uint16 fan, uint16 rpm) throws Error {
            string reason;
            if (fan_pwm.has_manual_pwm_control(out reason)) {
                fan_pwm.set_manual_mode();
                fan_pwm.set_fan_target(fan, rpm);
                return;
            }
            fan_targets.set_manual_mode();
            fan_targets.set_fan_target(fan, rpm);
        }

        public void set_fan_levels (uint16 cpu, uint16 gpu) throws Error {
            string reason;
            if (fan_pwm.has_manual_pwm_control(out reason)) {
                fan_pwm.set_manual_mode();
                fan_pwm.set_fan_levels(cpu, gpu);
                return;
            }
            fan_targets.set_manual_mode();
            fan_targets.set_fan_levels(cpu, gpu);
        }

        public string choose_hardware_profile_for_policy (string requested) {
            var choices = get_hardware_profiles();
            foreach (var choice in choices) {
                if (choice == requested) {
                    return requested;
                }
            }
            if (requested == "low-power" || requested == "quiet" || requested == "cool") {
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
    }
}
