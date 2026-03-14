namespace VictusControl {
    public class MonitorApp : Gtk.Application {
        private AppConfig config;

        public MonitorApp () {
            Object(
                application_id: APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
            );
            config = AppConfig.load();
        }

        protected override void activate () {
            var window = (MainWindow) active_window;
            if (window == null) {
                window = new MainWindow(this, config);
            }
            window.present();
        }
    }

    public static int main (string[] args) {
        return new MonitorApp().run(args);
    }
}
