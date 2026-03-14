namespace VictusControl {
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
            if (snapshot.max_temp_c >= 78) {
                target = "performance";
            } else if (snapshot.max_temp_c >= 64) {
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

    [DBus (name = "io.github.radhey.VictusControl1")]
    public interface ControlApi : Object {
        public abstract HashTable<string, Variant> get_snapshot () throws Error;
        public abstract bool set_hardware_profile (string profile) throws Error;
        public abstract bool set_platform_profile (string profile) throws Error;
        public abstract bool set_auto_policy (bool enabled) throws Error;
        public abstract bool set_fan_mode (string mode) throws Error;
        public abstract bool set_fan_levels (uint16 cpu, uint16 gpu) throws Error;
        public abstract HashTable<string, Variant> run_probe (string probe_name, HashTable<string, Variant> args) throws Error;
    }

    public class ControlService : Object, ControlApi {
        private HardwareBackend backend;
        private AutoPolicyController auto_policy;

        public ControlService () {
            backend = new HardwareBackend();
            auto_policy = new AutoPolicyController(backend);
        }

        public void export (DBusConnection connection) throws IOError {
            connection.register_object<ControlApi>(OBJECT_PATH, this);
        }

        public HashTable<string, Variant> get_snapshot () throws Error {
            return backend.read_snapshot(auto_policy.enabled).to_variant_dict();
        }

        public bool set_hardware_profile (string profile) throws Error {
            auto_policy.set_active(false);
            backend.set_hardware_profile(backend.choose_hardware_profile_for_policy(profile));
            return true;
        }

        public bool set_platform_profile (string profile) throws Error {
            return set_hardware_profile(profile);
        }

        public bool set_auto_policy (bool enabled) throws Error {
            auto_policy.set_active(enabled);
            return true;
        }

        public bool set_fan_mode (string mode) throws Error {
            backend.set_fan_mode(mode);
            return true;
        }

        public bool set_fan_levels (uint16 cpu, uint16 gpu) throws Error {
            throw new ControlError.UNSUPPORTED("Granular fan level control is not available. Use fan mode auto or max.");
        }

        public HashTable<string, Variant> run_probe (string probe_name, HashTable<string, Variant> args) throws Error {
            var result = ProbeEngine.run_named(probe_name);
            ProbeEngine.save_probe_state(result);
            return backend.read_snapshot(auto_policy.enabled).to_variant_dict();
        }
    }
}
