namespace VictusControl {
    public class MainWindow : Gtk.ApplicationWindow {
        private ControlClient? client;
        private AppConfig config;
        private Gtk.Label status_label;
        private Gtk.Label product_label;
        private Gtk.Label board_label;
        private Gtk.Label bios_label;
        private Gtk.Label profile_label;
        private Gtk.Label choices_label;
        private Gtk.Label cpu_temp_label;
        private Gtk.Label gpu_temp_label;
        private Gtk.Label max_temp_label;
        private Gtk.Label fan1_label;
        private Gtk.Label fan2_label;
        private Gtk.Label fan_support_label;
        private Gtk.Switch auto_policy_switch;
        private Gtk.Button quiet_button;
        private Gtk.Button balanced_button;
        private Gtk.Button performance_button;
        private Gtk.SpinButton cpu_spin;
        private Gtk.SpinButton gpu_spin;
        private Gtk.Button apply_fans_button;

        public MainWindow (Gtk.Application app, AppConfig config) {
            Object(application: app, title: APP_NAME, default_width: 760, default_height: 520);
            this.config = config;

            try {
                client = new ControlClient();
            } catch (Error error) {
                warning("Failed to connect to helper on startup: %s", error.message);
            }

            var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 18);
            main_box.margin_top = 18;
            main_box.margin_bottom = 18;
            main_box.margin_start = 18;
            main_box.margin_end = 18;

            status_label = create_value_label("Connecting to helper…");
            status_label.add_css_class("title-3");
            main_box.append(status_label);

            main_box.append(build_system_frame());
            main_box.append(build_thermal_frame());
            main_box.append(build_actions_frame());
            main_box.append(build_fan_frame());

            set_child(main_box);

            refresh_snapshot();
            Timeout.add_seconds(config.poll_interval_seconds, () => {
                refresh_snapshot();
                return true;
            });
        }

        private Gtk.Widget build_system_frame () {
            product_label = create_value_label("");
            board_label = create_value_label("");
            bios_label = create_value_label("");
            profile_label = create_value_label("");
            choices_label = create_value_label("");
            var grid = new Gtk.Grid();
            grid.row_spacing = 8;
            grid.column_spacing = 16;
            add_grid_row(grid, 0, "Product", product_label);
            add_grid_row(grid, 1, "Board", board_label);
            add_grid_row(grid, 2, "BIOS", bios_label);
            add_grid_row(grid, 3, "Active profile", profile_label);
            add_grid_row(grid, 4, "Available profiles", choices_label);
            return wrap_frame("System", grid);
        }

        private Gtk.Widget build_thermal_frame () {
            cpu_temp_label = create_value_label("");
            gpu_temp_label = create_value_label("");
            max_temp_label = create_value_label("");
            fan1_label = create_value_label("");
            fan2_label = create_value_label("");
            var grid = new Gtk.Grid();
            grid.row_spacing = 8;
            grid.column_spacing = 16;
            add_grid_row(grid, 0, "CPU temp", cpu_temp_label);
            add_grid_row(grid, 1, "GPU temp", gpu_temp_label);
            add_grid_row(grid, 2, "Max temp", max_temp_label);
            add_grid_row(grid, 3, "Fan 1 RPM", fan1_label);
            add_grid_row(grid, 4, "Fan 2 RPM", fan2_label);
            return wrap_frame("Thermals", grid);
        }

        private Gtk.Widget build_actions_frame () {
            quiet_button = new Gtk.Button.with_label("Quiet");
            balanced_button = new Gtk.Button.with_label("Balanced");
            performance_button = new Gtk.Button.with_label("Performance");
            quiet_button.clicked.connect(() => set_profile("quiet"));
            balanced_button.clicked.connect(() => set_profile("balanced"));
            performance_button.clicked.connect(() => set_profile("performance"));

            var buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            buttons.append(quiet_button);
            buttons.append(balanced_button);
            buttons.append(performance_button);

            auto_policy_switch = new Gtk.Switch();
            auto_policy_switch.notify["active"].connect(() => {
                if (!auto_policy_switch.is_sensitive()) {
                    return;
                }
                set_auto_policy(auto_policy_switch.active);
            });

            var auto_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            auto_box.append(new Gtk.Label("Auto policy"));
            auto_box.append(auto_policy_switch);

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.append(buttons);
            box.append(auto_box);
            return wrap_frame("Actions", box);
        }

        private Gtk.Widget build_fan_frame () {
            fan_support_label = create_value_label("");
            cpu_spin = new Gtk.SpinButton.with_range(0, 10000, 100);
            gpu_spin = new Gtk.SpinButton.with_range(0, 10000, 100);
            apply_fans_button = new Gtk.Button.with_label("Apply Fan Levels");
            apply_fans_button.clicked.connect(() => apply_fan_levels());

            var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            row.append(new Gtk.Label("CPU"));
            row.append(cpu_spin);
            row.append(new Gtk.Label("GPU"));
            row.append(gpu_spin);
            row.append(apply_fans_button);

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.append(fan_support_label);
            box.append(row);
            return wrap_frame("Direct Fan Control", box);
        }

        private void add_grid_row (Gtk.Grid grid, int row, string title, Gtk.Widget value) {
            var label = new Gtk.Label(title);
            label.halign = Gtk.Align.START;
            grid.attach(label, 0, row, 1, 1);
            grid.attach(value, 1, row, 1, 1);
        }

        private Gtk.Widget wrap_frame (string title, Gtk.Widget child) {
            var frame = new Gtk.Frame(title);
            frame.set_child(child);
            return frame;
        }

        private Gtk.Label create_value_label (string text) {
            var label = new Gtk.Label(text);
            label.selectable = true;
            label.wrap = true;
            label.halign = Gtk.Align.START;
            return label;
        }

        private void refresh_snapshot () {
            try {
                ensure_client();
                var snapshot = client.get_snapshot();
                status_label.label = "Helper connected";
                product_label.label = snapshot.product_name;
                board_label.label = snapshot.board_name;
                bios_label.label = snapshot.bios_version;
                profile_label.label = snapshot.active_profile;
                choices_label.label = string.joinv(", ", snapshot.available_profiles);
                cpu_temp_label.label = format_metric(snapshot.cpu_temp_c, "°C");
                gpu_temp_label.label = format_metric(snapshot.gpu_temp_c, "°C");
                max_temp_label.label = format_metric(snapshot.max_temp_c, "°C");
                fan1_label.label = format_metric(snapshot.fan1_rpm, " RPM");
                fan2_label.label = format_metric(snapshot.fan2_rpm, " RPM");
                fan_support_label.label = snapshot.can_direct_fan_control
                    ? "Direct fan control is enabled for this machine."
                    : snapshot.fan_control_reason;
                auto_policy_switch.sensitive = true;
                auto_policy_switch.active = snapshot.auto_policy_enabled;
                cpu_spin.sensitive = snapshot.can_direct_fan_control;
                gpu_spin.sensitive = snapshot.can_direct_fan_control;
                apply_fans_button.sensitive = snapshot.can_direct_fan_control;
            } catch (Error error) {
                status_label.label = "Helper unavailable";
                fan_support_label.label = error.message;
                auto_policy_switch.sensitive = false;
                cpu_spin.sensitive = false;
                gpu_spin.sensitive = false;
                apply_fans_button.sensitive = false;
                client = null;
            }
        }

        private void set_profile (string profile) {
            try {
                ensure_client();
                client.set_platform_profile(profile);
                refresh_snapshot();
            } catch (Error error) {
                status_label.label = error.message;
            }
        }

        private void set_auto_policy (bool enabled) {
            try {
                ensure_client();
                client.set_auto_policy(enabled);
                refresh_snapshot();
            } catch (Error error) {
                status_label.label = error.message;
            }
        }

        private void apply_fan_levels () {
            try {
                ensure_client();
                client.set_fan_levels((uint16) cpu_spin.get_value_as_int(), (uint16) gpu_spin.get_value_as_int());
            } catch (Error error) {
                status_label.label = error.message;
            }
        }

        private void ensure_client () throws Error {
            if (client == null) {
                client = new ControlClient();
            }
        }

        private string format_metric (int value, string suffix) {
            return value >= 0 ? "%d%s".printf(value, suffix) : "unavailable";
        }

    }
}
