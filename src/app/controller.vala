namespace VictusControl {
    /**
     * Owns the victusd connection for the monitor window.
     *
     * Every helper call is asynchronous: actions go through ActionQueue and
     * polling never overlaps itself, so the GTK main loop never waits on
     * hardware. UI widgets never talk to D-Bus directly — they subscribe to
     * signals emitted by this controller instead.
     */
    public class AppController : Object {
        /** Emitted after every successful snapshot fetch. */
        public signal void snapshot_updated (Snapshot snapshot);

        /** Emitted when the helper connection is lost. */
        public signal void connection_lost (string error_message);

        /** Emitted after an action fails. */
        public signal void action_failed (string error_message);

        /** Emitted when a requested action starts or stops waiting on the helper. */
        public signal void action_pending (ControlAction action, bool pending);

        private AppConfig config;
        private HelperConnection connection = new HelperConnection();
        private ActionQueue actions;
        private bool refreshing = false;
        private bool refresh_requested = false;

        public AppController (AppConfig config) {
            this.config = config;
            actions = new ActionQueue(connection);
            actions.pending_changed.connect((action, pending) => action_pending(action, pending));
            actions.failed.connect((action, message) => action_failed(message));
            actions.drained.connect(() => refresh.begin());
        }

        /** Begin the periodic poll timer. */
        public void start_polling () {
            refresh.begin();
            Timeout.add_seconds(config.poll_interval_seconds, () => {
                refresh.begin();
                return Source.CONTINUE;
            });
        }

        public void submit (ControlAction action) {
            actions.submit(action);
        }

        /**
         * Fetch one snapshot. A request made while a fetch is in flight
         * runs once afterwards, so post-action state is never skipped.
         */
        private async void refresh () {
            if (refreshing) {
                refresh_requested = true;
                return;
            }
            refreshing = true;
            do {
                refresh_requested = false;
                try {
                    snapshot_updated(yield connection.get_snapshot());
                } catch (Error error) {
                    connection_lost(error.message);
                }
            } while (refresh_requested);
            refreshing = false;
        }
    }
}
