namespace VictusControl {
    /**
     * Shared display-formatting helpers used by both the GTK4 monitor
     * window and the GTK3 system-tray indicator.
     */
    public class Formatting : Object {
        public static string profile (string raw) {
            switch (raw.down()) {
            case "low-power":
                return "Low Power";
            case "cool":
                return "Cool";
            case "quiet":
                return "Quiet";
            case "balanced":
                return "Balanced";
            case "performance":
                return "Performance";
            default:
                return raw != "" ? raw : "Unavailable";
            }
        }

        public static string profiles (string[] list) {
            if (list.length == 0) {
                return "Unavailable";
            }
            string[] formatted = new string[list.length];
            for (var i = 0; i < list.length; i++) {
                formatted[i] = profile(list[i]);
            }
            return string.joinv(" / ", formatted);
        }

        public static string metric (int value, string suffix) {
            return value >= 0 ? "%d%s".printf(value, suffix) : "Unavailable";
        }

        public static string fan_mode (string mode) {
            switch (mode) {
            case "auto":
                return "Auto";
            case "max":
                return "Max";
            case "manual":
                return "Manual";
            case "unavailable":
                return "Unavailable";
            default:
                return "Unknown";
            }
        }

        public static string fan_level (int value, string unit) {
            if (value < 0) {
                return "Unavailable";
            }
            return unit == FAN_LEVEL_UNIT_PERCENT ? "%d%%".printf(value) : "%d RPM".printf(value);
        }

        public static bool is_low_power_profile (string profile) {
            var name = profile.down();
            return name == "low-power" || name == "quiet" || name == "cool";
        }

        public static bool has_profile (string[] profiles, string name) {
            foreach (var profile in profiles) {
                if (profile.down() == name) {
                    return true;
                }
            }
            return false;
        }

        public static bool has_low_power_profile (string[] profiles) {
            foreach (var profile in profiles) {
                if (is_low_power_profile(profile)) {
                    return true;
                }
            }
            return false;
        }

        public static string fallback (string value) {
            return value != null && value != "" ? value : "Unavailable";
        }
    }
}
