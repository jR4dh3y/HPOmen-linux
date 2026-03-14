namespace VictusControl {
    /**
     * Top-level application window.
     *
     * Extremely compact 2-column layout.
     */
    public class MainWindow : Gtk.ApplicationWindow {
        private AppController controller;
        private AppConfig config;

        private HeroSection hero;
        private ThermalSection thermal;
        private ProfileSection profiles;
        private FanSection fans;

        public MainWindow (Gtk.Application app, AppConfig config) {
            // Tightened height massively since we removed the Overview section
            Object(application: app, title: APP_NAME, default_width: 880, default_height: 480);
            this.config = config;

            CssLoader.load();

            /* ---- controller ---- */
            controller = new AppController(config);

            controller.snapshot_updated.connect(on_snapshot);
            controller.connection_lost.connect(on_connection_lost);
            controller.action_failed.connect(on_action_failed);

            /* ---- widget tree ---- */
            hero = new HeroSection();
            thermal = new ThermalSection();
            profiles = new ProfileSection();
            fans = new FanSection();

            /* wire widget signals -> controller actions */
            profiles.profile_requested.connect((p) => controller.set_profile(p));
            profiles.auto_policy_toggled.connect((e) => controller.set_auto_policy(e));
            fans.fan_mode_requested.connect((m) => controller.set_fan_mode(m));

            /* ---- layout ---- */
            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
            main_box.add_css_class("app-grid");
            main_box.margin_top = 16;
            main_box.margin_bottom = 16;
            main_box.margin_start = 16;
            main_box.margin_end = 16;

            main_box.append(hero);

            var columns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 16);
            columns.hexpand = true;
            columns.vexpand = true;

            // Left Column
            var left_col = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
            left_col.hexpand = true;
            left_col.vexpand = true;
            left_col.append(thermal);

            // Right Column
            var right_col = new Gtk.Box(Gtk.Orientation.VERTICAL, 16);
            right_col.hexpand = true;
            right_col.vexpand = true;
            right_col.append(profiles);
            right_col.append(fans); // Fan section takes the place of System Overview

            columns.append(left_col);
            columns.append(right_col);

            main_box.append(columns);
            
            set_child(main_box);

            /* ---- start polling ---- */
            controller.start_polling();
        }

        /* ---- signal handlers ---- */

        private void on_snapshot (Snapshot snapshot) {
            hero.update(snapshot);
            thermal.update(snapshot);
            profiles.update(snapshot);
            fans.update(snapshot, config.hide_unsupported_fan_controls);
        }

        private void on_connection_lost (string error_message) {
            hero.show_offline(error_message);
            thermal.show_offline();
            profiles.show_offline();
            fans.show_offline(error_message, config.hide_unsupported_fan_controls);
        }

        private void on_action_failed (string error_message) {
            hero.show_error(error_message);
        }
    }
}
