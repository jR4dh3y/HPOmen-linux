namespace VictusControl {
    public class ProbeEngine : Object {
        public static Json.Object inventory () {
            var root = new Json.Object();
            root.set_string_member("generated_at", Fs.now_iso8601_utc());
            root.set_boolean_member("hp_wmi_present", Fs.exists(HP_WMI_PATH));
            root.set_string_member("product_name", Fs.read_text(DMI_PRODUCT_NAME_PATH) ?? "");
            root.set_string_member("board_name", Fs.read_text(DMI_BOARD_NAME_PATH) ?? "");
            root.set_string_member("bios_version", Fs.read_text(DMI_BIOS_VERSION_PATH) ?? "");

            var profiles = new Json.Array();
            var backend = new HardwareBackend();
            foreach (var profile in backend.get_hardware_profiles()) {
                profiles.add_string_element(profile);
            }
            root.set_array_member("hardware_profiles", profiles);
            /* Legacy alias — same data under the old key for backward compat. */
            root.set_array_member("platform_profiles", profiles);

            var hardware_profile = new Json.Object();
            hardware_profile.set_string_member("path", HP_WMI_HARDWARE_PROFILE_PATH);
            hardware_profile.set_string_member("choices_path", HP_WMI_HARDWARE_PROFILE_CHOICES_PATH);
            hardware_profile.set_string_member("active", backend.get_active_hardware_profile());
            root.set_object_member("hp_wmi_hardware_profile", hardware_profile);

            var wmi_devices = new Json.Array();
            foreach (var path in Fs.list_directories(WMI_DEVICES_PATH)) {
                var object = new Json.Object();
                object.set_string_member("path", path);
                object.set_string_member("guid", Fs.read_text(Path.build_filename(path, "guid")) ?? "");
                var object_id = Fs.read_text(Path.build_filename(path, "object_id"));
                if (object_id != null) {
                    object.set_string_member("object_id", object_id);
                }
                var notify_id = Fs.read_text(Path.build_filename(path, "notify_id"));
                if (notify_id != null) {
                    object.set_string_member("notify_id", notify_id);
                }
                var setable = Fs.read_text(Path.build_filename(path, "setable"));
                if (setable != null) {
                    object.set_string_member("setable", setable);
                }
                wmi_devices.add_object_element(object);
            }
            root.set_array_member("wmi_devices", wmi_devices);

            var hp_hwmon = FanBackend.locate_hp_hwmon_dir();
            if (hp_hwmon != null) {
                var hp = new Json.Object();
                hp.set_string_member("path", hp_hwmon);
                hp.set_int_member("fan1_rpm", Fs.read_int(Path.build_filename(hp_hwmon, "fan1_input")));
                hp.set_int_member("fan2_rpm", Fs.read_int(Path.build_filename(hp_hwmon, "fan2_input")));
                var pwm1_enable = Fs.read_text(Path.build_filename(hp_hwmon, "pwm1_enable"));
                if (pwm1_enable != null) {
                    hp.set_string_member("pwm1_enable", pwm1_enable);
                }
                var fan1_target = Path.build_filename(hp_hwmon, "fan1_target");
                var fan2_target = Path.build_filename(hp_hwmon, "fan2_target");
                var pwm1 = Path.build_filename(hp_hwmon, "pwm1");
                var pwm2 = Path.build_filename(hp_hwmon, "pwm2");
                hp.set_boolean_member("fan1_target_present", Fs.exists(fan1_target));
                hp.set_boolean_member("fan2_target_present", Fs.exists(fan2_target));
                hp.set_boolean_member("pwm1_present", Fs.exists(pwm1));
                hp.set_boolean_member("pwm2_present", Fs.exists(pwm2));
                add_optional_int(hp, "pwm1", pwm1);
                add_optional_int(hp, "pwm2", pwm2);
                add_optional_int(hp, "fan1_max", Path.build_filename(hp_hwmon, "fan1_max"));
                add_optional_int(hp, "fan2_max", Path.build_filename(hp_hwmon, "fan2_max"));
                string reason;
                var manual_pwm_available = new FanPwmBackend().has_manual_pwm_control(out reason);
                var manual_rpm_available = new FanTargetBackend().has_manual_rpm_control(out reason);
                hp.set_boolean_member("manual_pwm_control_available", manual_pwm_available);
                hp.set_boolean_member("manual_rpm_control_available", manual_rpm_available);
                hp.set_boolean_member("manual_control_available", manual_pwm_available || manual_rpm_available);
                root.set_object_member("hp_hwmon", hp);
            }

            return root;
        }

        public static Json.Object safe_hp_wmi () {
            var root = inventory();
            var findings = new Json.Object();
            string reason;
            var available = new FanPwmBackend().has_manual_pwm_control(out reason);
            if (!available) {
                available = new FanTargetBackend().has_manual_rpm_control(out reason);
            }
            findings.set_boolean_member("can_direct_fan_control", available);
            findings.set_string_member("fan_control_reason", reason);
            root.set_object_member("findings", findings);
            return root;
        }

        public static bool load_direct_fan_capability (out string reason) {
            reason = "Linux hp_wmi exposes telemetry, but no validated direct fan-control path has been saved for this machine.";
            var parser = new Json.Parser();
            try {
                parser.load_from_file(PROBE_STATE_PATH);
                var root = parser.get_root().get_object();
                if (root.has_member("findings")) {
                    var findings = root.get_object_member("findings");
                    reason = findings.get_string_member_with_default("fan_control_reason", reason);
                    return findings.get_boolean_member_with_default("can_direct_fan_control", false);
                }
            } catch (Error error) {
            }
            return false;
        }

        public static void save_probe_state (Json.Object object) throws Error {
            Fs.ensure_parent_dir(PROBE_STATE_PATH);
            var root = new Json.Node(Json.NodeType.OBJECT);
            root.set_object(object);
            var generator = new Json.Generator();
            generator.pretty = true;
            generator.set_root(root);
            generator.to_file(PROBE_STATE_PATH);
        }

        public static Json.Object run_named (string name) throws Error {
            switch (name) {
            case "inventory":
                return inventory();
            case "safe-hp-wmi":
                return safe_hp_wmi();
            default:
                throw new ControlError.INVALID_ARGUMENT("Unknown probe: %s".printf(name));
            }
        }

        private static void add_optional_int (Json.Object object, string key, string path) {
            var value = Fs.read_int(path);
            if (value >= 0) {
                object.set_int_member(key, value);
            }
        }

        /* locate_hp_hwmon_dir() lives in FanBackend — no local copy needed. */
    }
}
