namespace VictusControl {
    /**
     * Ultra compact hardware-profile selection buttons.
     */
    public class ProfileSection : Gtk.Box {
        public signal void action_requested (ControlAction action);

        private Gtk.Button low_power_button;
        private Gtk.Button balanced_button;
        private Gtk.Button performance_button;

        public ProfileSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            low_power_button = profile_button("Low Power", "low-power");
            balanced_button = profile_button("Balanced", "balanced");
            performance_button = profile_button("Performance", "performance");

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            button_row.append(low_power_button);
            button_row.append(balanced_button);
            button_row.append(performance_button);

            append(WidgetHelpers.wrap_titleless_section(button_row));
        }

        public void update (Snapshot snapshot) {
            var profiles = snapshot.available_hardware_profiles;
            var can_set = snapshot.can_set_hardware_profile;
            var active = snapshot.active_hardware_profile.down();
            update_button(low_power_button, can_set && Formatting.has_low_power_profile(profiles), Formatting.is_low_power_profile(active));
            update_button(balanced_button, can_set && Formatting.has_profile(profiles, "balanced"), active == "balanced");
            update_button(performance_button, can_set && Formatting.has_profile(profiles, "performance"), active == "performance");
        }

        public void show_offline () {
            low_power_button.sensitive = false;
            balanced_button.sensitive = false;
            performance_button.sensitive = false;
        }

        private Gtk.Button profile_button (string label, string profile) {
            var button = WidgetHelpers.create_action_button(label);
            button.hexpand = true;
            button.clicked.connect(() => action_requested(new ControlAction.hardware_profile(profile)));
            return button;
        }

        private void update_button (Gtk.Button button, bool supported, bool active) {
            button.sensitive = supported;
            WidgetHelpers.update_active_button(button, active);
        }
    }
}
