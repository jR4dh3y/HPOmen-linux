namespace VictusControl {
    /**
     * Compact manual level editor for one fan.
     *
     * The row follows the helper's held level until the user edits it,
     * and keeps the user's edit until it is applied.
     */
    public class FanLevelRow : Gtk.Box {
        private Gtk.Label title_label;
        private Gtk.Adjustment adjustment;
        private Gtk.Scale scale;
        private Gtk.SpinButton spin;
        private Gtk.Label unit_label;
        private string unit = "";
        private bool edited = false;
        private bool syncing = false;
        private int submitted = -1;

        public FanLevelRow (string label) {
            Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 8);
            add_css_class("fan-target-row");

            title_label = new Gtk.Label(label);
            title_label.halign = Gtk.Align.START;
            title_label.width_chars = 4;
            title_label.add_css_class("card-title");

            adjustment = new Gtk.Adjustment(0, 0, MANUAL_FAN_MAX_RPM_FALLBACK, FAN_LEVEL_STEP_RPM, FAN_LEVEL_STEP_RPM * 5, 0);
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
            unit_label = new Gtk.Label("");
            unit_label.width_chars = 3;
            unit_label.xalign = 0.0f;
            unit_label.add_css_class("card-title");

            append(title_label);
            append(scale);
            append(spin);
            append(unit_label);
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
                unit_label.label = unit == FAN_LEVEL_UNIT_PERCENT ? "%" : "RPM";
            }
            /* Shrinking the range clamps the value; that is not a user edit. */
            syncing = true;
            adjustment.upper = max_level;
            syncing = false;
        }

        /** Show the helper's held level unless the user has an unapplied edit. */
        public void sync (int held_level) {
            if (edited || held_level < 0) {
                return;
            }
            syncing = true;
            adjustment.value = held_level;
            syncing = false;
        }

        /** Remember the level sent to the helper. */
        public void mark_submitted () {
            submitted = level;
        }

        /** Resume following the helper unless the user edited again after submitting. */
        public void mark_applied () {
            if (level == submitted) {
                edited = false;
            }
        }

        public void set_controls_sensitive (bool enabled) {
            scale.sensitive = enabled;
            spin.sensitive = enabled;
        }
    }
}
