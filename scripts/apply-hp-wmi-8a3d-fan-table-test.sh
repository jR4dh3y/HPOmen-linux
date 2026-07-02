#!/bin/sh
set -eu

KERNEL_VERSION=${KERNEL_VERSION:-$(uname -r)}
WORK_DIR=${WORK_DIR:-/tmp/hp-wmi-8a3d-fan-table-test}
SOURCE_URL=${SOURCE_URL:-https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/platform/x86/hp/hp-wmi.c}
MODULE_PATH=${MODULE_PATH:-/lib/modules/$KERNEL_VERSION/updates/dkms/hp-wmi.ko.zst}

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

curl -L --fail "$SOURCE_URL" -o "$WORK_DIR/hp-wmi.c"
cat > "$WORK_DIR/Makefile" <<'MAKEFILE'
obj-m := hp-wmi.o
MAKEFILE

perl -0pi -e 's/(#include <linux\/workqueue\.h>\n)/$1\n#ifndef ACPI_AC_CLASS\n#define ACPI_AC_CLASS "ac_adapter"\n#endif\n/' "$WORK_DIR/hp-wmi.c"

perl -0pi -e 's/(static const struct dmi_system_id victus_s_thermal_profile_boards\[\] __initconst = \{\n)/$1\t{\n\t\t.matches = { DMI_MATCH(DMI_BOARD_NAME, "8A3D") },\n\t\t.driver_data = (void *)&victus_s_thermal_params,\n\t},\n/' "$WORK_DIR/hp-wmi.c"

perl -0pi -e 's/(ret = hp_wmi_perform_query\(HPWMI_VICTUS_S_GET_FAN_TABLE_QUERY,\n\s+HPWMI_GM, &fan_data, 4, sizeof\(fan_data\)\);\n)\tif \(ret\)\n\t\treturn ret;/$1\tif (ret) {\n\t\tpr_warn("8A3D fan table test: query failed: %d\\n", ret);\n\t\treturn ret;\n\t}\n\n\tpr_info("8A3D fan table test: query succeeded\\n");/' "$WORK_DIR/hp-wmi.c"

perl -0pi -e 's/(\tfan_table = \(struct victus_s_fan_table \*\)fan_data;\n)/$1\tpr_info("8A3D fan table test: header num_fans=%u unknown=%u\\n",\n\t\tfan_table->header.num_fans, fan_table->header.unknown);\n/' "$WORK_DIR/hp-wmi.c"

perl -0pi -e 's/(\t\tnoise_db = fan_table->entries\[i\]\.noise_db;\n)/$1\n\t\tif (i < 16)\n\t\t\tpr_info("8A3D fan table test: entry[%d] cpu=%u gpu=%u noise=%u\\n",\n\t\t\t\ti, cpu_rpm, gpu_rpm, noise_db);\n/' "$WORK_DIR/hp-wmi.c"

perl -0pi -e 's/(\tpriv->gpu_delta = gpu_delta;\n)/$1\n\tpr_info("8A3D fan table test: parsed min=%u00 max=%u00 gpu_delta=%d00\\n",\n\t\tmin_rpm, max_rpm, gpu_delta);\n/' "$WORK_DIR/hp-wmi.c"

make -C "/lib/modules/$KERNEL_VERSION/build" M="$WORK_DIR" LLVM=1 CC=clang

mkdir -p "$(dirname "$MODULE_PATH")"
case "$MODULE_PATH" in
    *.zst)
        zstd -f "$WORK_DIR/hp-wmi.ko" -o "$MODULE_PATH"
        ;;
    *)
        install -m 0644 "$WORK_DIR/hp-wmi.ko" "$MODULE_PATH"
        ;;
esac

depmod "$KERNEL_VERSION"

echo "Installed 8A3D fan-table test hp-wmi module at $MODULE_PATH"
echo "Reboot, then collect: modinfo -n hp_wmi; ls /sys/devices/platform/hp-wmi/hwmon/hwmon*/; sudo dmesg | grep -i 'hp_wmi\\|8A3D fan table'"
