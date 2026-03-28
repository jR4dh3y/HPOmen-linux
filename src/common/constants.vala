namespace VictusControl {
    public const string APP_ID = "dev.radhey.VictusControl";
    public const string APP_NAME = "Victus Control";
    public const string SERVICE_NAME = "dev.radhey.VictusControl1";
    public const string OBJECT_PATH = "/dev/radhey/VictusControl1";
    public const string INTERFACE_NAME = "dev.radhey.VictusControl1";
    public const string POLKIT_ACTION_ID = "dev.radhey.VictusControl1.manage";

    public const string HP_WMI_PATH = "/sys/devices/platform/hp-wmi";
    public const string HP_WMI_HWMON_PATH = "/sys/devices/platform/hp-wmi/hwmon";
    public const string HP_WMI_PLATFORM_PROFILE_ROOT_PATH = "/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0";
    public const string HP_WMI_HARDWARE_PROFILE_PATH = "/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0/profile";
    public const string HP_WMI_HARDWARE_PROFILE_CHOICES_PATH = "/sys/devices/platform/hp-wmi/platform-profile/platform-profile-0/choices";
    public const string WMI_DEVICES_PATH = "/sys/bus/wmi/devices";
    public const string DMI_PRODUCT_NAME_PATH = "/sys/class/dmi/id/product_name";
    public const string DMI_BOARD_NAME_PATH = "/sys/class/dmi/id/board_name";
    public const string DMI_BIOS_VERSION_PATH = "/sys/class/dmi/id/bios_version";
    public const string PROBE_STATE_PATH = "/var/lib/victus-control/probe.json";
    public const string USER_CONFIG_RELATIVE_PATH = "victus-control/config.ini";
    public const uint DEFAULT_POLL_INTERVAL_SECONDS = 3;
    public const uint DEFAULT_AUTO_POLICY_INTERVAL_SECONDS = 5;

    /* Auto-policy temperature thresholds (degrees C). */
    public const int AUTO_POLICY_TEMP_HIGH = 78;
    public const int AUTO_POLICY_TEMP_MID = 64;
    public const int AUTO_POLICY_HYSTERESIS = 5;

    /* sysfs fan-mode values written to / read from pwm1_enable. */
    public const string SYSFS_FAN_MODE_AUTO = "2";
    public const string SYSFS_FAN_MODE_MAX = "0";
    public const int SYSFS_FAN_MODE_AUTO_INT = 2;
    public const int SYSFS_FAN_MODE_MAX_INT = 0;

    /* Temperature normalization ceiling (degrees C). */
    public const double TEMP_NORMALIZE_MAX = 100.0;
}
