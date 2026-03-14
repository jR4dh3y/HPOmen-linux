namespace VictusControl {
    public class ControlClient : Object {
        private DBusProxy proxy;

        public ControlClient () throws Error {
            proxy = new DBusProxy.for_bus_sync(
                BusType.SYSTEM,
                DBusProxyFlags.NONE,
                null,
                SERVICE_NAME,
                OBJECT_PATH,
                INTERFACE_NAME,
                null
            );
        }

        public Snapshot get_snapshot () throws Error {
            var result = proxy.call_sync("GetSnapshot", null, DBusCallFlags.NONE, -1, null);
            return Snapshot.from_variant_dict(result.get_child_value(0));
        }

        public bool set_platform_profile (string profile) throws Error {
            return call_bool("SetPlatformProfile", new Variant("(s)", profile));
        }

        public bool set_auto_policy (bool enabled) throws Error {
            return call_bool("SetAutoPolicy", new Variant("(b)", enabled));
        }

        public bool set_fan_mode (string mode) throws Error {
            return call_bool("SetFanMode", new Variant("(s)", mode));
        }

        public bool set_fan_levels (uint16 cpu, uint16 gpu) throws Error {
            return call_bool("SetFanLevels", new Variant("(qq)", cpu, gpu));
        }

        private bool call_bool (string method, Variant parameters) throws Error {
            var result = proxy.call_sync(method, parameters, DBusCallFlags.NONE, -1, null);
            return result.get_child_value(0).get_boolean();
        }
    }
}
