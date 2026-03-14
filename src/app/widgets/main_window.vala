namespace VictusControl {
    /**
     * Top-level application window.
     *
     * This is a thin shell that assembles the section widgets, owns
     * the AppController, and wires controller signals to widget
     * update methods.  No D-Bus calls or business logic live here.
     */
    public class MainWindow : Gtk.ApplicationWindow {
        private AppController controller;
        private AppConfig config;

        private HeroSection hero;
        private OverviewSection overview;
        private ThermalSection thermal;
        private ProfileSection profiles;
        private FanSection fans;

        public MainWindow (Gtk.Application app, AppConfig config) {
            Object(application: app, title: APP_NAME, default_width: 960, default_height: 720);
            this.config = config;

            CssLoader.load();

            /* ---- controller ---- */
            controller = new AppController(config);

            controller.snapshot_updated.connect(on_snapshot);
            controller.connection_lost.connect(on_connection_lost);
            controller.action_failed.connect(on_action_failed);

            /* ---- widget tree ---- */
            hero = new HeroSection();
            overview = new OverviewSection();
            thermal = new ThermalSection();
            profiles = new ProfileSection();
            fans = new FanSection();

            /* wire widget signals -> controller actions */
            profiles.profile_requested.connect((p) => controller.set_profile(p));
            profiles.auto_policy_toggled.connect((e) => controller.set_auto_policy(e));
            fans.fan_mode_requested.connect((m) => controller.set_fan_mode(m));

            /* ---- layout ---- */
            var scroller = new Gtk.ScrolledWindow();
            scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scroller.vexpand = true;

            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 18);
            main_box.add_css_class("app-shell");
            main_box.margin_top = 20;
            main_box.margin_bottom = 20;
            main_box.margin_start = 20;
            main_box.margin_end = 20;

            main_box.append(hero);
            main_box.append(overview);
            main_box.append(thermal);
            main_box.append(profiles);
            main_box.append(fans);

            scroller.set_child(main_box);
            set_child(scroller);

            /* ---- start polling ---- */
            controller.start_polling();
        }

        /* ---- signal handlers ---- */

        private void on_snapshot (Snapshot snapshot) {
            hero.update(snapshot);
            overview.update(snapshot);
            thermal.update(snapshot);
            profiles.update(snapshot);
            fans.update(snapshot, config.hide_unsupported_fan_controls);
        }

        private void on_connection_lost (string error_message) {
            hero.show_offline(error_message);
            overview.show_offline();
            thermal.show_offline();
            profiles.show_offline();
            fans.show_offline(error_message, config.hide_unsupported_fan_controls);
        }

        private void on_action_failed (string error_message) {
            hero.show_error(error_message);
        }
    }
}
