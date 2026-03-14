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
                root.set_object_member("hp_hwmon", hp);
            }

            return root;
        }

        public static Json.Object safe_hp_wmi () {
            var root = inventory();
            var findings = new Json.Object();
            findings.set_boolean_member("can_direct_fan_control", false);
            findings.set_string_member(
                "fan_control_reason",
                "Linux hp_wmi exposes fan RPM telemetry here, but no validated direct fan write path is implemented."
            );
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

        /* locate_hp_hwmon_dir() lives in FanBackend — no local copy needed. */
    }
}
