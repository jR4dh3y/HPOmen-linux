#!/bin/sh
set -eu

KERNEL_VERSION=${KERNEL_VERSION:-$(uname -r)}
WORK_DIR=${WORK_DIR:-/tmp/hp-wmi-v2-upstream-test}
SOURCE_URL=${SOURCE_URL:-https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/drivers/platform/x86/hp/hp-wmi.c}
PATCH_FILE=${PATCH_FILE:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/patches/0001-v2-platform-x86-hp-wmi-add-victus-15-fb0xxx-fan-control.patch}
MODULE_PATH=${MODULE_PATH:-/lib/modules/$KERNEL_VERSION/updates/dkms/hp-wmi.ko.zst}

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/drivers/platform/x86/hp"

curl -L --fail "$SOURCE_URL" -o "$WORK_DIR/drivers/platform/x86/hp/hp-wmi.c"
patch -d "$WORK_DIR" -p1 < "$PATCH_FILE"
cp "$WORK_DIR/drivers/platform/x86/hp/hp-wmi.c" "$WORK_DIR/hp-wmi.c"

cat > "$WORK_DIR/Makefile" <<'MAKEFILE'
obj-m := hp-wmi.o
MAKEFILE

# Current CachyOS 7.0 headers do not define this newer mainline symbol.
perl -0pi -e 's/(#include <linux\/workqueue\.h>\n)/$1\n#ifndef ACPI_AC_CLASS\n#define ACPI_AC_CLASS "ac_adapter"\n#endif\n/' "$WORK_DIR/hp-wmi.c"

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

echo "Installed v2 test hp-wmi module at $MODULE_PATH"
echo "Reboot, then collect: modinfo -n hp_wmi; ls /sys/devices/platform/hp-wmi/hwmon/hwmon*/; sudo dmesg | grep -i hp_wmi"
