namespace VictusControl {
    /**
     * Temperature-driven automatic hardware-profile policy engine.
     *
     * When enabled, periodically reads the current thermal state and
     * selects a hardware profile based on configurable temperature
     * thresholds defined in constants.vala.
     */
    public class AutoPolicyController : Object {
        private HardwareBackend backend;
        private uint source_id = 0;
        public bool enabled { get; private set; default = false; }

        public AutoPolicyController (HardwareBackend backend) {
            this.backend = backend;
        }

        public void set_active (bool enabled) {
            this.enabled = enabled;
            if (!enabled) {
                if (source_id != 0) {
                    Source.remove(source_id);
                    source_id = 0;
                }
                return;
            }
            if (source_id == 0) {
                source_id = Timeout.add_seconds(DEFAULT_AUTO_POLICY_INTERVAL_SECONDS, () => {
                    apply_once();
                    return this.enabled;
                });
            }
            apply_once();
        }

        private void apply_once () {
            var snapshot = backend.read_snapshot(true);
            if (!snapshot.can_set_hardware_profile || snapshot.max_temp_c < 0) {
                return;
            }
            string target;
            if (snapshot.max_temp_c >= AUTO_POLICY_TEMP_HIGH) {
                target = "performance";
            } else if (snapshot.max_temp_c >= AUTO_POLICY_TEMP_MID) {
                target = "balanced";
            } else {
                target = "quiet";
            }
            try {
                backend.set_hardware_profile(backend.choose_hardware_profile_for_policy(target));
            } catch (Error error) {
                warning("Auto policy failed: %s", error.message);
            }
        }
    }
}
