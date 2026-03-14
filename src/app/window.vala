namespace VictusControl {
    public class MainWindow : Gtk.ApplicationWindow {
        private ControlClient? client;
        private AppConfig config;

        private Gtk.Label status_label;
        private Gtk.Label hero_title_label;
        private Gtk.Label hero_subtitle_label;
        private Gtk.Label helper_state_label;

        private Gtk.Label product_label;
        private Gtk.Label board_label;
        private Gtk.Label bios_label;
        private Gtk.Label profile_label;
        private Gtk.Label choices_label;

        private Gtk.Label cpu_temp_label;
        private Gtk.Label gpu_temp_label;
        private Gtk.Label max_temp_label;
        private Gtk.ProgressBar cpu_temp_bar;
        private Gtk.ProgressBar gpu_temp_bar;
        private Gtk.ProgressBar max_temp_bar;

        private Gtk.Label fan1_label;
        private Gtk.Label fan2_label;
        private Gtk.Label rpm_summary_label;

        private Gtk.Label profile_hint_label;
        private Gtk.Switch auto_policy_switch;
        private Gtk.Button quiet_button;
        private Gtk.Button balanced_button;
        private Gtk.Button performance_button;

        private Gtk.Box fan_section_box;
        private Gtk.Label fan_support_label;
        private Gtk.Label fan_mode_label;
        private Gtk.Button fan_auto_button;
        private Gtk.Button fan_max_button;

        private bool updating_auto_policy = false;

        public MainWindow (Gtk.Application app, AppConfig config) {
            Object(application: app, title: APP_NAME, default_width: 960, default_height: 720);
            this.config = config;

            load_css();

            try {
                client = new ControlClient();
            } catch (Error error) {
                warning("Failed to connect to helper on startup: %s", error.message);
            }

            var scroller = new Gtk.ScrolledWindow();
            scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scroller.vexpand = true;

            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 18);
            main_box.add_css_class("app-shell");
            main_box.margin_top = 20;
            main_box.margin_bottom = 20;
            main_box.margin_start = 20;
            main_box.margin_end = 20;

            main_box.append(build_hero_section());
            main_box.append(build_overview_section());
            main_box.append(build_thermal_section());
            main_box.append(build_actions_section());
            main_box.append(build_fan_section());

            scroller.set_child(main_box);
            set_child(scroller);

            refresh_snapshot();
            Timeout.add_seconds(config.poll_interval_seconds, () => {
                refresh_snapshot();
                return true;
            });
        }

        private Gtk.Widget build_hero_section () {
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
            accent_box.append(create_panel_value("Profiles", "Quiet / Balanced / Performance"));
            accent_box.append(create_panel_value("Fan modes", "Auto / Max"));

            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 24);
            box.add_css_class("hero-card");
            box.append(text_box);
            box.append(accent_box);
            return box;
        }

        private Gtk.Widget build_overview_section () {
            product_label = create_value_label("");
            board_label = create_value_label("");
            bios_label = create_value_label("");
            profile_label = create_value_label("");
            choices_label = create_value_label("");

            var grid = new Gtk.Grid();
            grid.column_spacing = 18;
            grid.row_spacing = 18;
            grid.attach(create_info_card("Product", product_label), 0, 0, 1, 1);
            grid.attach(create_info_card("Board", board_label), 1, 0, 1, 1);
            grid.attach(create_info_card("BIOS", bios_label), 2, 0, 1, 1);
            grid.attach(create_info_card("Active profile", profile_label), 0, 1, 1, 1);
            grid.attach(create_info_card("Available profiles", choices_label), 1, 1, 2, 1);

            return wrap_section("System Overview", "Identity, firmware, and Linux platform profile state.", grid);
        }

        private Gtk.Widget build_thermal_section () {
            cpu_temp_label = create_metric_value_label();
            gpu_temp_label = create_metric_value_label();
            max_temp_label = create_metric_value_label();
            cpu_temp_bar = create_metric_bar();
            gpu_temp_bar = create_metric_bar();
            max_temp_bar = create_metric_bar();
            fan1_label = create_metric_value_label();
            fan2_label = create_metric_value_label();
            rpm_summary_label = create_value_label("");

            var grid = new Gtk.Grid();
            grid.column_spacing = 18;
            grid.row_spacing = 18;
            grid.attach(create_metric_card("CPU", "Processor temperature", cpu_temp_label, cpu_temp_bar), 0, 0, 1, 1);
            grid.attach(create_metric_card("GPU", "Graphics temperature", gpu_temp_label, gpu_temp_bar), 1, 0, 1, 1);
            grid.attach(create_metric_card("Peak", "Highest thermal reading", max_temp_label, max_temp_bar), 2, 0, 1, 1);
            grid.attach(create_simple_card("Fan 1", "Primary fan speed", fan1_label), 0, 1, 1, 1);
            grid.attach(create_simple_card("Fan 2", "Secondary fan speed", fan2_label), 1, 1, 1, 1);
            grid.attach(create_info_card("RPM summary", rpm_summary_label), 2, 1, 1, 1);

            return wrap_section("Thermal Telemetry", "Live temperatures and RPM reporting from hwmon and HP WMI.", grid);
        }

        private Gtk.Widget build_actions_section () {
            quiet_button = create_action_button("Quiet");
            balanced_button = create_action_button("Balanced");
            performance_button = create_action_button("Performance");
            quiet_button.clicked.connect(() => set_profile("quiet"));
            balanced_button.clicked.connect(() => set_profile("balanced"));
            performance_button.clicked.connect(() => set_profile("performance"));

            profile_hint_label = create_value_label("");
            profile_hint_label.add_css_class("muted-text");

            auto_policy_switch = new Gtk.Switch();
            auto_policy_switch.valign = Gtk.Align.CENTER;
            auto_policy_switch.notify["active"].connect(() => {
                if (updating_auto_policy || !auto_policy_switch.is_sensitive()) {
                    return;
                }
                set_auto_policy(auto_policy_switch.active);
            });

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            button_row.append(quiet_button);
            button_row.append(balanced_button);
            button_row.append(performance_button);

            var switch_label = new Gtk.Label("Temperature-driven auto policy");
            switch_label.halign = Gtk.Align.START;
            switch_label.hexpand = true;

            var switch_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            switch_row.add_css_class("inline-card");
            switch_row.append(switch_label);
            switch_row.append(auto_policy_switch);

            var action_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 14);
            action_box.append(button_row);
            action_box.append(profile_hint_label);
            action_box.append(switch_row);

            return wrap_section("Performance Controls", "Capability-aware profile switching backed by the helper service.", action_box);
        }

        private Gtk.Widget build_fan_section () {
            fan_section_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 14);
            fan_support_label = create_value_label("");
            fan_support_label.add_css_class("muted-text");
            fan_mode_label = create_metric_value_label();
            fan_auto_button = create_action_button("Auto");
            fan_max_button = create_action_button("Max");
            fan_auto_button.clicked.connect(() => set_fan_mode("auto"));
            fan_max_button.clicked.connect(() => set_fan_mode("max"));

            var current_mode_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            current_mode_box.add_css_class("inline-card");
            var current_mode_title = new Gtk.Label("Current fan mode");
            current_mode_title.halign = Gtk.Align.START;
            current_mode_title.hexpand = true;
            current_mode_box.append(current_mode_title);
            current_mode_box.append(fan_mode_label);

            var button_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            button_row.append(fan_auto_button);
            button_row.append(fan_max_button);

            fan_section_box.append(fan_support_label);
            fan_section_box.append(current_mode_box);
            fan_section_box.append(button_row);

            return wrap_section("Fan Control", "Validated HP WMI fan modes only. Granular fan levels remain blocked.", fan_section_box);
        }

        private Gtk.Widget wrap_section (string title, string subtitle, Gtk.Widget child) {
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

        private Gtk.Widget create_info_card (string title, Gtk.Label value_label) {
            return create_card(title, null, value_label, null);
        }

        private Gtk.Widget create_simple_card (string title, string subtitle, Gtk.Label value_label) {
            return create_card(title, subtitle, value_label, null);
        }

        private Gtk.Widget create_metric_card (string title, string subtitle, Gtk.Label value_label, Gtk.ProgressBar bar) {
            return create_card(title, subtitle, value_label, bar);
        }

        private Gtk.Widget create_card (string title, string? subtitle, Gtk.Label value_label, Gtk.ProgressBar? bar) {
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

        private Gtk.Widget create_panel_value (string title, string value) {
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

        private Gtk.Label create_value_label (string text) {
            var label = new Gtk.Label(text);
            label.selectable = true;
            label.wrap = true;
            label.halign = Gtk.Align.START;
            label.xalign = 0.0f;
            return label;
        }

        private Gtk.Label create_metric_value_label () {
            var label = create_value_label("");
            label.add_css_class("metric-value");
            return label;
        }

        private Gtk.ProgressBar create_metric_bar () {
            var bar = new Gtk.ProgressBar();
            bar.hexpand = true;
            bar.show_text = false;
            bar.add_css_class("thermal-bar");
            return bar;
        }

        private Gtk.Button create_action_button (string label) {
            var button = new Gtk.Button.with_label(label);
            button.add_css_class("pill-button");
            return button;
        }

        private void refresh_snapshot () {
            try {
                ensure_client();
                var snapshot = client.get_snapshot();

                status_label.label = "Online";
                hero_title_label.label = snapshot.product_name != ""
                    ? "%s control surface".printf(snapshot.product_name)
                    : "Victus hardware control";
                hero_subtitle_label.label = build_hero_subtitle(snapshot);
                helper_state_label.label = "Helper state: %s".printf(snapshot.helper_state);

                product_label.label = fallback_text(snapshot.product_name);
                board_label.label = fallback_text(snapshot.board_name);
                bios_label.label = fallback_text(snapshot.bios_version);
                profile_label.label = fallback_text(format_profile(snapshot.active_profile));
                choices_label.label = format_profiles(snapshot.available_profiles);

                update_temperature_card(cpu_temp_label, cpu_temp_bar, snapshot.cpu_temp_c);
                update_temperature_card(gpu_temp_label, gpu_temp_bar, snapshot.gpu_temp_c);
                update_temperature_card(max_temp_label, max_temp_bar, snapshot.max_temp_c);

                fan1_label.label = format_metric(snapshot.fan1_rpm, " RPM");
                fan2_label.label = format_metric(snapshot.fan2_rpm, " RPM");
                rpm_summary_label.label = build_rpm_summary(snapshot);

                update_profile_buttons(snapshot);
                updating_auto_policy = true;
                auto_policy_switch.sensitive = true;
                auto_policy_switch.active = snapshot.auto_policy_enabled;
                updating_auto_policy = false;

                profile_hint_label.label = snapshot.can_set_profile
                    ? "Choose a platform profile or leave auto policy enabled to let the helper react to thermals."
                    : "Platform profile switching is unavailable on this host.";

                fan_mode_label.label = format_fan_mode(snapshot.active_fan_mode);
                fan_support_label.label = snapshot.can_set_fan_mode
                    ? "Mode-based control is available. Auto returns control to firmware; Max forces the fans to full speed."
                    : fallback_text(snapshot.fan_control_reason);
                fan_auto_button.sensitive = snapshot.can_set_fan_mode && snapshot.active_fan_mode != "auto";
                fan_max_button.sensitive = snapshot.can_set_fan_mode && snapshot.active_fan_mode != "max";
                update_active_button(fan_auto_button, snapshot.active_fan_mode == "auto");
                update_active_button(fan_max_button, snapshot.active_fan_mode == "max");
                fan_section_box.visible = !config.hide_unsupported_fan_controls || snapshot.can_set_fan_mode;
            } catch (Error error) {
                status_label.label = "Offline";
                hero_title_label.label = "Victus hardware control";
                hero_subtitle_label.label = "The helper is unavailable, so the dashboard cannot fetch live hardware state.";
                helper_state_label.label = error.message;

                product_label.label = "Unavailable";
                board_label.label = "Unavailable";
                bios_label.label = "Unavailable";
                profile_label.label = "Unavailable";
                choices_label.label = "Unavailable";

                update_temperature_card(cpu_temp_label, cpu_temp_bar, -1);
                update_temperature_card(gpu_temp_label, gpu_temp_bar, -1);
                update_temperature_card(max_temp_label, max_temp_bar, -1);
                fan1_label.label = "Unavailable";
                fan2_label.label = "Unavailable";
                rpm_summary_label.label = "No RPM telemetry";

                set_profile_controls_available(false);
                updating_auto_policy = true;
                auto_policy_switch.sensitive = false;
                auto_policy_switch.active = false;
                updating_auto_policy = false;
                profile_hint_label.label = "Start victusd to enable profile controls.";

                fan_support_label.label = error.message;
                fan_mode_label.label = "Unavailable";
                fan_auto_button.sensitive = false;
                fan_max_button.sensitive = false;
                update_active_button(fan_auto_button, false);
                update_active_button(fan_max_button, false);
                fan_section_box.visible = !config.hide_unsupported_fan_controls;
                client = null;
            }
        }

        private void update_profile_buttons (Snapshot snapshot) {
            var has_profiles = snapshot.can_set_profile && snapshot.available_profiles.length > 0;
            set_profile_controls_available(has_profiles);

            var active = snapshot.active_profile.down();
            update_profile_button_state(quiet_button, has_profile(snapshot, "quiet"), active == "quiet");
            update_profile_button_state(balanced_button, has_profile(snapshot, "balanced"), active == "balanced");
            update_profile_button_state(performance_button, has_profile(snapshot, "performance"), active == "performance");
        }

        private void set_profile_controls_available (bool available) {
            quiet_button.sensitive = available;
            balanced_button.sensitive = available;
            performance_button.sensitive = available;
        }

        private void update_profile_button_state (Gtk.Button button, bool supported, bool active) {
            button.sensitive = supported;
            update_active_button(button, active);
        }

        private void update_active_button (Gtk.Button button, bool active) {
            if (active) {
                button.add_css_class("active-pill");
            } else {
                button.remove_css_class("active-pill");
            }
        }

        private void update_temperature_card (Gtk.Label value_label, Gtk.ProgressBar bar, int value) {
            value_label.label = format_metric(value, "°C");
            bar.fraction = normalize_temperature(value);
        }

        private double normalize_temperature (int value) {
            if (value < 0) {
                return 0.0;
            }
            var fraction = (double) value / 100.0;
            return fraction > 1.0 ? 1.0 : fraction;
        }

        private bool has_profile (Snapshot snapshot, string name) {
            foreach (var profile in snapshot.available_profiles) {
                if (profile.down() == name) {
                    return true;
                }
            }
            return false;
        }

        private void set_profile (string profile) {
            try {
                ensure_client();
                client.set_platform_profile(profile);
                refresh_snapshot();
            } catch (Error error) {
                status_label.label = "Error";
                helper_state_label.label = error.message;
            }
        }

        private void set_auto_policy (bool enabled) {
            try {
                ensure_client();
                client.set_auto_policy(enabled);
                refresh_snapshot();
            } catch (Error error) {
                status_label.label = "Error";
                helper_state_label.label = error.message;
            }
        }

        private void set_fan_mode (string mode) {
            try {
                ensure_client();
                client.set_fan_mode(mode);
                refresh_snapshot();
            } catch (Error error) {
                status_label.label = "Error";
                helper_state_label.label = error.message;
            }
        }

        private void ensure_client () throws Error {
            if (client == null) {
                client = new ControlClient();
            }
        }

        private string build_hero_subtitle (Snapshot snapshot) {
            var temp_summary = snapshot.max_temp_c >= 0
                ? "Peak %d°C".printf(snapshot.max_temp_c)
                : "Peak temperature unavailable";
            var profile_summary = snapshot.active_profile != ""
                ? "Profile %s".printf(format_profile(snapshot.active_profile))
                : "Profile unavailable";
            return "%s. %s.".printf(profile_summary, temp_summary);
        }

        private string build_rpm_summary (Snapshot snapshot) {
            if (!snapshot.can_read_rpm) {
                return "RPM telemetry unavailable";
            }

            if (snapshot.fan1_rpm >= 0 && snapshot.fan2_rpm >= 0) {
                return "%d / %d RPM".printf(snapshot.fan1_rpm, snapshot.fan2_rpm);
            }

            if (snapshot.fan1_rpm >= 0) {
                return "Fan 1 at %d RPM".printf(snapshot.fan1_rpm);
            }

            if (snapshot.fan2_rpm >= 0) {
                return "Fan 2 at %d RPM".printf(snapshot.fan2_rpm);
            }

            return "No live fan speed data";
        }

        private string fallback_text (string value) {
            return value != null && value != "" ? value : "Unavailable";
        }

        private string format_profiles (string[] profiles) {
            if (profiles.length == 0) {
                return "Unavailable";
            }

            string[] formatted = new string[profiles.length];
            for (var i = 0; i < profiles.length; i++) {
                formatted[i] = format_profile(profiles[i]);
            }
            return string.joinv(" / ", formatted);
        }

        private string format_profile (string profile) {
            switch (profile.down()) {
            case "quiet":
                return "Quiet";
            case "balanced":
                return "Balanced";
            case "performance":
                return "Performance";
            default:
                return profile != "" ? profile : "Unavailable";
            }
        }

        private string format_metric (int value, string suffix) {
            return value >= 0 ? "%d%s".printf(value, suffix) : "Unavailable";
        }

        private string format_fan_mode (string mode) {
            switch (mode) {
            case "auto":
                return "Auto";
            case "max":
                return "Max";
            case "unavailable":
                return "Unavailable";
            default:
                return "Unknown";
            }
        }

        private void load_css () {
            var provider = new Gtk.CssProvider();
            provider.load_from_string("""
                window {
                    background:
                        linear-gradient(180deg, #11161d 0%, #191f29 42%, #0d1117 100%);
                    color: #f3efe5;
                }

                .app-shell {
                    min-height: 680px;
                }

                .hero-card,
                .section-card,
                .metric-card,
                .inline-card,
                .accent-panel {
                    border-radius: 20px;
                }

                .hero-card,
                .section-card {
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

                .accent-panel,
                .metric-card,
                .inline-card {
                    background: rgba(255, 255, 255, 0.04);
                    border: 1px solid rgba(255, 255, 255, 0.08);
                    padding: 16px;
                }

                .hero-title {
                    font-family: "IBM Plex Sans", sans-serif;
                    font-size: 30px;
                    font-weight: 700;
                    letter-spacing: 0.02em;
                }

                .hero-subtitle,
                .section-subtitle,
                .card-subtitle,
                .muted-text {
                    color: rgba(243, 239, 229, 0.72);
                }

                .section-title {
                    font-family: "IBM Plex Sans", sans-serif;
                    font-size: 20px;
                    font-weight: 700;
                    letter-spacing: 0.04em;
                }

                .card-title,
                .panel-title,
                .eyebrow {
                    color: rgba(243, 239, 229, 0.62);
                    text-transform: uppercase;
                    letter-spacing: 0.14em;
                    font-size: 11px;
                    font-weight: 700;
                }

                .panel-value {
                    font-family: "JetBrains Mono", monospace;
                    font-size: 13px;
                    color: #ffd7a8;
                }

                .metric-value {
                    font-family: "JetBrains Mono", monospace;
                    font-size: 28px;
                    font-weight: 700;
                    color: #fff7ea;
                }

                .status-pill {
                    background: rgba(255, 164, 77, 0.18);
                    color: #ffd7a8;
                    padding: 6px 12px;
                    border-radius: 999px;
                    font-weight: 700;
                    letter-spacing: 0.08em;
                    text-transform: uppercase;
                }

                .pill-button {
                    min-height: 42px;
                    padding: 0 16px;
                    border-radius: 999px;
                    background: rgba(255, 255, 255, 0.06);
                    color: #f3efe5;
                    border: 1px solid rgba(255, 255, 255, 0.08);
                    font-weight: 700;
                }

                .pill-button:hover {
                    background: rgba(255, 255, 255, 0.12);
                }

                .active-pill {
                    background: linear-gradient(90deg, #ff9f43, #ef4444);
                    color: #130d09;
                    border-color: transparent;
                }

                .thermal-bar trough {
                    background: rgba(255, 255, 255, 0.06);
                    border-radius: 999px;
                    min-height: 8px;
                }

                .thermal-bar progress {
                    background: linear-gradient(90deg, #f59e0b, #ef4444);
                    border-radius: 999px;
                    min-height: 8px;
                }
            """);

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
