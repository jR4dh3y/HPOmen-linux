namespace VictusControl {
    private static string json_to_string (Json.Object object) {
        var root = new Json.Node(Json.NodeType.OBJECT);
        root.set_object(object);
        var generator = new Json.Generator();
        generator.pretty = true;
        generator.set_root(root);
        size_t length;
        return generator.to_data(out length);
    }

    public static int main (string[] args) {
        var command = args.length > 1 ? args[1] : "inventory";
        try {
            Json.Object result;
            switch (command) {
            case "inventory":
                result = ProbeEngine.inventory();
                break;
            case "snapshot":
                result = new HardwareBackend().read_snapshot(false).to_json_object();
                break;
            case "safe-hp-wmi":
                result = ProbeEngine.safe_hp_wmi();
                break;
            case "dangerous-write":
                stderr.printf("dangerous-write is intentionally not implemented until a validated fan write path exists.\n");
                return 2;
            case "help":
            case "--help":
            case "-h":
                stdout.printf("Usage: victus-probe [inventory|snapshot|safe-hp-wmi|dangerous-write]\n");
                return 0;
            default:
                stderr.printf("Unknown command: %s\n", command);
                return 1;
            }

            stdout.printf("%s\n", json_to_string(result));
            return 0;
        } catch (Error error) {
            stderr.printf("victus-probe: %s\n", error.message);
            return 1;
        }
    }
}
