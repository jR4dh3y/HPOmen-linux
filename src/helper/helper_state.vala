namespace VictusControl {
    /**
     * Persists the last hardware profile the user picked through victusd.
     *
     * hp-wmi resets Victus S boards to balanced at every probe and cannot
     * read the real profile back, so victusd restores this value on start.
     */
    public class HelperState : Object {
        private const string GROUP = "hardware";
        private const string PROFILE_KEY = "profile";

        public static string? load_profile () {
            var key_file = new KeyFile();
            try {
                key_file.load_from_file(HELPER_STATE_PATH, KeyFileFlags.NONE);
                return key_file.get_string(GROUP, PROFILE_KEY);
            } catch (Error error) {
                if (!(error is FileError.NOENT)) {
                    stderr.printf("victusd: cannot read %s: %s\n", HELPER_STATE_PATH, error.message);
                }
                return null;
            }
        }

        public static void save_profile (string profile) throws Error {
            var key_file = new KeyFile();
            key_file.set_string(GROUP, PROFILE_KEY, profile);
            Fs.ensure_parent_dir(HELPER_STATE_PATH);
            FileUtils.set_contents(HELPER_STATE_PATH, key_file.to_data());
        }
    }
}
