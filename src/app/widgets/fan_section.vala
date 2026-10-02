namespace VictusControl {
    /**
     * Compact Fan-mode controls.
     */
    public class FanSection : Gtk.Box {
        public signal void action_requested (ControlAction action);

        private Gtk.Box fan_section_box;
        private Gtk.Button fan_auto_button;
        private Gtk.Button fan_manual_button;
        private Gtk.Button fan_max_button;
        private FanTargetRow fan1_row;
        private FanTargetRow fan2_row;
        private Gtk.Label reason_label;
        /* In-flight plus queued level requests; rows hold their edits until all settle. */
        private int levels_pending = 0;
        /*
         * Latest level wanted per fan. Each per-fan Apply sends both, so a
         * queued request for one fan never drops a pending one for the other.
         */
        private int fan1_requested = -1;
        private int fan2_requested = -1;

        public FanSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            fan_section_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);

            fan_auto_button = mode_button("Auto", FanBackend.MODE_AUTO);
            fan_manual_button = mode_button("Manual", FanBackend.MODE_MANUAL);
            fan_max_button = mode_button("Max", FanBackend.MODE_MAX);

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            button_row.append(fan_auto_button);
            button_row.append(fan_manual_button);
            button_row.append(fan_max_button);

            fan1_row = new FanTargetRow(1, "Fan 1 / CPU", MANUAL_FAN_MAX_RPM_FALLBACK);
            fan2_row = new FanTargetRow(2, "Fan 2 / GPU", MANUAL_FAN_MAX_RPM_FALLBACK);
            fan1_row.fan_target_requested.connect(request_fan_level);
            fan2_row.fan_target_requested.connect(request_fan_level);

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
            WidgetHelpers.update_active_button(fan_auto_button, snapshot.active_fan_mode == FanBackend.MODE_AUTO);
            WidgetHelpers.update_active_button(fan_manual_button, snapshot.active_fan_mode == FanBackend.MODE_MANUAL);
            WidgetHelpers.update_active_button(fan_max_button, snapshot.active_fan_mode == FanBackend.MODE_MAX);
            fan1_row.configure(snapshot.fan_level_unit, snapshot.fan1_level_max);
            fan2_row.configure(snapshot.fan_level_unit, snapshot.fan2_level_max);
            if (levels_pending == 0) {
                fan1_requested = snapshot.fan1_level;
                fan2_requested = snapshot.fan2_level;
                fan1_row.sync(snapshot.fan1_level);
                fan2_row.sync(snapshot.fan2_level);
            }
            fan1_row.set_controls_sensitive(snapshot.can_direct_fan_control);
            fan2_row.set_controls_sensitive(snapshot.can_direct_fan_control);
            reason_label.label = snapshot.can_direct_fan_control ? "" : snapshot.fan_control_reason;
            reason_label.visible = !snapshot.can_direct_fan_control && snapshot.fan_control_reason != "";
            fan_section_box.visible = !hide_unsupported || snapshot.can_set_fan_mode || snapshot.can_direct_fan_control;
        }

        public void set_pending (ControlAction action, bool pending) {
            if (action.kind != ActionKind.FAN_LEVELS) {
                return;
            }
            levels_pending += pending ? 1 : -1;
            if (levels_pending == 0) {
                fan1_row.mark_applied();
                fan2_row.mark_applied();
            }
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

        private void request_fan_level (uint16 fan, uint16 level) {
            if (fan == 1) {
                fan1_requested = level;
            } else {
                fan2_requested = level;
            }
            var fan1 = fan1_requested >= 0 ? (uint16) fan1_requested : fan1_row.level;
            var fan2 = fan2_requested >= 0 ? (uint16) fan2_requested : fan2_row.level;
            action_requested(new ControlAction.fan_levels(fan1, fan2));
        }

        private Gtk.Button mode_button (string label, string mode) {
            var button = WidgetHelpers.create_action_button(label);
            button.hexpand = true;
            button.clicked.connect(() => action_requested(new ControlAction.fan_mode(mode)));
            return button;
        }
    }
}
