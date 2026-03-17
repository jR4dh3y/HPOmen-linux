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
            run_with_retry (() => { client.set_hardware_profile (profile); });
        }

        /** Toggle the temperature-driven auto-policy. */
        public void set_auto_policy (bool enabled) {
            run_with_retry (() => { client.set_auto_policy (enabled); });
        }

        /** Switch fan mode (auto / max). */
        public void set_fan_mode (string mode) {
            run_with_retry (() => { client.set_fan_mode (mode); });
        }

        /* ---- internals ---- */

        private delegate void ActionCall () throws Error;

        /**
         * Execute a D-Bus action, reconnecting once on failure.
         *
         * Handles stale proxy connections that occur when victusd
         * restarts between poll cycles.
         */
        private void run_with_retry (owned ActionCall action) {
            try {
                ensure_client ();
                action ();
                refresh ();
            } catch (Error first_error) {
                client = null;
                try {
                    ensure_client ();
                    action ();
                    refresh ();
                } catch (Error retry_error) {
                    action_failed (retry_error.message);
                }
            }
        }

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
