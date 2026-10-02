namespace VictusControl {
    /**
     * Compact manual level row for one fan.
     *
     * Values are in the snapshot's fan_level_unit (RPM or percent). The row
     * follows the driver's current level until the user edits it, and keeps
     * the edit until it is applied.
     */
    public class FanTargetRow : Gtk.Box {
        public signal void fan_target_requested (uint16 fan, uint16 level);

        private uint16 fan;
        private Gtk.Label title_label;
        private Gtk.Adjustment adjustment;
        private Gtk.Scale scale;
        private Gtk.SpinButton spin;
        private Gtk.Button apply_button;
        private string unit = "";
        private bool edited = false;
        private bool syncing = false;
        private int submitted = -1;

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
                FAN_LEVEL_STEP_RPM,
                FAN_LEVEL_STEP_RPM * 5,
                0
            );
            adjustment.value_changed.connect(() => {
                if (!syncing) {
                    edited = true;
                }
            });
            scale = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, adjustment);
            scale.draw_value = false;
            scale.hexpand = true;
            spin = new Gtk.SpinButton(adjustment, FAN_LEVEL_STEP_RPM, 0);
            spin.width_chars = 5;

            apply_button = WidgetHelpers.create_action_button("Apply");
            apply_button.clicked.connect(() => {
                submitted = level;
                fan_target_requested(this.fan, level);
            });

            append(title_label);
            append(scale);
            append(spin);
            append(apply_button);
        }

        public uint16 level {
            get { return (uint16) spin.get_value_as_int(); }
        }

        /** Adopt the active driver's unit and range; a unit change discards edits. */
        public void configure (string unit, int max_level) {
            if (unit == "" || max_level <= 0) {
                return;
            }
            if (unit != this.unit) {
                this.unit = unit;
                edited = false;
                var step = unit == FAN_LEVEL_UNIT_PERCENT ? FAN_LEVEL_STEP_PERCENT : FAN_LEVEL_STEP_RPM;
                adjustment.step_increment = step;
                adjustment.page_increment = step * 5;
            }
            /* Shrinking the range clamps the value; that is not a user edit. */
            syncing = true;
            adjustment.upper = max_level;
            syncing = false;
        }

        /** Show the driver's current level unless the user has an unapplied edit. */
        public void sync (int current_level) {
            if (edited || current_level < 0) {
                return;
            }
            syncing = true;
            adjustment.value = current_level;
            syncing = false;
        }

        /** Resume following the driver unless the user edited again after applying. */
        public void mark_applied () {
            if (level == submitted) {
                edited = false;
            }
        }

        public void set_controls_sensitive (bool enabled) {
            scale.sensitive = enabled;
            spin.sensitive = enabled;
            apply_button.sensitive = enabled;
        }
    }
}
