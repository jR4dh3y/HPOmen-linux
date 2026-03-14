namespace VictusControl {
    /**
     * Hero banner at the top of the dashboard showing connection
     * status, product name, and a live one-line summary.
     */
    public class HeroSection : Gtk.Box {
        private Gtk.Label status_label;
        private Gtk.Label hero_title_label;
        private Gtk.Label hero_subtitle_label;
        private Gtk.Label helper_state_label;

        public HeroSection () {
            Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 24);
            add_css_class("hero-card");

            status_label = new Gtk.Label("Connecting");
            status_label.halign = Gtk.Align.START;
            status_label.add_css_class("status-pill");

            hero_title_label = new Gtk.Label("Victus hardware control");
            hero_title_label.halign = Gtk.Align.START;
            hero_title_label.wrap = true;
            hero_title_label.add_css_class("hero-title");

            hero_subtitle_label = new Gtk.Label("Waiting for the helper to expose live machine state.");
            hero_subtitle_label.halign = Gtk.Align.START;
            hero_subtitle_label.wrap = true;
            hero_subtitle_label.add_css_class("hero-subtitle");

            helper_state_label = new Gtk.Label("");
            helper_state_label.halign = Gtk.Align.START;
            helper_state_label.wrap = true;
            helper_state_label.add_css_class("eyebrow");

            var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
            text_box.hexpand = true;
            text_box.append(status_label);
            text_box.append(hero_title_label);
            text_box.append(hero_subtitle_label);
            text_box.append(helper_state_label);

            var accent_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
            accent_box.halign = Gtk.Align.END;
            accent_box.valign = Gtk.Align.START;
            accent_box.add_css_class("accent-panel");
            accent_box.append(WidgetHelpers.create_panel_value("HW Profiles", "Cool / Quiet / Balanced / Performance"));
            accent_box.append(WidgetHelpers.create_panel_value("Fan modes", "Auto / Max"));

            append(text_box);
            append(accent_box);
        }

        /** Refresh all labels from a live snapshot. */
        public void update (Snapshot snapshot) {
            status_label.label = "Online";
            hero_title_label.label = snapshot.product_name != ""
                ? "%s control surface".printf(snapshot.product_name)
                : "Victus hardware control";
            hero_subtitle_label.label = build_subtitle(snapshot);
            helper_state_label.label = "Helper state: %s".printf(snapshot.helper_state);
        }

        /** Show offline / error state. */
        public void show_offline (string error_message) {
            status_label.label = "Offline";
            hero_title_label.label = "Victus hardware control";
            hero_subtitle_label.label = "The helper is unavailable, so the dashboard cannot fetch live hardware state.";
            helper_state_label.label = error_message;
        }

        /** Show action error on the status pill. */
        public void show_error (string error_message) {
            status_label.label = "Error";
            helper_state_label.label = error_message;
        }

        private string build_subtitle (Snapshot snapshot) {
            var temp_summary = snapshot.max_temp_c >= 0
                ? "Peak %d\u00b0C".printf(snapshot.max_temp_c)
                : "Peak temperature unavailable";
            var profile_summary = snapshot.active_hardware_profile != ""
                ? "Hardware profile %s".printf(Formatting.profile(snapshot.active_hardware_profile))
                : "Hardware profile unavailable";
            return "%s. %s.".printf(profile_summary, temp_summary);
        }
    }
}
