namespace VictusControl {
    /**
     * Tray companion. Polls and acts through the same async connection and
     * action queue as the monitor window, so menu clicks never block GTK.
     */
    public class TrayApp : Object {
        private AppIndicator.Indicator indicator;
        private TrayMenu menu = new TrayMenu();
        private HelperConnection connection = new HelperConnection();
        private ActionQueue actions;
        private bool refreshing = false;

        public TrayApp () {
            indicator = new AppIndicator.Indicator(
                "victus-control-tray",
                "utilities-system-monitor-symbolic",
                AppIndicator.IndicatorCategory.HARDWARE
            );
            indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
            indicator.set_title(APP_NAME);
            indicator.set_menu(menu.menu);

            actions = new ActionQueue(connection);
            actions.pending_changed.connect((action, pending) => menu.set_pending(action, pending));
            actions.failed.connect((action, message) => menu.show_message(message));
            actions.drained.connect(() => refresh.begin());
            menu.action_requested.connect((action) => actions.submit(action));
            menu.quit_requested.connect(() => Gtk.main_quit());

            refresh.begin();
            Timeout.add_seconds(TRAY_POLL_INTERVAL_SECONDS, () => {
                refresh.begin();
                return Source.CONTINUE;
            });
        }

        private async void refresh () {
            if (refreshing) {
                return;
            }
            refreshing = true;
            try {
                var snapshot = yield connection.get_snapshot();
                menu.update(snapshot);
                var summary = TrayMenu.summary(snapshot);
                indicator.set_label(summary, summary);
            } catch (Error error) {
                menu.show_message("Helper unavailable");
                indicator.set_label("offline", "offline");
            }
            refreshing = false;
        }
    }

    public static int main (string[] args) {
        Gtk.init(ref args);
        var tray = new TrayApp();
        Gtk.main();
        return 0;
    }
}
