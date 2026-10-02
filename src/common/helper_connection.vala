namespace VictusControl {
    /**
     * Lazily connected, self-healing link to victusd.
     *
     * Any failed call drops the proxy, so the next call reconnects to a
     * restarted helper instead of reusing a stale one.
     */
    public class HelperConnection : Object {
        private ControlClient? client;

        public async Snapshot get_snapshot () throws Error {
            try {
                var connected = yield ensure_client();
                return yield connected.get_snapshot();
            } catch (Error error) {
                client = null;
                throw ControlErrors.readable(error);
            }
        }

        /**
         * Send an action, reconnecting and retrying once when the transport
         * failed. A helper rejection or a timeout is reported, not retried.
         */
        public async void send (ControlAction action) throws Error {
            try {
                yield send_once(action);
            } catch (Error first_error) {
                if (ControlErrors.is_helper_verdict(first_error) || first_error is IOError.TIMED_OUT) {
                    throw first_error;
                }
                yield send_once(action);
            }
        }

        private async void send_once (ControlAction action) throws Error {
            try {
                var connected = yield ensure_client();
                yield action.send(connected);
            } catch (Error error) {
                client = null;
                throw ControlErrors.readable(error);
            }
        }

        private async ControlClient ensure_client () throws Error {
            if (client == null) {
                client = yield ControlClient.open();
            }
            return client;
        }
    }
}
