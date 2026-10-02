namespace VictusControl {
    /**
     * Serializes user actions to victusd without blocking the caller.
     *
     * One action is in flight at a time. A queued action is replaced by a
     * newer action of the same kind, so rapid clicks collapse into the
     * latest request instead of replaying every intermediate one.
     */
    public class ActionQueue : Object {
        /** Emitted when an action is queued (true) and when it settles or is superseded (false). */
        public signal void pending_changed (ControlAction action, bool pending);

        public signal void failed (ControlAction action, string error_message);

        /** Emitted when the queue empties, so callers can refresh state once. */
        public signal void drained ();

        private HelperConnection connection;
        private Gee.ArrayList<ControlAction> queued = new Gee.ArrayList<ControlAction>();
        private bool running = false;

        public ActionQueue (HelperConnection connection) {
            this.connection = connection;
        }

        public void submit (ControlAction action) {
            for (int index = 0; index < queued.size; index++) {
                if (queued[index].kind == action.kind) {
                    var superseded = queued.remove_at(index);
                    pending_changed(superseded, false);
                    break;
                }
            }
            queued.add(action);
            pending_changed(action, true);
            if (!running) {
                drain.begin();
            }
        }

        private async void drain () {
            running = true;
            while (queued.size > 0) {
                var action = queued.remove_at(0);
                try {
                    yield connection.send(action);
                } catch (Error error) {
                    failed(action, error.message);
                }
                pending_changed(action, false);
            }
            running = false;
            drained();
        }
    }
}
