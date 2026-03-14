namespace VictusControl {
    /**
     * Shared display-formatting helpers used by both the GTK4 monitor
     * window and the GTK3 system-tray indicator.
     */
    public class Formatting : Object {
        public static string profile (string raw) {
            switch (raw.down()) {
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
            case "unavailable":
                return "Unavailable";
            default:
                return "Unknown";
            }
        }

        public static string fallback (string value) {
            return value != null && value != "" ? value : "Unavailable";
        }
    }
}
