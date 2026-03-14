namespace VictusControl {
    /**
     * Reusable GTK4 widget factory methods shared across all
     * dashboard section widgets.
     */
    public class WidgetHelpers : Object {

        /** Wrap a child widget inside a titled section card. */
        public static Gtk.Widget wrap_section (string title, string subtitle, Gtk.Widget child) {
            var title_label = new Gtk.Label(title);
            title_label.halign = Gtk.Align.START;
            title_label.add_css_class("section-title");

            var subtitle_label = new Gtk.Label(subtitle);
            subtitle_label.halign = Gtk.Align.START;
            subtitle_label.wrap = true;
            subtitle_label.add_css_class("section-subtitle");

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.add_css_class("section-card");
            box.append(title_label);
            box.append(subtitle_label);
            box.append(child);
            return box;
        }

        /** Generic card with optional subtitle and optional progress bar. */
        public static Gtk.Widget create_card (string title, string? subtitle, Gtk.Label value_label, Gtk.ProgressBar? bar) {
            var title_label = new Gtk.Label(title);
            title_label.halign = Gtk.Align.START;
            title_label.add_css_class("card-title");

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            box.add_css_class("metric-card");
            box.hexpand = true;
            box.vexpand = true;
            box.append(title_label);

            if (subtitle != null) {
                var subtitle_label = new Gtk.Label(subtitle);
                subtitle_label.halign = Gtk.Align.START;
                subtitle_label.wrap = true;
                subtitle_label.add_css_class("card-subtitle");
                box.append(subtitle_label);
            }

            box.append(value_label);

            if (bar != null) {
                box.append(bar);
            }

            return box;
        }

        /** Card with title only (no subtitle, no bar). */
        public static Gtk.Widget create_info_card (string title, Gtk.Label value_label) {
            return create_card(title, null, value_label, null);
        }

        /** Card with title + subtitle (no bar). */
        public static Gtk.Widget create_simple_card (string title, string subtitle, Gtk.Label value_label) {
            return create_card(title, subtitle, value_label, null);
        }

        /** Card with title, subtitle, and progress bar. */
        public static Gtk.Widget create_metric_card (string title, string subtitle, Gtk.Label value_label, Gtk.ProgressBar bar) {
            return create_card(title, subtitle, value_label, bar);
        }

        /** Key-value pair used inside the hero accent panel. */
        public static Gtk.Widget create_panel_value (string title, string value) {
            var title_label = new Gtk.Label(title);
            title_label.halign = Gtk.Align.START;
            title_label.add_css_class("panel-title");

            var value_label = new Gtk.Label(value);
            value_label.halign = Gtk.Align.START;
            value_label.wrap = true;
            value_label.add_css_class("panel-value");

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            box.append(title_label);
            box.append(value_label);
            return box;
        }

        /** Selectable, wrapping label for data values. */
        public static Gtk.Label create_value_label (string text) {
            var label = new Gtk.Label(text);
            label.selectable = true;
            label.wrap = true;
            label.halign = Gtk.Align.START;
            label.xalign = 0.0f;
            return label;
        }

        /** Monospace metric value label. */
        public static Gtk.Label create_metric_value_label () {
            var label = create_value_label("");
            label.add_css_class("metric-value");
            return label;
        }

        /** Thermal progress bar. */
        public static Gtk.ProgressBar create_metric_bar () {
            var bar = new Gtk.ProgressBar();
            bar.hexpand = true;
            bar.show_text = false;
            bar.add_css_class("thermal-bar");
            return bar;
        }

        /** Rounded pill-style action button. */
        public static Gtk.Button create_action_button (string label) {
            var button = new Gtk.Button.with_label(label);
            button.add_css_class("pill-button");
            return button;
        }

        /** Toggle the active-pill CSS class on a button. */
        public static void update_active_button (Gtk.Button button, bool active) {
            if (active) {
                button.add_css_class("active-pill");
            } else {
                button.remove_css_class("active-pill");
            }
        }
    }
}
