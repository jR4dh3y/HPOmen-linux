namespace VictusControl {
    public class AppConfig : Object {
        public uint poll_interval_seconds { get; set; default = DEFAULT_POLL_INTERVAL_SECONDS; }
        public bool hide_unsupported_fan_controls { get; set; default = false; }

        public static AppConfig load () {
            var config = new AppConfig();
            var path = config_path();
            if (!Fs.exists(path)) {
                return config;
            }
            var key_file = new KeyFile();
            try {
                key_file.load_from_file(path, KeyFileFlags.NONE);
                var interval = key_file.get_integer("ui", "poll_interval_seconds");
                config.poll_interval_seconds = interval >= 1 ? (uint) interval : DEFAULT_POLL_INTERVAL_SECONDS;
                config.hide_unsupported_fan_controls = key_file.get_boolean("ui", "hide_unsupported_fan_controls");
            } catch (Error error) {
            }
            return config;
        }

        public void save () {
            var key_file = new KeyFile();
            key_file.set_integer("ui", "poll_interval_seconds", (int) poll_interval_seconds);
            key_file.set_boolean("ui", "hide_unsupported_fan_controls", hide_unsupported_fan_controls);
            var path = config_path();
            Fs.ensure_parent_dir(path);
            try {
                FileUtils.set_contents(path, key_file.to_data());
            } catch (Error error) {
                warning("Failed to save config: %s", error.message);
            }
        }

        private static string config_path () {
            return Path.build_filename(Environment.get_user_config_dir(), USER_CONFIG_RELATIVE_PATH);
        }
    }
}
