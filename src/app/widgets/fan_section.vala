namespace VictusControl {
    /**
     * Fan-mode controls (Auto / Max) and current mode readout.
     *
     * Emits a signal when the user requests a fan-mode change —
     * the controller handles the D-Bus call.
     */
    public class FanSection : Gtk.Box {
        /** User clicked a fan-mode button. */
        public signal void fan_mode_requested (string mode);

        private Gtk.Box fan_section_box;
        private Gtk.Label fan_support_label;
        private Gtk.Label fan_mode_label;
        private Gtk.Button fan_auto_button;
        private Gtk.Button fan_max_button;

        public FanSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            fan_section_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 14);

            fan_support_label = WidgetHelpers.create_value_label("");
            fan_support_label.add_css_class("muted-text");

            fan_mode_label = WidgetHelpers.create_metric_value_label();

            fan_auto_button = WidgetHelpers.create_action_button("Auto");
            fan_max_button = WidgetHelpers.create_action_button("Max");
            fan_auto_button.clicked.connect(() => fan_mode_requested("auto"));
            fan_max_button.clicked.connect(() => fan_mode_requested("max"));

            var current_mode_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            current_mode_box.add_css_class("inline-card");
            var current_mode_title = new Gtk.Label("Current fan mode");
            current_mode_title.halign = Gtk.Align.START;
            current_mode_title.hexpand = true;
            current_mode_box.append(current_mode_title);
            current_mode_box.append(fan_mode_label);

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            button_row.append(fan_auto_button);
            button_row.append(fan_max_button);

            fan_section_box.append(fan_support_label);
            fan_section_box.append(current_mode_box);
            fan_section_box.append(button_row);

            append(WidgetHelpers.wrap_section(
                "Fan Control",
                "Validated HP WMI fan modes only. Granular fan levels remain blocked.",
                fan_section_box
            ));
        }

        public void update (Snapshot snapshot, bool hide_unsupported) {
            fan_mode_label.label = Formatting.fan_mode(snapshot.active_fan_mode);
            fan_support_label.label = snapshot.can_set_fan_mode
                ? "Mode-based control is available. Auto returns control to firmware; Max forces the fans to full speed."
                : Formatting.fallback(snapshot.fan_control_reason);
            fan_auto_button.sensitive = snapshot.can_set_fan_mode && snapshot.active_fan_mode != "auto";
            fan_max_button.sensitive = snapshot.can_set_fan_mode && snapshot.active_fan_mode != "max";
            WidgetHelpers.update_active_button(fan_auto_button, snapshot.active_fan_mode == "auto");
            WidgetHelpers.update_active_button(fan_max_button, snapshot.active_fan_mode == "max");
            fan_section_box.visible = !hide_unsupported || snapshot.can_set_fan_mode;
        }

        public void show_offline (string error_message, bool hide_unsupported) {
            fan_support_label.label = error_message;
            fan_mode_label.label = "Unavailable";
            fan_auto_button.sensitive = false;
            fan_max_button.sensitive = false;
            WidgetHelpers.update_active_button(fan_auto_button, false);
            WidgetHelpers.update_active_button(fan_max_button, false);
            fan_section_box.visible = !hide_unsupported;
        }
    }
}
