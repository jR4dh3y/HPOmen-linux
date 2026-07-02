namespace VictusControl {
    public class TrayApp : Object {
        private const string ACTIVE_SUFFIX = " •";

        private AppIndicator.Indicator indicator;
        private ControlClient? client;
        private Gtk.MenuItem temp_item;
        private Gtk.MenuItem rpm_item;
        private Gtk.MenuItem low_power_item;
        private Gtk.MenuItem balanced_item;
        private Gtk.MenuItem performance_item;
        private Gtk.MenuItem fan_auto_item;
        private Gtk.MenuItem fan_max_item;

        public TrayApp () {
            indicator = new AppIndicator.Indicator(
                "victus-control-tray",
                "utilities-system-monitor-symbolic",
                AppIndicator.IndicatorCategory.HARDWARE
            );
            indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
            indicator.set_title(APP_NAME);
            indicator.set_menu(build_menu());
            connect_helper();
            refresh();
            Timeout.add_seconds(5, () => {
                refresh();
                return true;
            });
        }

        private Gtk.Menu build_menu () {
            var menu = new Gtk.Menu();

            temp_item = new Gtk.MenuItem.with_label("Temp unavailable");
            temp_item.set_sensitive(false);
            menu.append(temp_item);

            rpm_item = new Gtk.MenuItem.with_label("Fans unavailable");
            rpm_item.set_sensitive(false);
            menu.append(rpm_item);

            menu.append(new Gtk.SeparatorMenuItem());

            low_power_item = profile_item("Low Power", "low-power");
            balanced_item = profile_item("Balanced", "balanced");
            performance_item = profile_item("Performance", "performance");
            menu.append(low_power_item);
            menu.append(balanced_item);
            menu.append(performance_item);

            menu.append(new Gtk.SeparatorMenuItem());

            fan_auto_item = fan_mode_item("Fan Auto", "auto");
            fan_max_item = fan_mode_item("Fan Max", "max");
            menu.append(fan_auto_item);
            menu.append(fan_max_item);

            menu.append(new Gtk.SeparatorMenuItem());

            var open_item = new Gtk.MenuItem.with_label("Open Monitor");
            open_item.activate.connect(() => {
                try {
                    Process.spawn_command_line_async("victus-control");
                } catch (Error error) {
                    temp_item.set_label(error.message);
                }
            });
            menu.append(open_item);

            var quit_item = new Gtk.MenuItem.with_label("Quit");
            quit_item.activate.connect(() => Gtk.main_quit());
            menu.append(quit_item);

            menu.show_all();
            return menu;
        }

        private Gtk.MenuItem profile_item (string label, string profile) {
            var item = new Gtk.MenuItem.with_label(label);
            item.activate.connect(() => try_call(() => client.set_hardware_profile(profile)));
            return item;
        }

        private Gtk.MenuItem fan_mode_item (string label, string mode) {
            var item = new Gtk.MenuItem.with_label(label);
            item.activate.connect(() => try_call(() => client.set_fan_mode(mode)));
            return item;
        }

        private void connect_helper () {
            try {
                client = new ControlClient();
            } catch (Error error) {
                client = null;
                temp_item.set_label("Helper unavailable");
                rpm_item.set_label("Fans unavailable");
            }
        }

        private void refresh () {
            try {
                if (client == null) {
                    connect_helper();
                }
                if (client == null) {
                    return;
                }
                var snapshot = client.get_snapshot();
                update_menu_state(snapshot);
                var summary = build_indicator_summary(snapshot);
                indicator.set_label(summary, summary);
            } catch (Error error) {
                temp_item.set_label("Helper unavailable");
                rpm_item.set_label("Fans unavailable");
                indicator.set_label("offline", "offline");
                client = null;
            }
        }

        private void update_menu_state (Snapshot snapshot) {
            temp_item.set_label(
                snapshot.max_temp_c >= 0 ? "Temp %dC".printf(snapshot.max_temp_c) : "Temp unavailable"
            );
            rpm_item.set_label("Fans %s / %s RPM".printf(
                snapshot.fan1_rpm >= 0 ? "%d".printf(snapshot.fan1_rpm) : "n/a",
                snapshot.fan2_rpm >= 0 ? "%d".printf(snapshot.fan2_rpm) : "n/a"
            ));

            var active_profile = snapshot.active_hardware_profile.down();
            set_current(low_power_item, "Low Power", is_low_power_profile(active_profile));
            set_current(balanced_item, "Balanced", active_profile == "balanced");
            set_current(performance_item, "Performance", active_profile == "performance");

            low_power_item.sensitive = snapshot.can_set_hardware_profile
                && has_low_power_profile(snapshot);
            balanced_item.sensitive = snapshot.can_set_hardware_profile
                && has_hw_profile(snapshot, "balanced");
            performance_item.sensitive = snapshot.can_set_hardware_profile
                && has_hw_profile(snapshot, "performance");

            set_current(fan_auto_item, "Fan Auto", snapshot.active_fan_mode == "auto");
            set_current(fan_max_item, "Fan Max", snapshot.active_fan_mode == "max");
            fan_auto_item.sensitive = snapshot.can_set_fan_mode;
            fan_max_item.sensitive = snapshot.can_set_fan_mode;
        }

        private string build_indicator_summary (Snapshot snapshot) {
            return "%s | %s/%s RPM".printf(
                snapshot.max_temp_c >= 0 ? "%dC".printf(snapshot.max_temp_c) : "Temp n/a",
                snapshot.fan1_rpm >= 0 ? "%d".printf(snapshot.fan1_rpm) : "n/a",
                snapshot.fan2_rpm >= 0 ? "%d".printf(snapshot.fan2_rpm) : "n/a"
            );
        }

        private void set_current (Gtk.MenuItem item, string label, bool active) {
            item.set_label("%s%s".printf(label, active ? ACTIVE_SUFFIX : ""));
        }

        private static bool has_hw_profile (Snapshot snapshot, string name) {
            foreach (var profile in snapshot.available_hardware_profiles) {
                if (profile.down() == name) {
                    return true;
                }
            }
            return false;
        }

        private static bool has_low_power_profile (Snapshot snapshot) {
            foreach (var profile in snapshot.available_hardware_profiles) {
                if (is_low_power_profile(profile.down())) {
                    return true;
                }
            }
            return false;
        }

        private static bool is_low_power_profile (string profile) {
            return profile == "low-power" || profile == "quiet" || profile == "cool";
        }

        private delegate bool BoolCall () throws Error;

        private void try_call (BoolCall call) {
            try {
                if (client == null) {
                    connect_helper();
                }
                if (client != null) {
                    call();
                }
                refresh();
            } catch (Error first_error) {
                client = null;
                try {
                    connect_helper();
                    if (client != null) {
                        call();
                    }
                    refresh();
                } catch (Error retry_error) {
                    temp_item.set_label(retry_error.message);
                }
            }
        }
    }

    public static int main (string[] args) {
        Gtk.init(ref args);
        var tray = new TrayApp();
        Gtk.main();
        return 0;
    }
}
