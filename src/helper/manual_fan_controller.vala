namespace VictusControl {
    /**
     * Owns the manual fan levels victusd is holding.
     *
     * Drivers whose firmware forgets manual targets get them rewritten
     * every MANUAL_FAN_REAPPLY_SECONDS; upstream PWM refreshes in-kernel.
     */
    public class ManualFanController : Object {
        private HardwareBackend backend;
        private HardwareWorker worker;
        private uint source_id = 0;

        private int fan1_level = -1;
        private int fan2_level = -1;

        public ManualFanController (HardwareBackend backend, HardwareWorker worker) {
            this.backend = backend;
            this.worker = worker;
        }

        public async void set_fan_levels (uint16 fan1, uint16 fan2) throws Error {
            var needs_reapply = false;
            yield worker.run(() => {
                needs_reapply = backend.set_fan_levels(fan1, fan2);
            });
            fan1_level = fan1;
            fan2_level = fan2;
            if (needs_reapply) {
                start_reapply();
            } else {
                stop_reapply();
            }
        }

        /** Forget held levels after the user leaves manual mode. */
        public void release () {
            stop_reapply();
            fan1_level = -1;
            fan2_level = -1;
        }

        private void start_reapply () {
            if (source_id != 0) {
                return;
            }
            source_id = Timeout.add_seconds(MANUAL_FAN_REAPPLY_SECONDS, () => {
                reapply.begin();
                return Source.CONTINUE;
            });
        }

        private void stop_reapply () {
            if (source_id != 0) {
                Source.remove(source_id);
                source_id = 0;
            }
        }

        private async void reapply () {
            if (fan1_level < 0 || fan2_level < 0) {
                return;
            }
            var fan1 = (uint16) fan1_level;
            var fan2 = (uint16) fan2_level;
            try {
                yield worker.run(() => {
                    backend.set_fan_levels(fan1, fan2);
                });
            } catch (Error error) {
                stderr.printf("victusd: manual fan reapply failed: %s\n", error.message);
            }
        }
    }
}
