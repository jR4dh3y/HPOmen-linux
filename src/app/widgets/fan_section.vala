namespace VictusControl {
    /**
     * Compact Fan-mode controls.
     */
    public class FanSection : Gtk.Box {
        public signal void fan_mode_requested (string mode);

        private Gtk.Box fan_section_box;
        private Gtk.Button fan_auto_button;
        private Gtk.Button fan_max_button;

        public FanSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            fan_section_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);

            fan_auto_button = WidgetHelpers.create_action_button("Auto");
            fan_max_button = WidgetHelpers.create_action_button("Max");
            fan_auto_button.clicked.connect(() => fan_mode_requested("auto"));
            fan_max_button.clicked.connect(() => fan_mode_requested("max"));
            
            fan_auto_button.hexpand = true;
            fan_max_button.hexpand = true;

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            button_row.append(fan_auto_button);
            button_row.append(fan_max_button);

            fan_section_box.append(button_row);

            append(WidgetHelpers.wrap_section("Fan Control", fan_section_box));
        }

        public void update (Snapshot snapshot, bool hide_unsupported) {
            fan_auto_button.sensitive = snapshot.can_set_fan_mode && snapshot.active_fan_mode != "auto";
            fan_max_button.sensitive = snapshot.can_set_fan_mode && snapshot.active_fan_mode != "max";
            WidgetHelpers.update_active_button(fan_auto_button, snapshot.active_fan_mode == "auto");
            WidgetHelpers.update_active_button(fan_max_button, snapshot.active_fan_mode == "max");
            fan_section_box.visible = !hide_unsupported || snapshot.can_set_fan_mode;
        }

        public void show_offline (string error_message, bool hide_unsupported) {
            fan_auto_button.sensitive = false;
            fan_max_button.sensitive = false;
            WidgetHelpers.update_active_button(fan_auto_button, false);
            WidgetHelpers.update_active_button(fan_max_button, false);
            fan_section_box.visible = !hide_unsupported;
        }
    }
}
