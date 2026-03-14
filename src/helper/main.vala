namespace VictusControl {
    public static int main (string[] args) {
        try {
            var loop = new MainLoop();
            var service = new ControlService();
            Bus.own_name(
                BusType.SYSTEM,
                SERVICE_NAME,
                BusNameOwnerFlags.NONE,
                (connection) => {
                    try {
                        service.export(connection);
                    } catch (Error error) {
                        critical("Failed to export D-Bus service: %s", error.message);
                        loop.quit();
                    }
                }
            );
            loop.run();
            return 0;
        } catch (Error error) {
            stderr.printf("victusd: %s\n", error.message);
            return 1;
        }
    }
}
