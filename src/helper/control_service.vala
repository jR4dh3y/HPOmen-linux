namespace VictusControl {
    /**
     * D-Bus interface contract exposed by the victusd helper.
     *
     * SetFanLevels takes levels in the snapshot's fan_level_unit.
     */
    [DBus (name = "dev.radhey.VictusControl1")]
    public interface ControlApi : Object {
        public abstract async HashTable<string, Variant> get_snapshot () throws Error;
        public abstract async bool set_hardware_profile (string profile) throws Error;
        public abstract async bool set_platform_profile (string profile) throws Error;
        public abstract async bool set_auto_policy (bool enabled) throws Error;
        public abstract async bool set_fan_mode (string mode) throws Error;
        public abstract async bool set_fan_levels (uint16 fan1, uint16 fan2) throws Error;
        public abstract async HashTable<string, Variant> run_probe (string probe_name, HashTable<string, Variant> args) throws Error;
    }

    /**
     * D-Bus service that queues hardware work on HardwareWorker and keeps
     * policy state (auto policy, manual reapply) on the main loop.
     */
    public class ControlService : Object, ControlApi {
        private HardwareBackend backend = new HardwareBackend();
        private HardwareWorker worker = new HardwareWorker();
        private AutoPolicyController auto_policy;
        private ManualFanController manual_fans;

        public ControlService () {
            auto_policy = new AutoPolicyController(backend, worker);
            manual_fans = new ManualFanController(backend, worker);
        }

        public void export (DBusConnection connection) throws IOError {
            connection.register_object<ControlApi>(OBJECT_PATH, this);
        }

        /** Reapply the user's last profile, which hp-wmi may have reset at probe time. */
        public async void restore_profile () {
            var saved = HelperState.load_profile();
            if (saved == null) {
                return;
            }
            try {
                yield worker.run(() => {
                    if (backend.get_active_hardware_profile() != saved) {
                        backend.set_hardware_profile(saved);
                    }
                });
            } catch (Error error) {
                stderr.printf("victusd: cannot restore profile %s: %s\n", saved, error.message);
            }
        }

        public async HashTable<string, Variant> get_snapshot () throws Error {
            Snapshot? snapshot = null;
            yield worker.run(() => {
                snapshot = backend.read_snapshot();
            });
            snapshot.auto_policy_enabled = auto_policy.enabled;
            return snapshot.to_variant_dict();
        }

        public async bool set_hardware_profile (string profile) throws Error {
            auto_policy.set_active(false);
            yield worker.run(() => {
                var applied = backend.choose_hardware_profile_for_policy(profile);
                backend.set_hardware_profile(applied);
                try {
                    HelperState.save_profile(applied);
                } catch (Error error) {
                    stderr.printf("victusd: cannot save profile: %s\n", error.message);
                }
            });
            return true;
        }

        public async bool set_platform_profile (string profile) throws Error {
            return yield set_hardware_profile(profile);
        }

        public async bool set_auto_policy (bool enabled) throws Error {
            auto_policy.set_active(enabled);
            return true;
        }

        public async bool set_fan_mode (string mode) throws Error {
            if (mode != FanBackend.MODE_MANUAL) {
                manual_fans.release();
            }
            yield worker.run(() => {
                backend.set_fan_mode(mode);
            });
            return true;
        }

        public async bool set_fan_levels (uint16 fan1, uint16 fan2) throws Error {
            yield manual_fans.set_fan_levels(fan1, fan2);
            return true;
        }

        public async HashTable<string, Variant> run_probe (string probe_name, HashTable<string, Variant> args) throws Error {
            yield worker.run(() => {
                ProbeEngine.save_probe_state(ProbeEngine.run_named(probe_name));
            });
            return yield get_snapshot();
        }
    }
}
