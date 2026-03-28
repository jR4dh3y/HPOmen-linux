namespace VictusControl {
    /**
     * Temperature-driven automatic hardware-profile policy engine.
     *
     * When enabled, periodically reads the current thermal state and
     * selects a hardware profile based on configurable temperature
     * thresholds defined in constants.vala.  Hysteresis prevents
     * rapid flapping at threshold boundaries.
     */
    public class AutoPolicyController : Object {
        private HardwareBackend backend;
        private uint source_id = 0;
        private string last_target = "";
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
                last_target = "";
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
            var target = choose_target(snapshot.max_temp_c);
            if (target == last_target) {
                return;
            }
            try {
                backend.set_hardware_profile(backend.choose_hardware_profile_for_policy(target));
                last_target = target;
            } catch (Error error) {
                warning("Auto policy failed: %s", error.message);
            }
        }

        /**
         * Select the target profile with hysteresis.
         *
         * Stepping UP uses the exact threshold; stepping DOWN
         * requires the temperature to drop below threshold minus
         * the hysteresis margin.
         */
        private string choose_target (int temp_c) {
            if (last_target == "performance") {
                if (temp_c >= AUTO_POLICY_TEMP_HIGH - AUTO_POLICY_HYSTERESIS) {
                    return "performance";
                }
            }
            if (last_target == "balanced") {
                if (temp_c >= AUTO_POLICY_TEMP_MID - AUTO_POLICY_HYSTERESIS
                    && temp_c < AUTO_POLICY_TEMP_HIGH) {
                    return "balanced";
                }
            }
            if (temp_c >= AUTO_POLICY_TEMP_HIGH) {
                return "performance";
            } else if (temp_c >= AUTO_POLICY_TEMP_MID) {
                return "balanced";
            }
            return "quiet";
        }
    }
}
