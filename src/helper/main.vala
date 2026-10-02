namespace VictusControl {
    public static int main (string[] args) {
        var loop = new MainLoop();
        var service = new ControlService();
        if (ProbeEngine.hp_wmi_out_of_tree()) {
            stderr.printf("victusd: hp_wmi is an out-of-tree module and shadows the in-tree driver\n");
        }
        service.restore_profile.begin();
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
            },
            () => {},
            () => {
                stderr.printf("victusd: lost bus name ownership, exiting\n");
                loop.quit();
            }
        );
        loop.run();
        return 0;
    }
}
