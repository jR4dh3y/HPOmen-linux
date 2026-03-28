namespace VictusControl {
    /**
     * Loads the application stylesheet.
     */
    public class CssLoader {
        public static void load () {
            var provider = new Gtk.CssProvider();
            
            var local_css_path = "src/app/style.css";

            if (Fs.exists(local_css_path)) {
                provider.load_from_path(local_css_path);
            } else {
                provider.load_from_string(FALLBACK_CSS);
            }

            var display = Gdk.Display.get_default();
            if (display != null) {
                Gtk.StyleContext.add_provider_for_display(
                    display,
                    provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
            }
        }

        private const string FALLBACK_CSS = """
            window {
                background-color: #121211; 
                color: #E2DFD8; 
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Fira Sans", "Droid Sans", "Helvetica Neue", sans-serif;
                -gtk-font-smoothing: antialiased;
            }

            .hero-card, .section-card, .metric-card, .inline-card {
                border-radius: 12px;
                background-color: #1A1918;
                border: 1px solid rgba(255, 255, 255, 0.04);
            }

            .section-card {
                padding: 16px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            }

            .section-card:hover {
                border: 1px solid rgba(255, 255, 255, 0.08);
            }

            .hero-card {
                background: radial-gradient(circle at top right, rgba(212, 163, 115, 0.1), transparent 40%), #161514;
                border: 1px solid rgba(212, 163, 115, 0.1);
                padding: 16px 24px;
            }

            .metric-card {
                padding: 12px 16px;
                background-color: #1C1B1A;
                border: 1px solid rgba(255, 255, 255, 0.03);
                border-radius: 8px;
            }

            .inline-card {
                padding: 12px 16px;
                background-color: #1C1B1A;
                border: 1px solid rgba(255, 255, 255, 0.03);
                border-radius: 8px;
            }

            .hero-title {
                font-family: "New York", "Georgia", "Times New Roman", serif;
                font-size: 28px;
                font-weight: 400;
                letter-spacing: -0.5px;
                color: #F5F2EC;
            }

            .section-title {
                font-size: 16px;
                font-weight: 500;
                letter-spacing: -0.3px;
                color: #F5F2EC;
                margin-bottom: 2px;
            }

            .section-subtitle {
                color: #8C8A86;
                font-size: 12px;
                margin-bottom: 12px;
                font-weight: 400;
            }

            .card-title, .eyebrow {
                font-size: 10px;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 1.5px;
                color: #7B7873;
            }

            .card-subtitle {
                font-family: "JetBrains Mono", "Fira Code", monospace;
                color: #D4A373; 
                font-weight: 500;
                font-size: 10px;
                letter-spacing: 0.2px;
                margin-bottom: 4px;
            }

            .value-label {
                font-size: 12px;
                color: #D2CEC4;
                font-weight: 500;
            }

            .metric-value {
                font-family: "JetBrains Mono", "Fira Code", "Space Mono", monospace;
                font-size: 20px;
                font-weight: 300;
                letter-spacing: -1.0px;
                color: #F5F2EC;
                margin-top: 4px;
            }

            .status-pill {
                background-color: rgba(212, 163, 115, 0.15);
                color: #D4A373;
                padding: 4px 10px;
                border-radius: 99px;
                font-weight: 500;
                font-size: 10px;
                letter-spacing: 0.5px;
                border: 1px solid rgba(212, 163, 115, 0.2);
                margin-bottom: 0px;
            }

            .pill-button {
                min-height: 36px;
                padding: 0 16px;
                border-radius: 8px;
                background-color: #242321;
                color: #E2DFD8;
                border: 1px solid rgba(255, 255, 255, 0.05);
                font-weight: 500;
                font-size: 12px;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
                transition: all 0.2s cubic-bezier(0.2, 0, 0, 1);
            }

            .pill-button:hover {
                background-color: #2D2B29;
                border-color: rgba(255, 255, 255, 0.1);
            }

            .active-pill {
                background-color: #F5F2EC;
                color: #121211;
                border-color: #F5F2EC;
                font-weight: 600;
            }

            .active-pill:hover {
                background-color: #FFFFFF;
                border-color: #FFFFFF;
            }

            switch {
                background-color: #242321;
                border: 1px solid rgba(255, 255, 255, 0.08);
                border-radius: 99px;
            }

            switch slider {
                background-color: #8C8A86;
                border-radius: 50%;
                border: none;
                box-shadow: 0 1px 2px rgba(0,0,0,0.2);
            }

            switch:checked {
                background-color: #D4A373;
                border-color: #D4A373;
            }

            switch:checked slider {
                background-color: #121211;
            }
        """;
    }
}
