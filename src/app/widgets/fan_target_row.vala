namespace VictusControl {
    /**
     * Compact manual RPM target row for one fan.
     */
    public class FanTargetRow : Gtk.Box {
        public signal void fan_target_requested (uint16 fan, uint16 rpm);

        private uint16 fan;
        private Gtk.Label title_label;
        private Gtk.Adjustment adjustment;
        private Gtk.Scale scale;
        private Gtk.SpinButton spin;
        private Gtk.Button apply_button;

        public FanTargetRow (uint16 fan, string label, uint16 max_rpm) {
            Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 8);
            this.fan = fan;

            add_css_class("fan-target-row");

            title_label = new Gtk.Label(label);
            title_label.halign = Gtk.Align.START;
            title_label.width_chars = 4;
            title_label.add_css_class("card-title");

            adjustment = new Gtk.Adjustment(
                MANUAL_FAN_MIN_RPM,
                MANUAL_FAN_MIN_RPM,
                max_rpm,
                100,
                500,
                0
            );
            scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, adjustment);
            scale.draw_value = false;
            scale.hexpand = true;
            spin = new Gtk.SpinButton(adjustment, 100, 0);
            spin.width_chars = 5;

            apply_button = WidgetHelpers.create_action_button("Apply");
            apply_button.clicked.connect(() => {
                fan_target_requested(this.fan, (uint16) spin.get_value_as_int());
            });

            append(title_label);
            append(scale);
            append(spin);
            append(apply_button);
        }

        public uint16 get_target_rpm () {
            return (uint16) spin.get_value_as_int();
        }

        public void update_max_rpm (int max_rpm) {
            if (max_rpm < MANUAL_FAN_MIN_RPM) {
                return;
            }
            adjustment.upper = max_rpm;
            if (adjustment.value > max_rpm) {
                adjustment.value = max_rpm;
            }
        }

        public void set_controls_sensitive (bool enabled) {
            scale.sensitive = enabled;
            spin.sensitive = enabled;
            apply_button.sensitive = enabled;
        }
    }
}
