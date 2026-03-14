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

            var grid = new Gtk.Grid();
            grid.column_spacing = 12;
            grid.row_spacing = 12;
            
            var cpu_card = WidgetHelpers.create_info_card("CPU", cpu_temp_label);
            cpu_card.hexpand = true;
            grid.attach(cpu_card, 0, 0, 1, 1);
            
            var gpu_card = WidgetHelpers.create_info_card("GPU", gpu_temp_label);
            gpu_card.hexpand = true;
            grid.attach(gpu_card, 1, 0, 1, 1);
            
            var peak_card = WidgetHelpers.create_info_card("Peak", max_temp_label);
            peak_card.hexpand = true;
            grid.attach(peak_card, 2, 0, 1, 1);
            
            var fan1_card = WidgetHelpers.create_info_card("Fan 1", fan1_label);
            fan1_card.hexpand = true;
            grid.attach(fan1_card, 0, 1, 1, 1);
            
            var fan2_card = WidgetHelpers.create_info_card("Fan 2", fan2_label);
            fan2_card.hexpand = true;
            grid.attach(fan2_card, 1, 1, 2, 1);

            append(WidgetHelpers.wrap_section("Telemetry", grid));
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
