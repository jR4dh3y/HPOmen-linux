namespace VictusControl {
    public const string APP_ID = "dev.radhey.VictusControl";
    public const string APP_NAME = "Victus Control";
    public const string SERVICE_NAME = "dev.radhey.VictusControl1";
    public const string OBJECT_PATH = "/dev/radhey/VictusControl1";
    public const string INTERFACE_NAME = "dev.radhey.VictusControl1";
    public const string POLKIT_ACTION_ID = "dev.radhey.VictusControl1.manage";
    public const string STYLE_RESOURCE_PATH = "/dev/radhey/VictusControl/style.css";

    public const string HP_WMI_PATH = "/sys/devices/platform/hp-wmi";
    public const string HP_WMI_HWMON_PATH = "/sys/devices/platform/hp-wmi/hwmon";
    /* Holds platform-profile-N; N comes from a global IDA, so it is discovered, not assumed. */
    public const string HP_WMI_PLATFORM_PROFILE_DIR = "/sys/devices/platform/hp-wmi/platform-profile";
    public const string PLATFORM_PROFILE_DIR_PREFIX = "platform-profile-";
    public const string HP_WMI_GPU_MUX_MODE_PATH = "/sys/devices/platform/hp-wmi/gpu_mux_mode";
    public const string HP_WMI_MODULE_TAINT_PATH = "/sys/module/hp_wmi/taint";
    public const string MODULE_TAINT_OUT_OF_TREE = "O";
    public const string WMI_DEVICES_PATH = "/sys/bus/wmi/devices";
    public const string DMI_PRODUCT_NAME_PATH = "/sys/class/dmi/id/product_name";
    public const string DMI_BOARD_NAME_PATH = "/sys/class/dmi/id/board_name";
    public const string DMI_BIOS_VERSION_PATH = "/sys/class/dmi/id/bios_version";
    public const string PROBE_STATE_PATH = "/var/lib/victus-control/probe.json";
    public const string HELPER_STATE_PATH = "/var/lib/victus-control/state.ini";
    public const string USER_CONFIG_RELATIVE_PATH = "victus-control/config.ini";
    public const uint DEFAULT_POLL_INTERVAL_SECONDS = 3;
    public const uint DEFAULT_AUTO_POLICY_INTERVAL_SECONDS = 5;
    public const uint TRAY_POLL_INTERVAL_SECONDS = 5;
    public const uint ERROR_DISPLAY_SECONDS = 6;

    /* Covers a queued fan write (about 1 s per WMI round trip) behind another one. */
    public const int HELPER_CALL_TIMEOUT_MS = 10000;

    /* Auto-policy temperature thresholds (degrees C). */
    public const int AUTO_POLICY_TEMP_HIGH = 78;
    public const int AUTO_POLICY_TEMP_MID = 64;
    public const int AUTO_POLICY_HYSTERESIS = 5;

    /* sysfs fan-mode values written to / read from pwm1_enable. */
    public const string SYSFS_FAN_MODE_AUTO = "2";
    public const string SYSFS_FAN_MODE_MANUAL = "1";
    public const string SYSFS_FAN_MODE_MAX = "0";
    public const int SYSFS_FAN_MODE_AUTO_INT = 2;
    public const int SYSFS_FAN_MODE_MANUAL_INT = 1;
    public const int SYSFS_FAN_MODE_MAX_INT = 0;

    /* Manual fan levels are RPM on the DKMS fan*_target driver, percent on upstream pwmN. */
    public const string FAN_LEVEL_UNIT_RPM = "rpm";
    public const string FAN_LEVEL_UNIT_PERCENT = "percent";
    public const int FAN_LEVEL_PERCENT_MAX = 100;
    public const int FAN_LEVEL_STEP_RPM = 100;
    public const int FAN_LEVEL_STEP_PERCENT = 5;
    public const uint16 MANUAL_FAN_MIN_RPM = 0;
    public const uint16 MANUAL_FAN_MAX_RPM_FALLBACK = 7000;
    public const int MANUAL_FAN_PWM_MAX = 255;
    /* Firmware drops manual targets after 120 s; upstream PWM keeps them alive in-kernel. */
    public const uint MANUAL_FAN_REAPPLY_SECONDS = 90;

    /* Temperature normalization ceiling (degrees C). */
    public const double TEMP_NORMALIZE_MAX = 100.0;
}
