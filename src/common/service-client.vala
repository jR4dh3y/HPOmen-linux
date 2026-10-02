namespace VictusControl {
    /**
     * Asynchronous proxy for the victusd D-Bus API.
     *
     * Every call yields to the caller's main loop, so UI processes never
     * block on hardware I/O in the helper.
     */
    public class ControlClient : Object {
        private DBusProxy proxy;

        private ControlClient (DBusProxy proxy) {
            this.proxy = proxy;
        }

        public static async ControlClient open () throws Error {
            var proxy = yield new DBusProxy.for_bus(
                BusType.SYSTEM,
                DBusProxyFlags.DO_NOT_LOAD_PROPERTIES | DBusProxyFlags.DO_NOT_CONNECT_SIGNALS,
                null,
                SERVICE_NAME,
                OBJECT_PATH,
                INTERFACE_NAME,
                null
            );
            return new ControlClient(proxy);
        }

        public async Snapshot get_snapshot () throws Error {
            var result = yield proxy.call("GetSnapshot", null, DBusCallFlags.NONE, HELPER_CALL_TIMEOUT_MS, null);
            return Snapshot.from_variant_dict(result.get_child_value(0));
        }

        public async void set_hardware_profile (string profile) throws Error {
            yield call_method("SetHardwareProfile", new Variant("(s)", profile));
        }

        public async void set_auto_policy (bool enabled) throws Error {
            yield call_method("SetAutoPolicy", new Variant("(b)", enabled));
        }

        public async void set_fan_mode (string mode) throws Error {
            yield call_method("SetFanMode", new Variant("(s)", mode));
        }

        public async void set_fan_levels (uint16 fan1, uint16 fan2) throws Error {
            yield call_method("SetFanLevels", new Variant("(qq)", fan1, fan2));
        }

        private async void call_method (string method, Variant parameters) throws Error {
            yield proxy.call(method, parameters, DBusCallFlags.NONE, HELPER_CALL_TIMEOUT_MS, null);
        }
    }
}
