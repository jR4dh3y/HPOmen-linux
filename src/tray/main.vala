namespace VictusControl {
    public class TrayApp : Object {
        private AppIndicator.Indicator indicator;
        private ControlClient? client;
        private Gtk.MenuItem status_item;
        private Gtk.CheckMenuItem auto_item;

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

            status_item = new Gtk.MenuItem.with_label("Connecting…");
            status_item.set_sensitive(false);
            menu.append(status_item);

            menu.append(new Gtk.SeparatorMenuItem());

            menu.append(profile_item("Cool", "cool"));
            menu.append(profile_item("Quiet", "quiet"));
            menu.append(profile_item("Balanced", "balanced"));
            menu.append(profile_item("Performance", "performance"));

            auto_item = new Gtk.CheckMenuItem.with_label("Auto Policy");
            auto_item.activate.connect(() => {
                try_call(() => client.set_auto_policy(auto_item.get_active()));
            });
            menu.append(auto_item);

            menu.append(new Gtk.SeparatorMenuItem());

            var open_item = new Gtk.MenuItem.with_label("Open Monitor");
            open_item.activate.connect(() => {
                try {
                    Process.spawn_command_line_async("victus-control");
                } catch (Error error) {
                    status_item.set_label(error.message);
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

        private void connect_helper () {
            try {
                client = new ControlClient();
            } catch (Error error) {
                client = null;
                status_item.set_label("Helper unavailable");
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
                var summary = build_summary(snapshot);
                status_item.set_label(summary);
                indicator.set_label(summary, summary);
                auto_item.set_active(snapshot.auto_policy_enabled);
            } catch (Error error) {
                status_item.set_label("Helper unavailable");
                indicator.set_label("offline", "offline");
                client = null;
            }
        }

        private string build_summary (Snapshot snapshot) {
            return "%s | %s | %s/%s RPM".printf(
                snapshot.max_temp_c >= 0 ? "%dC".printf(snapshot.max_temp_c) : "Temp n/a",
                Formatting.profile(snapshot.active_hardware_profile),
                snapshot.fan1_rpm >= 0 ? "%d".printf(snapshot.fan1_rpm) : "n/a",
                snapshot.fan2_rpm >= 0 ? "%d".printf(snapshot.fan2_rpm) : "n/a"
            );
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
            } catch (Error error) {
                status_item.set_label(error.message);
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
