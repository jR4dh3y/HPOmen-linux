namespace VictusControl {
    /**
     * Reapplies manual fan targets because firmware may revert them.
     */
    public class ManualFanController : Object {
        private HardwareBackend backend;
        private uint source_id = 0;
        private uint16 fan1_rpm = 0;
        private uint16 fan2_rpm = 0;
        private bool fan1_target_set = false;
        private bool fan2_target_set = false;

        public ManualFanController (HardwareBackend backend) {
            this.backend = backend;
        }

        public void set_fan_target (uint16 fan, uint16 rpm) throws Error {
            if (fan == 1) {
                fan1_rpm = rpm;
                fan1_target_set = true;
                if (!fan2_target_set) {
                    fan2_rpm = read_safe_rpm(2);
                    fan2_target_set = true;
                }
            } else if (fan == 2) {
                fan2_rpm = rpm;
                fan2_target_set = true;
                if (!fan1_target_set) {
                    fan1_rpm = read_safe_rpm(1);
                    fan1_target_set = true;
                }
            }
            backend.set_fan_levels(fan1_rpm, fan2_rpm);
            start();
        }

        public void set_fan_levels (uint16 fan1_rpm, uint16 fan2_rpm) throws Error {
            backend.set_fan_levels(fan1_rpm, fan2_rpm);
            this.fan1_rpm = fan1_rpm;
            this.fan2_rpm = fan2_rpm;
            fan1_target_set = true;
            fan2_target_set = true;
            start();
        }

        public void stop () {
            if (source_id != 0) {
                Source.remove(source_id);
                source_id = 0;
            }
            fan1_rpm = 0;
            fan2_rpm = 0;
            fan1_target_set = false;
            fan2_target_set = false;
        }

        private void start () {
            if (source_id != 0) {
                return;
            }
            source_id = Timeout.add_seconds(MANUAL_FAN_REAPPLY_SECONDS, () => {
                reapply();
                return source_id != 0;
            });
        }

        private void reapply () {
            try {
                if (fan1_target_set && fan2_target_set) {
                    backend.set_fan_levels(fan1_rpm, fan2_rpm);
                } else {
                    if (fan1_target_set) {
                        backend.set_fan_target(1, fan1_rpm);
                    }
                    if (fan2_target_set) {
                        backend.set_fan_target(2, fan2_rpm);
                    }
                }
            } catch (Error error) {
                warning("Manual fan reapply failed: %s", error.message);
            }
        }

        private uint16 read_safe_rpm (uint16 fan) {
            var snapshot = backend.read_snapshot(false);
            int rpm = fan == 1 ? snapshot.fan1_rpm : snapshot.fan2_rpm;
            if (rpm > 0 && rpm <= uint16.MAX) {
                return (uint16) rpm;
            }

            int max_rpm = fan == 1 ? snapshot.fan1_max_rpm : snapshot.fan2_max_rpm;
            if (max_rpm > 0 && max_rpm < MANUAL_FAN_SAFE_RPM_FALLBACK) {
                return (uint16) max_rpm;
            }
            return MANUAL_FAN_SAFE_RPM_FALLBACK;
        }
    }
}
