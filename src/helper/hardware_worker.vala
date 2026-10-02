namespace VictusControl {
    public delegate void HardwareJob () throws Error;

    /**
     * Runs every HardwareBackend call on one background thread.
     *
     * WMI-backed sysfs writes take around a second. Running them here keeps
     * the bus loop free to answer other clients and timers, and the single
     * thread keeps hardware access strictly ordered.
     */
    public class HardwareWorker : Object {
        private AsyncQueue<WorkItem> queue = new AsyncQueue<WorkItem>();
        private Thread<bool> thread;

        public HardwareWorker () {
            thread = new Thread<bool>("victusd-hardware", process);
        }

        /** Run `job` on the worker thread and resume on the main loop when it finishes. */
        public async void run (owned HardwareJob job) throws Error {
            var item = new WorkItem((owned) job, run.callback);
            queue.push(item);
            yield;
            if (item.error != null) {
                throw item.error.copy();
            }
        }

        private bool process () {
            while (true) {
                var item = queue.pop();
                try {
                    item.job();
                } catch (Error error) {
                    item.error = ControlErrors.to_control_error(error);
                }
                Idle.add((owned) item.resume);
            }
        }
    }

    private class WorkItem {
        public HardwareJob job;
        public SourceFunc resume;
        public Error? error = null;

        public WorkItem (owned HardwareJob job, owned SourceFunc resume) {
            this.job = (owned) job;
            this.resume = (owned) resume;
        }
    }
}
