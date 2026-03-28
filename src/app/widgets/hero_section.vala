namespace VictusControl {
    /**
     * Ultra-compact Hero banner
     */
    public class HeroSection : Gtk.Box {
        private Gtk.Label status_label;
        private Gtk.Label hero_title_label;
        private string saved_title = "Victus Control";
        private uint error_timeout_id = 0;

        public HeroSection () {
            Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 16);
            add_css_class("hero-card");

            hero_title_label = new Gtk.Label("Victus Control");
            hero_title_label.halign = Gtk.Align.START;
            hero_title_label.hexpand = true;
            hero_title_label.wrap = false;
            hero_title_label.ellipsize = Pango.EllipsizeMode.END;
            hero_title_label.add_css_class("hero-title");

            status_label = new Gtk.Label("Connecting");
            status_label.halign = Gtk.Align.END;
            status_label.valign = Gtk.Align.CENTER;
            status_label.add_css_class("status-pill");

            append(hero_title_label);
            append(status_label);
        }

        public void update (Snapshot snapshot) {
            if (error_timeout_id != 0) {
                return;
            }
            status_label.label = "Online";
            saved_title = snapshot.product_name != ""
                ? snapshot.product_name
                : "Victus Hardware Control";
            hero_title_label.label = saved_title;
        }

        public void show_offline (string error_message) {
            clear_error_timeout ();
            status_label.label = "Offline";
            hero_title_label.label = "Victus Control";
        }

        public void show_error (string error_message) {
            clear_error_timeout ();
            status_label.label = "Error";
            hero_title_label.label = error_message;
            error_timeout_id = Timeout.add_seconds (6, () => {
                error_timeout_id = 0;
                status_label.label = "Online";
                hero_title_label.label = saved_title;
                return false;
            });
        }

        private void clear_error_timeout () {
            if (error_timeout_id != 0) {
                Source.remove (error_timeout_id);
                error_timeout_id = 0;
            }
        }
    }
}
