namespace VictusControl {
    public const string APP_ID = "io.github.radhey.VictusControl";
    public const string APP_NAME = "Victus Control";
    public const string SERVICE_NAME = "io.github.radhey.VictusControl1";
    public const string OBJECT_PATH = "/io/github/radhey/VictusControl1";
    public const string INTERFACE_NAME = "io.github.radhey.VictusControl1";
    public const string POLKIT_ACTION_ID = "io.github.radhey.VictusControl1.manage";

    public const string PLATFORM_PROFILE_PATH = "/sys/firmware/acpi/platform_profile";
    public const string PLATFORM_PROFILE_CHOICES_PATH = "/sys/firmware/acpi/platform_profile_choices";
    public const string HP_WMI_PATH = "/sys/devices/platform/hp-wmi";
    public const string HP_WMI_HWMON_PATH = "/sys/devices/platform/hp-wmi/hwmon";
    public const string WMI_DEVICES_PATH = "/sys/bus/wmi/devices";
    public const string DMI_PRODUCT_NAME_PATH = "/sys/class/dmi/id/product_name";
    public const string DMI_BOARD_NAME_PATH = "/sys/class/dmi/id/board_name";
    public const string DMI_BIOS_VERSION_PATH = "/sys/class/dmi/id/bios_version";
    public const string PROBE_STATE_PATH = "/var/lib/victus-control/probe.json";
    public const string USER_CONFIG_RELATIVE_PATH = "victus-control/config.ini";
    public const uint DEFAULT_POLL_INTERVAL_SECONDS = 3;
    public const uint DEFAULT_AUTO_POLICY_INTERVAL_SECONDS = 5;
}
