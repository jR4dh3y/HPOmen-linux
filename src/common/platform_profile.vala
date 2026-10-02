namespace VictusControl {
    /**
     * HP WMI platform-profile class device under the hp-wmi platform device.
     */
    public class PlatformProfile : Object {
        public static string? locate_dir () {
            foreach (var dir in Fs.list_directories(HP_WMI_PLATFORM_PROFILE_DIR)) {
                if (Path.get_basename(dir).has_prefix(PLATFORM_PROFILE_DIR_PREFIX)
                    && Fs.exists(Path.build_filename(dir, "profile"))) {
                    return dir;
                }
            }
            return null;
        }

        public static string? profile_path () {
            var dir = locate_dir();
            return dir != null ? Path.build_filename(dir, "profile") : null;
        }

        public static string? choices_path () {
            var dir = locate_dir();
            return dir != null ? Path.build_filename(dir, "choices") : null;
        }

        public static string[] choices () {
            var path = choices_path();
            var raw = path != null ? Fs.read_text(path) : null;
            return raw != null && raw != "" ? raw.split(" ") : new string[0];
        }

        public static string active () {
            var path = profile_path();
            return (path != null ? Fs.read_text(path) : null) ?? "unknown";
        }

        public static void write (string profile) throws Error {
            var path = profile_path();
            if (path == null) {
                throw new ControlError.UNSUPPORTED("HP WMI platform profile is unavailable on this host.");
            }
            Fs.write_text(path, profile);
        }
    }
}
