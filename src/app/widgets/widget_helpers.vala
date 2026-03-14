namespace VictusControl {
    /**
     * Reusable GTK4 widget factory methods.
     */
    public class WidgetHelpers : Object {

        public static Gtk.Widget wrap_section (string title, Gtk.Widget child) {
            var title_label = new Gtk.Label(title);
            title_label.halign = Gtk.Align.START;
            title_label.add_css_class("section-title");

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.add_css_class("section-card");
            box.append(title_label);
            box.append(child);
            return box;
        }

        public static Gtk.Widget create_info_card (string title, Gtk.Label value_label) {
            var title_label = new Gtk.Label(title);
            title_label.halign = Gtk.Align.START;
            title_label.add_css_class("card-title");

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            box.add_css_class("metric-card");
            box.hexpand = true;
            box.vexpand = true;
            box.append(title_label);
            box.append(value_label);
            return box;
        }

        public static Gtk.Label create_value_label (string text) {
            var label = new Gtk.Label(text);
            label.selectable = false;
            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            label.lines = 2;
            label.ellipsize = Pango.EllipsizeMode.END;
            label.halign = Gtk.Align.START;
            label.xalign = 0.0f;
            label.add_css_class("value-label");
            return label;
        }

        public static Gtk.Label create_metric_value_label () {
            var label = new Gtk.Label("");
            label.selectable = false;
            label.halign = Gtk.Align.START;
            label.xalign = 0.0f;
            label.add_css_class("metric-value");
            return label;
        }

        public static Gtk.Button create_action_button (string label) {
            var button = new Gtk.Button.with_label(label);
            button.add_css_class("pill-button");
            return button;
        }

        public static void update_active_button (Gtk.Button button, bool active) {
            if (active) {
                button.add_css_class("active-pill");
            } else {
                button.remove_css_class("active-pill");
            }
        }
    }
}
