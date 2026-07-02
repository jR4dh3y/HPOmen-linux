namespace VictusControl {
    /**
     * Ultra compact hardware-profile selection buttons.
     */
    public class ProfileSection : Gtk.Box {
        public signal void profile_requested (string profile);

        private Gtk.Button low_power_button;
        private Gtk.Button balanced_button;
        private Gtk.Button performance_button;

        public ProfileSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            low_power_button = WidgetHelpers.create_action_button("Low Power");
            balanced_button = WidgetHelpers.create_action_button("Balanced");
            performance_button = WidgetHelpers.create_action_button("Performance");

            low_power_button.clicked.connect(() => profile_requested("low-power"));
            balanced_button.clicked.connect(() => profile_requested("balanced"));
            performance_button.clicked.connect(() => profile_requested("performance"));

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            low_power_button.hexpand = true;
            balanced_button.hexpand = true;
            performance_button.hexpand = true;
            button_row.append(low_power_button);
            button_row.append(balanced_button);
            button_row.append(performance_button);

            append(WidgetHelpers.wrap_titleless_section(button_row));
        }

        public void update (Snapshot snapshot) {
            var has_profiles = snapshot.can_set_hardware_profile && snapshot.available_hardware_profiles.length > 0;
            set_controls_available(has_profiles);

            var active = snapshot.active_hardware_profile.down();
            update_button(low_power_button, has_low_power_profile(snapshot), is_low_power_profile(active));
            update_button(balanced_button, has_hw_profile(snapshot, "balanced"), active == "balanced");
            update_button(performance_button, has_hw_profile(snapshot, "performance"), active == "performance");
        }

        public void show_offline () {
            set_controls_available(false);
        }

        private void set_controls_available (bool available) {
            low_power_button.sensitive = available;
            balanced_button.sensitive = available;
            performance_button.sensitive = available;
        }

        private void update_button (Gtk.Button button, bool supported, bool active) {
            button.sensitive = supported;
            WidgetHelpers.update_active_button(button, active);
        }

        private static bool has_hw_profile (Snapshot snapshot, string name) {
            foreach (var profile in snapshot.available_hardware_profiles) {
                if (profile.down() == name) {
                    return true;
                }
            }
            return false;
        }

        private static bool has_low_power_profile (Snapshot snapshot) {
            foreach (var profile in snapshot.available_hardware_profiles) {
                if (is_low_power_profile(profile.down())) {
                    return true;
                }
            }
            return false;
        }

        private static bool is_low_power_profile (string profile) {
            return profile == "low-power" || profile == "quiet" || profile == "cool";
        }
    }
}
