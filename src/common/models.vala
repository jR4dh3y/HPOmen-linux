namespace VictusControl {
    public class Snapshot : Object {
        public string product_name { get; set; default = ""; }
        public string board_name { get; set; default = ""; }
        public string bios_version { get; set; default = ""; }
        public string active_profile { get; set; default = ""; }
        public string[] available_profiles { get; set; default = {}; }
        public int fan1_rpm { get; set; default = -1; }
        public int fan2_rpm { get; set; default = -1; }
        public int cpu_temp_c { get; set; default = -1; }
        public int gpu_temp_c { get; set; default = -1; }
        public int max_temp_c { get; set; default = -1; }
        public bool can_read_rpm { get; set; default = false; }
        public bool can_read_temp { get; set; default = false; }
        public bool can_set_profile { get; set; default = false; }
        public bool can_direct_fan_control { get; set; default = false; }
        public bool auto_policy_enabled { get; set; default = false; }
        public string fan_control_reason { get; set; default = ""; }
        public string helper_state { get; set; default = "disconnected"; }

        public HashTable<string, Variant> to_variant_dict () {
            var dict = new HashTable<string, Variant>(str_hash, str_equal);
            dict.insert("product_name", new Variant.string(product_name));
            dict.insert("board_name", new Variant.string(board_name));
            dict.insert("bios_version", new Variant.string(bios_version));
            dict.insert("active_profile", new Variant.string(active_profile));
            dict.insert("available_profiles", new Variant.strv(available_profiles));
            dict.insert("fan1_rpm", new Variant.int32(fan1_rpm));
            dict.insert("fan2_rpm", new Variant.int32(fan2_rpm));
            dict.insert("cpu_temp_c", new Variant.int32(cpu_temp_c));
            dict.insert("gpu_temp_c", new Variant.int32(gpu_temp_c));
            dict.insert("max_temp_c", new Variant.int32(max_temp_c));
            dict.insert("can_read_rpm", new Variant.boolean(can_read_rpm));
            dict.insert("can_read_temp", new Variant.boolean(can_read_temp));
            dict.insert("can_set_profile", new Variant.boolean(can_set_profile));
            dict.insert("can_direct_fan_control", new Variant.boolean(can_direct_fan_control));
            dict.insert("auto_policy_enabled", new Variant.boolean(auto_policy_enabled));
            dict.insert("fan_control_reason", new Variant.string(fan_control_reason));
            dict.insert("helper_state", new Variant.string(helper_state));
            return dict;
        }

        public Json.Object to_json_object () {
            var object = new Json.Object();
            object.set_string_member("product_name", product_name);
            object.set_string_member("board_name", board_name);
            object.set_string_member("bios_version", bios_version);
            object.set_string_member("active_profile", active_profile);
            var profiles = new Json.Array();
            foreach (var profile in available_profiles) {
                profiles.add_string_element(profile);
            }
            object.set_array_member("available_profiles", profiles);
            object.set_int_member("fan1_rpm", fan1_rpm);
            object.set_int_member("fan2_rpm", fan2_rpm);
            object.set_int_member("cpu_temp_c", cpu_temp_c);
            object.set_int_member("gpu_temp_c", gpu_temp_c);
            object.set_int_member("max_temp_c", max_temp_c);
            object.set_boolean_member("can_read_rpm", can_read_rpm);
            object.set_boolean_member("can_read_temp", can_read_temp);
            object.set_boolean_member("can_set_profile", can_set_profile);
            object.set_boolean_member("can_direct_fan_control", can_direct_fan_control);
            object.set_boolean_member("auto_policy_enabled", auto_policy_enabled);
            object.set_string_member("fan_control_reason", fan_control_reason);
            object.set_string_member("helper_state", helper_state);
            return object;
        }

        public static Snapshot from_variant_dict (Variant dict) {
            var snapshot = new Snapshot();
            snapshot.product_name = lookup_string(dict, "product_name", "");
            snapshot.board_name = lookup_string(dict, "board_name", "");
            snapshot.bios_version = lookup_string(dict, "bios_version", "");
            snapshot.active_profile = lookup_string(dict, "active_profile", "");
            snapshot.available_profiles = lookup_strv(dict, "available_profiles");
            snapshot.fan1_rpm = lookup_int(dict, "fan1_rpm", -1);
            snapshot.fan2_rpm = lookup_int(dict, "fan2_rpm", -1);
            snapshot.cpu_temp_c = lookup_int(dict, "cpu_temp_c", -1);
            snapshot.gpu_temp_c = lookup_int(dict, "gpu_temp_c", -1);
            snapshot.max_temp_c = lookup_int(dict, "max_temp_c", -1);
            snapshot.can_read_rpm = lookup_bool(dict, "can_read_rpm", false);
            snapshot.can_read_temp = lookup_bool(dict, "can_read_temp", false);
            snapshot.can_set_profile = lookup_bool(dict, "can_set_profile", false);
            snapshot.can_direct_fan_control = lookup_bool(dict, "can_direct_fan_control", false);
            snapshot.auto_policy_enabled = lookup_bool(dict, "auto_policy_enabled", false);
            snapshot.fan_control_reason = lookup_string(dict, "fan_control_reason", "");
            snapshot.helper_state = lookup_string(dict, "helper_state", "disconnected");
            return snapshot;
        }

        private static string lookup_string (Variant dict, string key, string fallback) {
            var value = dict.lookup_value(key, VariantType.STRING);
            return value != null ? value.get_string() : fallback;
        }

        private static int lookup_int (Variant dict, string key, int fallback) {
            var value = dict.lookup_value(key, VariantType.INT32);
            return value != null ? value.get_int32() : fallback;
        }

        private static bool lookup_bool (Variant dict, string key, bool fallback) {
            var value = dict.lookup_value(key, VariantType.BOOLEAN);
            return value != null ? value.get_boolean() : fallback;
        }

        private static string[] lookup_strv (Variant dict, string key) {
            var value = dict.lookup_value(key, new VariantType("as"));
            return value != null ? value.dup_strv() : new string[0];
        }
    }
}
