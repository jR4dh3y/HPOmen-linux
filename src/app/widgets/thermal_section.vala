namespace VictusControl {
    /**
     * Live temperature gauges (CPU, GPU, Peak) with progress bars
     * and fan RPM readouts.
     */
    public class ThermalSection : Gtk.Box {
        private Gtk.Label cpu_temp_label;
        private Gtk.Label gpu_temp_label;
        private Gtk.Label max_temp_label;
        private Gtk.ProgressBar cpu_temp_bar;
        private Gtk.ProgressBar gpu_temp_bar;
        private Gtk.ProgressBar max_temp_bar;
        private Gtk.Label fan1_label;
        private Gtk.Label fan2_label;
        private Gtk.Label rpm_summary_label;

        public ThermalSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            cpu_temp_label = WidgetHelpers.create_metric_value_label();
            gpu_temp_label = WidgetHelpers.create_metric_value_label();
            max_temp_label = WidgetHelpers.create_metric_value_label();
            cpu_temp_bar = WidgetHelpers.create_metric_bar();
            gpu_temp_bar = WidgetHelpers.create_metric_bar();
            max_temp_bar = WidgetHelpers.create_metric_bar();
            fan1_label = WidgetHelpers.create_metric_value_label();
            fan2_label = WidgetHelpers.create_metric_value_label();
            rpm_summary_label = WidgetHelpers.create_value_label("");

            var grid = new Gtk.Grid();
            grid.column_spacing = 18;
            grid.row_spacing = 18;
            grid.attach(WidgetHelpers.create_metric_card("CPU", "Processor temperature", cpu_temp_label, cpu_temp_bar), 0, 0, 1, 1);
            grid.attach(WidgetHelpers.create_metric_card("GPU", "Graphics temperature", gpu_temp_label, gpu_temp_bar), 1, 0, 1, 1);
            grid.attach(WidgetHelpers.create_metric_card("Peak", "Highest thermal reading", max_temp_label, max_temp_bar), 2, 0, 1, 1);
            grid.attach(WidgetHelpers.create_simple_card("Fan 1", "Primary fan speed", fan1_label), 0, 1, 1, 1);
            grid.attach(WidgetHelpers.create_simple_card("Fan 2", "Secondary fan speed", fan2_label), 1, 1, 1, 1);
            grid.attach(WidgetHelpers.create_info_card("RPM summary", rpm_summary_label), 2, 1, 1, 1);

            append(WidgetHelpers.wrap_section(
                "Thermal Telemetry",
                "Live temperatures and RPM reporting from hwmon and HP WMI.",
                grid
            ));
        }

        public void update (Snapshot snapshot) {
            update_temp_card(cpu_temp_label, cpu_temp_bar, snapshot.cpu_temp_c);
            update_temp_card(gpu_temp_label, gpu_temp_bar, snapshot.gpu_temp_c);
            update_temp_card(max_temp_label, max_temp_bar, snapshot.max_temp_c);

            fan1_label.label = Formatting.metric(snapshot.fan1_rpm, " RPM");
            fan2_label.label = Formatting.metric(snapshot.fan2_rpm, " RPM");
            rpm_summary_label.label = build_rpm_summary(snapshot);
        }

        public void show_offline () {
            update_temp_card(cpu_temp_label, cpu_temp_bar, -1);
            update_temp_card(gpu_temp_label, gpu_temp_bar, -1);
            update_temp_card(max_temp_label, max_temp_bar, -1);
            fan1_label.label = "Unavailable";
            fan2_label.label = "Unavailable";
            rpm_summary_label.label = "No RPM telemetry";
        }

        /* ---- internals ---- */

        private void update_temp_card (Gtk.Label label, Gtk.ProgressBar bar, int value) {
            label.label = Formatting.metric(value, "\u00b0C");
            bar.fraction = normalize_temperature(value);
        }

        private static double normalize_temperature (int value) {
            if (value < 0) {
                return 0.0;
            }
            var fraction = (double) value / TEMP_NORMALIZE_MAX;
            return fraction > 1.0 ? 1.0 : fraction;
        }

        private static string build_rpm_summary (Snapshot snapshot) {
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
    }
}
