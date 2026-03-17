namespace VictusControl {
    /**
     * Compact live temperature gauges and fan RPM readouts.
     */
    public class ThermalSection : Gtk.Box {
        private Gtk.Label cpu_temp_label;
        private Gtk.Label gpu_temp_label;
        private Gtk.Label max_temp_label;
        private Gtk.Label fan1_label;
        private Gtk.Label fan2_label;

        public ThermalSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            cpu_temp_label = WidgetHelpers.create_metric_value_label();
            gpu_temp_label = WidgetHelpers.create_metric_value_label();
            max_temp_label = WidgetHelpers.create_metric_value_label();
            fan1_label = WidgetHelpers.create_metric_value_label();
            fan2_label = WidgetHelpers.create_metric_value_label();

            /* Top row: 3 equal-width temperature cards */
            var temp_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            temp_row.homogeneous = true;
            var cpu_card = WidgetHelpers.create_info_card("CPU", cpu_temp_label);
            var gpu_card = WidgetHelpers.create_info_card("GPU", gpu_temp_label);
            var peak_card = WidgetHelpers.create_info_card("Peak", max_temp_label);
            temp_row.append(cpu_card);
            temp_row.append(gpu_card);
            temp_row.append(peak_card);

            /* Bottom row: 2 equal-width fan cards */
            var fan_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            fan_row.homogeneous = true;
            var fan1_card = WidgetHelpers.create_info_card("Fan 1", fan1_label);
            var fan2_card = WidgetHelpers.create_info_card("Fan 2", fan2_label);
            fan_row.append(fan1_card);
            fan_row.append(fan2_card);

            var rows = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            rows.append(temp_row);
            rows.append(fan_row);

            append(WidgetHelpers.wrap_section("Telemetry", rows));
        }

        public void update (Snapshot snapshot) {
            update_temp_label(cpu_temp_label, snapshot.cpu_temp_c);
            update_temp_label(gpu_temp_label, snapshot.gpu_temp_c);
            update_temp_label(max_temp_label, snapshot.max_temp_c);

            fan1_label.label = Formatting.metric(snapshot.fan1_rpm, " RPM");
            fan2_label.label = Formatting.metric(snapshot.fan2_rpm, " RPM");
        }

        public void show_offline () {
            update_temp_label(cpu_temp_label, -1);
            update_temp_label(gpu_temp_label, -1);
            update_temp_label(max_temp_label, -1);
            fan1_label.label = "N/A";
            fan2_label.label = "N/A";
        }

        private void update_temp_label (Gtk.Label label, int value) {
            label.label = Formatting.metric(value, "\u00b0C");
        }
    }
}
