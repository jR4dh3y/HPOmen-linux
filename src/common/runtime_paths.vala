namespace VictusControl {
    /**
     * Runtime helpers for locating installed binaries and shared assets.
     *
     * This avoids relying on PATH lookups, which can resolve stale copies
     * from /usr/local before the packaged binaries in /usr/bin.
     */
    public class RuntimePaths : Object {
        private const string MONITOR_BINARY_NAME = "victus-control";
        private const string TRAY_BINARY_NAME = "victus-tray";
        private const string HELPER_BINARY_NAME = "victusd";
        private const string SHARED_DATA_DIR_NAME = "victus-control";
        private const string STYLE_CSS_NAME = "style.css";

        public static string monitor_binary () {
            return installed_binary_path(MONITOR_BINARY_NAME);
        }

        public static string tray_binary () {
            return installed_binary_path(TRAY_BINARY_NAME);
        }

        public static string helper_binary () {
            return installed_binary_path(HELPER_BINARY_NAME);
        }

        public static string style_css () {
            return Path.build_filename(shared_data_dir(), STYLE_CSS_NAME);
        }

        public static string shared_data_dir () {
            return Path.build_filename(install_prefix(), "share", SHARED_DATA_DIR_NAME);
        }

        public static string install_prefix () {
            var exe_dir = executable_dir();
            var prefix = Path.get_dirname(exe_dir);

            if (prefix != null && prefix != "." && prefix != "/") {
                return prefix;
            }

            return "/usr";
        }

        private static string installed_binary_path (string binary_name) {
            return Path.build_filename(install_prefix(), "bin", binary_name);
        }

        private static string executable_dir () {
            try {
                var exe_path = FileUtils.read_link("/proc/self/exe");
                var dir = Path.get_dirname(exe_path);
                if (dir != null && dir != ".") {
                    return dir;
                }
            } catch (FileError error) {
            }

            var resolved = Environment.find_program_in_path(MONITOR_BINARY_NAME);
            if (resolved != null) {
                var dir = Path.get_dirname(resolved);
                if (dir != null && dir != ".") {
                    return dir;
                }
            }

            return "/usr/bin";
        }
    }
}
