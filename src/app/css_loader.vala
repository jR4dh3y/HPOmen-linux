namespace VictusControl {
    /**
     * Loads the stylesheet compiled into the binary from src/app/style.css.
     */
    public class CssLoader {
        public static void load () {
            var display = Gdk.Display.get_default();
            if (display == null) {
                return;
            }
            var provider = new Gtk.CssProvider();
            provider.load_from_resource(STYLE_RESOURCE_PATH);
            Gtk.StyleContext.add_provider_for_display(
                display,
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
    }
}
