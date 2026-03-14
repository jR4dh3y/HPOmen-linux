namespace VictusControl {
    /**
     * System identity cards: product name, board, BIOS, active
     * hardware profile, and available profiles.
     */
    public class OverviewSection : Gtk.Box {
        private Gtk.Label product_label;
        private Gtk.Label board_label;
        private Gtk.Label bios_label;
        private Gtk.Label profile_label;
        private Gtk.Label choices_label;

        private Gtk.Widget root_widget;

        public OverviewSection () {
            Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            product_label = WidgetHelpers.create_value_label("");
            board_label = WidgetHelpers.create_value_label("");
            bios_label = WidgetHelpers.create_value_label("");
            profile_label = WidgetHelpers.create_value_label("");
            choices_label = WidgetHelpers.create_value_label("");

            var grid = new Gtk.Grid();
            grid.column_spacing = 18;
            grid.row_spacing = 18;
            grid.attach(WidgetHelpers.create_info_card("Product", product_label), 0, 0, 1, 1);
            grid.attach(WidgetHelpers.create_info_card("Board", board_label), 1, 0, 1, 1);
            grid.attach(WidgetHelpers.create_info_card("BIOS", bios_label), 2, 0, 1, 1);
            grid.attach(WidgetHelpers.create_info_card("Active HW profile", profile_label), 0, 1, 1, 1);
            grid.attach(WidgetHelpers.create_info_card("Available HW profiles", choices_label), 1, 1, 2, 1);

            root_widget = WidgetHelpers.wrap_section(
                "System Overview",
                "Identity, firmware, and HP WMI hardware profile state.",
                grid
            );
            append(root_widget);
        }

        public void update (Snapshot snapshot) {
            product_label.label = Formatting.fallback(snapshot.product_name);
            board_label.label = Formatting.fallback(snapshot.board_name);
            bios_label.label = Formatting.fallback(snapshot.bios_version);
            profile_label.label = Formatting.fallback(Formatting.profile(snapshot.active_hardware_profile));
            choices_label.label = Formatting.profiles(snapshot.available_hardware_profiles);
        }

        public void show_offline () {
            product_label.label = "Unavailable";
            board_label.label = "Unavailable";
            bios_label.label = "Unavailable";
            profile_label.label = "Unavailable";
            choices_label.label = "Unavailable";
        }
    }
}
