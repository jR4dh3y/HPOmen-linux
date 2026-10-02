namespace VictusControl {
    public class ProbeEngine : Object {
        private const string[] HWMON_ATTRIBUTES = {
            "fan1_input", "fan2_input", "fan1_max", "fan2_max", "fan1_target", "fan2_target",
            "pwm1_enable", "pwm1", "pwm2"
        };
        private const string[] SAFE_FINDING_KEYS = {
            "can_direct_fan_control", "fan_level_unit", "fan_control_reason"
        };

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
            hardware_profile.set_string_member("path", PlatformProfile.profile_path() ?? "");
            hardware_profile.set_string_member("choices_path", PlatformProfile.choices_path() ?? "");
            hardware_profile.set_string_member("active", backend.get_active_hardware_profile());
            root.set_object_member("hp_wmi_hardware_profile", hardware_profile);
            root.set_boolean_member("hp_wmi_out_of_tree", hp_wmi_out_of_tree());
            var gpu_mux_mode = Fs.read_text(HP_WMI_GPU_MUX_MODE_PATH);
            if (gpu_mux_mode != null) {
                root.set_string_member("gpu_mux_mode", gpu_mux_mode);
            }

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
                foreach (var name in HWMON_ATTRIBUTES) {
                    var value = Fs.read_text(Path.build_filename(hp_hwmon, name));
                    if (value != null) {
                        hp.set_string_member(name, value);
                    }
                }
                root.set_object_member("hp_hwmon", hp);
            }
            root.set_object_member("snapshot", backend.read_snapshot().to_json_object());

            return root;
        }

        public static Json.Object safe_hp_wmi () {
            var root = inventory();
            var snapshot = root.get_object_member("snapshot");
            var findings = new Json.Object();
            foreach (var key in SAFE_FINDING_KEYS) {
                findings.set_member(key, snapshot.get_member(key).copy());
            }
            root.set_object_member("findings", findings);
            return root;
        }

        public static bool hp_wmi_out_of_tree () {
            var taint = Fs.read_text(HP_WMI_MODULE_TAINT_PATH) ?? "";
            return taint.contains(MODULE_TAINT_OUT_OF_TREE);
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
    }
}
