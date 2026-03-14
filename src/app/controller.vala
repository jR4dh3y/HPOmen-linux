namespace VictusControl {
    /**
     * Manages the D-Bus connection to the victusd helper, periodic
     * polling, and dispatching user actions (profile changes, fan
     * mode switches, auto-policy toggles).
     *
     * UI widgets never talk to D-Bus directly — they subscribe to
     * signals emitted by this controller instead.
     */
    public class AppController : Object {
        /** Emitted after every successful snapshot fetch. */
        public signal void snapshot_updated (Snapshot snapshot);

        /** Emitted when the helper connection is lost. */
        public signal void connection_lost (string error_message);

        /** Emitted after an action fails. */
        public signal void action_failed (string error_message);

        private ControlClient? client;
        private AppConfig config;

        public AppController (AppConfig config) {
            this.config = config;
            try {
                client = new ControlClient();
            } catch (Error error) {
                warning("Failed to connect to helper on startup: %s", error.message);
            }
        }

        /** Begin the periodic poll timer. */
        public void start_polling () {
            refresh();
            Timeout.add_seconds(config.poll_interval_seconds, () => {
                refresh();
                return true;
            });
        }

        /** Request a hardware-profile change. */
        public void set_profile (string profile) {
            try {
                ensure_client();
                client.set_hardware_profile(profile);
                refresh();
            } catch (Error error) {
                action_failed(error.message);
            }
        }

        /** Toggle the temperature-driven auto-policy. */
        public void set_auto_policy (bool enabled) {
            try {
                ensure_client();
                client.set_auto_policy(enabled);
                refresh();
            } catch (Error error) {
                action_failed(error.message);
            }
        }

        /** Switch fan mode (auto / max). */
        public void set_fan_mode (string mode) {
            try {
                ensure_client();
                client.set_fan_mode(mode);
                refresh();
            } catch (Error error) {
                action_failed(error.message);
            }
        }

        /* ---- internals ---- */

        private void refresh () {
            try {
                ensure_client();
                var snapshot = client.get_snapshot();
                snapshot_updated(snapshot);
            } catch (Error error) {
                client = null;
                connection_lost(error.message);
            }
        }

        private void ensure_client () throws Error {
            if (client == null) {
                client = new ControlClient();
            }
        }
    }
}
