namespace VictusControl {
    public enum ActionKind {
        HARDWARE_PROFILE,
        AUTO_POLICY,
        FAN_MODE,
        FAN_LEVELS
    }

    /**
     * One user request for victusd. A newer request of the same kind
     * supersedes a queued one, so only the latest intent reaches hardware.
     */
    public class ControlAction : Object {
        public ActionKind kind { get; construct; }
        /* Requested profile or fan mode; "" for other kinds. */
        public string target { get; construct; default = ""; }
        public bool enabled { get; construct; default = false; }
        public uint fan1_level { get; construct; default = 0; }
        public uint fan2_level { get; construct; default = 0; }

        public ControlAction.hardware_profile (string profile) {
            Object(kind: ActionKind.HARDWARE_PROFILE, target: profile);
        }

        public ControlAction.auto_policy (bool enabled) {
            Object(kind: ActionKind.AUTO_POLICY, enabled: enabled);
        }

        public ControlAction.fan_mode (string mode) {
            Object(kind: ActionKind.FAN_MODE, target: mode);
        }

        public ControlAction.fan_levels (uint16 fan1, uint16 fan2) {
            Object(kind: ActionKind.FAN_LEVELS, fan1_level: fan1, fan2_level: fan2);
        }

        public async void send (ControlClient client) throws Error {
            switch (kind) {
            case ActionKind.HARDWARE_PROFILE:
                yield client.set_hardware_profile(target);
                break;
            case ActionKind.AUTO_POLICY:
                yield client.set_auto_policy(enabled);
                break;
            case ActionKind.FAN_MODE:
                yield client.set_fan_mode(target);
                break;
            case ActionKind.FAN_LEVELS:
                yield client.set_fan_levels((uint16) fan1_level, (uint16) fan2_level);
                break;
            }
        }
    }
}
