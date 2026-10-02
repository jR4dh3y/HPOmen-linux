namespace VictusControl {
    /**
     * AppIndicator menu. Current state lives in item labels, because
     * AppIndicator hosts do not render GTK check state reliably.
     */
    public class TrayMenu : Object {
        private const string ACTIVE_SUFFIX = " •";

        public signal void action_requested (ControlAction action);
        public signal void quit_requested ();

        public Gtk.Menu menu { get; private set; }

        private Gtk.MenuItem temp_item;
        private Gtk.MenuItem rpm_item;
        private Gtk.MenuItem low_power_item;
        private Gtk.MenuItem balanced_item;
        private Gtk.MenuItem performance_item;
        private Gtk.MenuItem fan_auto_item;
        private Gtk.MenuItem fan_max_item;
        private HashTable<Gtk.MenuItem, string> base_labels = new HashTable<Gtk.MenuItem, string>(direct_hash, direct_equal);

        public TrayMenu () {
            menu = new Gtk.Menu();
            temp_item = info_item("Temp unavailable");
            rpm_item = info_item("Fans unavailable");
            menu.append(new Gtk.SeparatorMenuItem());
            low_power_item = action_item("Low Power", new ControlAction.hardware_profile("low-power"));
            balanced_item = action_item("Balanced", new ControlAction.hardware_profile("balanced"));
            performance_item = action_item("Performance", new ControlAction.hardware_profile("performance"));
            menu.append(new Gtk.SeparatorMenuItem());
            fan_auto_item = action_item("Fan Auto", new ControlAction.fan_mode(FanBackend.MODE_AUTO));
            fan_max_item = action_item("Fan Max", new ControlAction.fan_mode(FanBackend.MODE_MAX));
            menu.append(new Gtk.SeparatorMenuItem());

            var open_item = new Gtk.MenuItem.with_label("Open Monitor");
            open_item.activate.connect(() => {
                try {
                    Process.spawn_command_line_async("victus-control");
                } catch (Error error) {
                    temp_item.set_label(error.message);
                }
            });
            menu.append(open_item);
            var quit_item = new Gtk.MenuItem.with_label("Quit");
            quit_item.activate.connect(() => quit_requested());
            menu.append(quit_item);
            menu.show_all();
        }

        public void update (Snapshot snapshot) {
            temp_item.set_label(snapshot.max_temp_c >= 0 ? "Temp %dC".printf(snapshot.max_temp_c) : "Temp unavailable");
            rpm_item.set_label("Fans %s / %s RPM".printf(rpm_text(snapshot.fan1_rpm), rpm_text(snapshot.fan2_rpm)));

            var profiles = snapshot.available_hardware_profiles;
            var can_set = snapshot.can_set_hardware_profile;
            var active = snapshot.active_hardware_profile.down();
            set_state(low_power_item, can_set && Formatting.has_low_power_profile(profiles), Formatting.is_low_power_profile(active));
            set_state(balanced_item, can_set && Formatting.has_profile(profiles, "balanced"), active == "balanced");
            set_state(performance_item, can_set && Formatting.has_profile(profiles, "performance"), active == "performance");
            set_state(fan_auto_item, snapshot.can_set_fan_mode, snapshot.active_fan_mode == FanBackend.MODE_AUTO);
            set_state(fan_max_item, snapshot.can_set_fan_mode, snapshot.active_fan_mode == FanBackend.MODE_MAX);
        }

        public void show_message (string message) {
            temp_item.set_label(message);
            rpm_item.set_label("Fans unavailable");
        }

        public static string summary (Snapshot snapshot) {
            return "%s | %s/%s RPM".printf(
                snapshot.max_temp_c >= 0 ? "%dC".printf(snapshot.max_temp_c) : "Temp n/a",
                rpm_text(snapshot.fan1_rpm),
                rpm_text(snapshot.fan2_rpm)
            );
        }

        private void set_state (Gtk.MenuItem item, bool sensitive, bool active) {
            item.sensitive = sensitive;
            item.set_label(base_labels[item] + (active ? ACTIVE_SUFFIX : ""));
        }

        private Gtk.MenuItem info_item (string label) {
            var item = new Gtk.MenuItem.with_label(label);
            item.set_sensitive(false);
            menu.append(item);
            return item;
        }

        private Gtk.MenuItem action_item (string label, ControlAction action) {
            var item = new Gtk.MenuItem.with_label(label);
            base_labels[item] = label;
            item.activate.connect(() => action_requested(action));
            menu.append(item);
            return item;
        }

        private static string rpm_text (int rpm) {
            return rpm >= 0 ? "%d".printf(rpm) : "n/a";
        }
    }
}
