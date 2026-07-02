namespace VictusControl {
    /**
     * Compact Fan-mode controls.
     */
    public class FanSection : Gtk.Box {
        public signal void fan_mode_requested (string mode);
        public signal void fan_target_requested (uint16 fan, uint16 rpm);

        private Gtk.Box fan_section_box;
        private Gtk.Button fan_auto_button;
        private Gtk.Button fan_manual_button;
        private Gtk.Button fan_max_button;
        private FanTargetRow fan1_row;
        private FanTargetRow fan2_row;
        private Gtk.Label reason_label;

        public FanSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            fan_section_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);

            fan_auto_button = WidgetHelpers.create_action_button("Auto");
            fan_manual_button = WidgetHelpers.create_action_button("Manual");
            fan_max_button = WidgetHelpers.create_action_button("Max");
            fan_auto_button.clicked.connect(() => fan_mode_requested("auto"));
            fan_manual_button.clicked.connect(() => fan_mode_requested("manual"));
            fan_max_button.clicked.connect(() => fan_mode_requested("max"));
            
            fan_auto_button.hexpand = true;
            fan_manual_button.hexpand = true;
            fan_max_button.hexpand = true;

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            button_row.append(fan_auto_button);
            button_row.append(fan_manual_button);
            button_row.append(fan_max_button);

            fan1_row = new FanTargetRow(1, "Fan 1 / CPU", MANUAL_FAN_MAX_RPM_FALLBACK);
            fan2_row = new FanTargetRow(2, "Fan 2 / GPU", MANUAL_FAN_MAX_RPM_FALLBACK);
            fan1_row.fan_target_requested.connect((f, r) => fan_target_requested(f, r));
            fan2_row.fan_target_requested.connect((f, r) => fan_target_requested(f, r));

            reason_label = new Gtk.Label("");
            reason_label.halign = Gtk.Align.START;
            reason_label.xalign = 0.0f;
            reason_label.wrap = true;
            reason_label.add_css_class("section-subtitle");

            fan_section_box.append(button_row);
            fan_section_box.append(fan1_row);
            fan_section_box.append(fan2_row);
            fan_section_box.append(reason_label);

            append(WidgetHelpers.wrap_titleless_section(fan_section_box));
        }

        public void update (Snapshot snapshot, bool hide_unsupported) {
            fan_auto_button.sensitive = snapshot.can_set_fan_mode;
            fan_manual_button.sensitive = snapshot.can_direct_fan_control;
            fan_max_button.sensitive = snapshot.can_set_fan_mode;
            WidgetHelpers.update_active_button(fan_auto_button, snapshot.active_fan_mode == "auto");
            WidgetHelpers.update_active_button(fan_manual_button, snapshot.active_fan_mode == "manual");
            WidgetHelpers.update_active_button(fan_max_button, snapshot.active_fan_mode == "max");
            fan1_row.update_max_rpm(snapshot.fan1_max_rpm);
            fan2_row.update_max_rpm(snapshot.fan2_max_rpm);
            fan1_row.set_controls_sensitive(snapshot.can_direct_fan_control);
            fan2_row.set_controls_sensitive(snapshot.can_direct_fan_control);
            reason_label.label = snapshot.can_direct_fan_control ? "" : snapshot.fan_control_reason;
            reason_label.visible = !snapshot.can_direct_fan_control && snapshot.fan_control_reason != "";
            fan_section_box.visible = !hide_unsupported || snapshot.can_set_fan_mode || snapshot.can_direct_fan_control;
        }

        public void show_offline (string error_message, bool hide_unsupported) {
            fan_auto_button.sensitive = false;
            fan_manual_button.sensitive = false;
            fan_max_button.sensitive = false;
            WidgetHelpers.update_active_button(fan_auto_button, false);
            WidgetHelpers.update_active_button(fan_manual_button, false);
            WidgetHelpers.update_active_button(fan_max_button, false);
            fan1_row.set_controls_sensitive(false);
            fan2_row.set_controls_sensitive(false);
            reason_label.label = error_message;
            reason_label.visible = true;
            fan_section_box.visible = !hide_unsupported;
        }
    }
}
