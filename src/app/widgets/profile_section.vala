namespace VictusControl {
    /**
     * Ultra compact hardware-profile selection buttons.
     */
    public class ProfileSection : Gtk.Box {
        public signal void profile_requested (string profile);
        public signal void auto_policy_toggled (bool enabled);

        private Gtk.Switch auto_policy_switch;
        private Gtk.Button cool_button;
        private Gtk.Button quiet_button;
        private Gtk.Button balanced_button;
        private Gtk.Button performance_button;

        private bool updating_auto_policy = false;

        public ProfileSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            cool_button = WidgetHelpers.create_action_button("Cool");
            quiet_button = WidgetHelpers.create_action_button("Quiet");
            balanced_button = WidgetHelpers.create_action_button("Balanced");
            performance_button = WidgetHelpers.create_action_button("Performance");

            cool_button.clicked.connect(() => profile_requested("cool"));
            quiet_button.clicked.connect(() => profile_requested("quiet"));
            balanced_button.clicked.connect(() => profile_requested("balanced"));
            performance_button.clicked.connect(() => profile_requested("performance"));

            auto_policy_switch = new Gtk.Switch();
            auto_policy_switch.valign = Gtk.Align.CENTER;
            auto_policy_switch.notify["active"].connect(() => {
                if (updating_auto_policy || !auto_policy_switch.is_sensitive()) {
                    return;
                }
                auto_policy_toggled(auto_policy_switch.active);
            });

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            cool_button.hexpand = true;
            quiet_button.hexpand = true;
            balanced_button.hexpand = true;
            performance_button.hexpand = true;
            button_row.append(cool_button);
            button_row.append(quiet_button);
            button_row.append(balanced_button);
            button_row.append(performance_button);

            var switch_label = new Gtk.Label("Auto Policy");
            switch_label.halign = Gtk.Align.START;
            switch_label.hexpand = true;
            switch_label.add_css_class("value-label");

            var switch_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            switch_row.add_css_class("inline-card");
            switch_row.append(switch_label);
            switch_row.append(auto_policy_switch);

            var action_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            action_box.append(button_row);
            action_box.append(switch_row);

            append(WidgetHelpers.wrap_section("Profiles", action_box));
        }

        public void update (Snapshot snapshot) {
            var has_profiles = snapshot.can_set_hardware_profile && snapshot.available_hardware_profiles.length > 0;
            set_controls_available(has_profiles);

            var active = snapshot.active_hardware_profile.down();
            update_button(cool_button, has_hw_profile(snapshot, "cool"), active == "cool");
            update_button(quiet_button, has_hw_profile(snapshot, "quiet"), active == "quiet");
            update_button(balanced_button, has_hw_profile(snapshot, "balanced"), active == "balanced");
            update_button(performance_button, has_hw_profile(snapshot, "performance"), active == "performance");

            updating_auto_policy = true;
            auto_policy_switch.sensitive = true;
            auto_policy_switch.active = snapshot.auto_policy_enabled;
            updating_auto_policy = false;
        }

        public void show_offline () {
            set_controls_available(false);
            updating_auto_policy = true;
            auto_policy_switch.sensitive = false;
            auto_policy_switch.active = false;
            updating_auto_policy = false;
        }

        private void set_controls_available (bool available) {
            cool_button.sensitive = available;
            quiet_button.sensitive = available;
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
    }
}
