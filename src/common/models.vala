namespace VictusControl {
    /**
     * Hardware state shared between victusd, the GTK window, the tray, and the probe.
     *
     * Every property crosses D-Bus under its snake_case name, so adding a
     * property is the whole contract change.
     */
    public class Snapshot : Object {
        public string product_name { get; set; default = ""; }
        public string board_name { get; set; default = ""; }
        public string bios_version { get; set; default = ""; }
        public string active_hardware_profile { get; set; default = ""; }
        public string[] available_hardware_profiles { get; set; default = {}; }
        public bool can_set_hardware_profile { get; set; default = false; }
        public int fan1_rpm { get; set; default = -1; }
        public int fan2_rpm { get; set; default = -1; }
        public int cpu_temp_c { get; set; default = -1; }
        public int gpu_temp_c { get; set; default = -1; }
        public int max_temp_c { get; set; default = -1; }
        public bool can_read_rpm { get; set; default = false; }
        public bool can_read_temp { get; set; default = false; }
        public bool can_set_fan_mode { get; set; default = false; }
        public bool can_direct_fan_control { get; set; default = false; }
        public bool auto_policy_enabled { get; set; default = false; }
        public string active_fan_mode { get; set; default = "unknown"; }
        public string fan_control_reason { get; set; default = ""; }
        /* FAN_LEVEL_UNIT_RPM or FAN_LEVEL_UNIT_PERCENT; "" without manual control. */
        public string fan_level_unit { get; set; default = ""; }
        public int fan1_level_max { get; set; default = -1; }
        public int fan2_level_max { get; set; default = -1; }
        /* Current manual levels read back from the driver; -1 when unreadable. */
        public int fan1_level { get; set; default = -1; }
        public int fan2_level { get; set; default = -1; }
        public string helper_state { get; set; default = "disconnected"; }

        public HashTable<string, Variant> to_variant_dict () {
            var dict = new HashTable<string, Variant>(str_hash, str_equal);
            foreach (var spec in get_class().list_properties()) {
                var value = Value(spec.value_type);
                get_property(spec.name, ref value);
                dict.insert(key_for(spec), to_variant(value));
            }
            return dict;
        }

        public Json.Object to_json_object () {
            var object = new Json.Object();
            foreach (var spec in get_class().list_properties()) {
                var value = Value(spec.value_type);
                get_property(spec.name, ref value);
                object.set_member(key_for(spec), Json.gvariant_serialize(to_variant(value)));
            }
            return object;
        }

        public static Snapshot from_variant_dict (Variant dict) {
            var snapshot = new Snapshot();
            foreach (var spec in snapshot.get_class().list_properties()) {
                var variant = dict.lookup_value(key_for(spec), null);
                if (variant != null) {
                    snapshot.set_from_variant(spec, variant);
                }
            }
            return snapshot;
        }

        private void set_from_variant (ParamSpec spec, Variant variant) {
            var value = Value(spec.value_type);
            if (spec.value_type == typeof(string) && variant.is_of_type(VariantType.STRING)) {
                value.set_string(variant.get_string());
            } else if (spec.value_type == typeof(int) && variant.is_of_type(VariantType.INT32)) {
                value.set_int(variant.get_int32());
            } else if (spec.value_type == typeof(bool) && variant.is_of_type(VariantType.BOOLEAN)) {
                value.set_boolean(variant.get_boolean());
            } else if (spec.value_type == typeof(string[]) && variant.is_of_type(VariantType.STRING_ARRAY)) {
                value.set_boxed(variant.dup_strv());
            } else {
                return;
            }
            set_property(spec.name, value);
        }

        private static Variant to_variant (Value value) {
            if (value.holds(typeof(string))) {
                return new Variant.string(value.get_string() ?? "");
            }
            if (value.holds(typeof(int))) {
                return new Variant.int32(value.get_int());
            }
            if (value.holds(typeof(bool))) {
                return new Variant.boolean(value.get_boolean());
            }
            /* A boxed strv carries no Vala length, so walk it to its NULL terminator. */
            var builder = new VariantBuilder(VariantType.STRING_ARRAY);
            unowned string[]? list = (string[]?) value.get_boxed();
            for (int index = 0; list != null && list[index] != null; index++) {
                builder.add("s", list[index]);
            }
            return builder.end();
        }

        private static string key_for (ParamSpec spec) {
            return spec.name.replace("-", "_");
        }
    }
}
