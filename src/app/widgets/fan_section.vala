namespace VictusControl {
    /**
     * Compact fan-mode buttons and manual levels for both fans.
     */
    public class FanSection : Gtk.Box {
        public signal void action_requested (ControlAction action);

        private Gtk.Box fan_section_box;
        private Gtk.Button fan_auto_button;
        private Gtk.Button fan_manual_button;
        private Gtk.Button fan_max_button;
        private FanLevelRow fan1_row;
        private FanLevelRow fan2_row;
        private Gtk.Button apply_button;
        private Gtk.Label reason_label;
        /* In-flight plus queued level requests; edits stay put until all settle. */
        private int levels_pending = 0;

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

            fan1_row = new FanLevelRow("Fan 1 / CPU");
            fan2_row = new FanLevelRow("Fan 2 / GPU");
            apply_button = WidgetHelpers.create_action_button("Apply");
            apply_button.halign = Gtk.Align.END;
            apply_button.clicked.connect(() => {
                fan1_row.mark_submitted();
                fan2_row.mark_submitted();
                action_requested(new ControlAction.fan_levels(fan1_row.level, fan2_row.level));
            });

            reason_label = new Gtk.Label("");
            reason_label.halign = Gtk.Align.START;
            reason_label.xalign = 0.0f;
            reason_label.wrap = true;
            reason_label.add_css_class("section-subtitle");

            fan_section_box.append(button_row);
            fan_section_box.append(fan1_row);
            fan_section_box.append(fan2_row);
            fan_section_box.append(apply_button);
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
                fan1_row.sync(snapshot.fan1_level);
                fan2_row.sync(snapshot.fan2_level);
            }
            set_levels_available(snapshot.can_direct_fan_control);
            reason_label.label = snapshot.can_direct_fan_control ? "" : snapshot.fan_control_reason;
            reason_label.visible = !snapshot.can_direct_fan_control && snapshot.fan_control_reason != "";
            fan_section_box.visible = !hide_unsupported || snapshot.can_set_fan_mode || snapshot.can_direct_fan_control;
        }

        public void set_pending (ControlAction action, bool pending) {
            switch (action.kind) {
            case ActionKind.FAN_MODE:
                WidgetHelpers.update_pending_button(button_for_mode(action.target), pending);
                break;
            case ActionKind.FAN_LEVELS:
                levels_pending += pending ? 1 : -1;
                if (levels_pending == 0) {
                    fan1_row.mark_applied();
                    fan2_row.mark_applied();
                }
                apply_button.label = levels_pending > 0 ? "Applying…" : "Apply";
                break;
            default:
                break;
            }
        }

        public void show_offline (string error_message, bool hide_unsupported) {
            fan_auto_button.sensitive = false;
            fan_manual_button.sensitive = false;
            fan_max_button.sensitive = false;
            WidgetHelpers.update_active_button(fan_auto_button, false);
            WidgetHelpers.update_active_button(fan_manual_button, false);
            WidgetHelpers.update_active_button(fan_max_button, false);
            set_levels_available(false);
            reason_label.label = error_message;
            reason_label.visible = true;
            fan_section_box.visible = !hide_unsupported;
        }

        private void set_levels_available (bool available) {
            fan1_row.set_controls_sensitive(available);
            fan2_row.set_controls_sensitive(available);
            apply_button.sensitive = available;
        }

        private Gtk.Button mode_button (string label, string mode) {
            var button = WidgetHelpers.create_action_button(label);
            button.hexpand = true;
            button.clicked.connect(() => action_requested(new ControlAction.fan_mode(mode)));
            return button;
        }

        private Gtk.Button button_for_mode (string mode) {
            if (mode == FanBackend.MODE_AUTO) {
                return fan_auto_button;
            }
            return mode == FanBackend.MODE_MANUAL ? fan_manual_button : fan_max_button;
        }
    }
}
