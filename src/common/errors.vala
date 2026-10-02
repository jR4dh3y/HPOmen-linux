namespace VictusControl {
    public const string CONTROL_ERROR_DBUS_NAME = "dev.radhey.VictusControl1.Error";

    [DBus (name = "dev.radhey.VictusControl1.Error")]
    public errordomain ControlError {
        FAILED,
        IO,
        INVALID_ARGUMENT,
        NOT_AUTHORIZED,
        UNSUPPORTED,
    }

    public class ControlErrors : Object {
        /** True when victusd itself rejected the call, so retrying cannot help. */
        public static bool is_helper_verdict (Error error) {
            var remote = DBusError.get_remote_error(error);
            return error is ControlError || (remote != null && remote.has_prefix(CONTROL_ERROR_DBUS_NAME));
        }

        /**
         * Drop the GDBus remote-error prefix so users see only the helper's
         * message. Helper rejections stay ControlError after stripping.
         */
        public static Error readable (Error error) {
            var copy = error.copy();
            var verdict = is_helper_verdict(copy);
            DBusError.strip_remote_error(copy);
            if (verdict && !(copy is ControlError)) {
                return new ControlError.FAILED(copy.message);
            }
            return copy;
        }

        /** Wrap foreign errors so every helper failure crosses D-Bus under one name. */
        public static Error to_control_error (Error error) {
            if (error is ControlError) {
                return error.copy();
            }
            return new ControlError.IO(error.message);
        }
    }
}
