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

            load_css();

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

        /* ---- CSS ---- */

        private void load_css () {
            var provider = new Gtk.CssProvider();
            var css_path = Path.build_filename(
                Path.get_dirname(Environment.find_program_in_path("victus-control") ?? ""),
                "..", "share", "victus-control", "style.css"
            );

            /* Try installed path first, then fall back to source-tree path. */
            if (Fs.exists(css_path)) {
                provider.load_from_path(css_path);
            } else {
                /* Inline fallback so the app works without an install step. */
                provider.load_from_string("""
                    window {
                        background:
                            linear-gradient(180deg, #11161d 0%, #191f29 42%, #0d1117 100%);
                        color: #f3efe5;
                    }
                    .app-shell { min-height: 680px; }
                    .hero-card, .section-card, .metric-card, .inline-card, .accent-panel {
                        border-radius: 20px;
                    }
                    .hero-card, .section-card {
                        background: rgba(12, 16, 23, 0.82);
                        border: 1px solid rgba(255, 255, 255, 0.08);
                        box-shadow: 0 20px 50px rgba(0, 0, 0, 0.28);
                        padding: 24px;
                    }
                    .hero-card {
                        background:
                            radial-gradient(circle at top right, rgba(249, 115, 22, 0.18), transparent 28%),
                            linear-gradient(135deg, rgba(123, 31, 32, 0.34), rgba(15, 18, 24, 0.96));
                    }
                    .accent-panel, .metric-card, .inline-card {
                        background: rgba(255, 255, 255, 0.04);
                        border: 1px solid rgba(255, 255, 255, 0.08);
                        padding: 16px;
                    }
                    .hero-title {
                        font-family: "IBM Plex Sans", sans-serif;
                        font-size: 30px; font-weight: 700; letter-spacing: 0.02em;
                    }
                    .hero-subtitle, .section-subtitle, .card-subtitle, .muted-text {
                        color: rgba(243, 239, 229, 0.72);
                    }
                    .section-title {
                        font-family: "IBM Plex Sans", sans-serif;
                        font-size: 20px; font-weight: 700; letter-spacing: 0.04em;
                    }
                    .card-title, .panel-title, .eyebrow {
                        color: rgba(243, 239, 229, 0.62);
                        text-transform: uppercase; letter-spacing: 0.14em;
                        font-size: 11px; font-weight: 700;
                    }
                    .panel-value {
                        font-family: "JetBrains Mono", monospace;
                        font-size: 13px; color: #ffd7a8;
                    }
                    .metric-value {
                        font-family: "JetBrains Mono", monospace;
                        font-size: 28px; font-weight: 700; color: #fff7ea;
                    }
                    .status-pill {
                        background: rgba(255, 164, 77, 0.18); color: #ffd7a8;
                        padding: 6px 12px; border-radius: 999px;
                        font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase;
                    }
                    .pill-button {
                        min-height: 42px; padding: 0 16px; border-radius: 999px;
                        background: rgba(255, 255, 255, 0.06); color: #f3efe5;
                        border: 1px solid rgba(255, 255, 255, 0.08); font-weight: 700;
                    }
                    .pill-button:hover { background: rgba(255, 255, 255, 0.12); }
                    .active-pill {
                        background: linear-gradient(90deg, #ff9f43, #ef4444);
                        color: #130d09; border-color: transparent;
                    }
                    .thermal-bar trough {
                        background: rgba(255, 255, 255, 0.06);
                        border-radius: 999px; min-height: 8px;
                    }
                    .thermal-bar progress {
                        background: linear-gradient(90deg, #f59e0b, #ef4444);
                        border-radius: 999px; min-height: 8px;
                    }
                """);
            }

            var display = Gdk.Display.get_default();
            if (display != null) {
                Gtk.StyleContext.add_provider_for_display(
                    display,
                    provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
            }
        }
    }
}
