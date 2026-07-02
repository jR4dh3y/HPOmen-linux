#!/bin/sh
set -eu

DKMS_DIR=${DKMS_DIR:-/usr/src/hp-omen-wmi-dkms-r32.d4b9b5a}
PATCH_FILE=${PATCH_FILE:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/patches/hp-wmi-manual-fan-target.patch}
KERNEL_VERSION=${KERNEL_VERSION:-$(uname -r)}
MODULE_PATH=${MODULE_PATH:-}

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

if [ ! -f "$DKMS_DIR/src/hp-wmi.c" ]; then
    echo "Missing driver source: $DKMS_DIR/src/hp-wmi.c" >&2
    exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
    echo "Missing patch file: $PATCH_FILE" >&2
    exit 1
fi

backup="$DKMS_DIR/src/hp-wmi.c.pre-manual-rpm"
if [ ! -f "$backup" ]; then
    cp "$DKMS_DIR/src/hp-wmi.c" "$backup"
fi

if patch --dry-run --reverse -d "$DKMS_DIR/src" -p0 < "$PATCH_FILE" >/dev/null 2>&1; then
    echo "Patch already applied."
else
    patch --forward -d "$DKMS_DIR/src" -p0 < "$PATCH_FILE"
fi

make -C "$DKMS_DIR/src" clean
make -C "$DKMS_DIR/src" KERNELDIR="/lib/modules/$KERNEL_VERSION/build" LLVM=1 CC=clang

if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH=$(modinfo -n hp_wmi 2>/dev/null || true)
fi
if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH="/lib/modules/$KERNEL_VERSION/updates/dkms/hp-wmi.ko"
fi

mkdir -p "$(dirname -- "$MODULE_PATH")"
case "$MODULE_PATH" in
    *.zst)
        if command -v zstd >/dev/null 2>&1; then
            zstd -f "$DKMS_DIR/src/hp-wmi.ko" -o "$MODULE_PATH"
        else
            install -m 0644 "$DKMS_DIR/src/hp-wmi.ko" "${MODULE_PATH%.zst}"
            mv "$MODULE_PATH" "$MODULE_PATH.pre-manual-rpm" 2>/dev/null || true
        fi
        ;;
    *)
        install -m 0644 "$DKMS_DIR/src/hp-wmi.ko" "$MODULE_PATH"
        ;;
esac

depmod "$KERNEL_VERSION"

echo "Patched hp-wmi for $KERNEL_VERSION."
echo "Reload manually when ready: sudo modprobe -r hp_wmi && sudo modprobe hp_wmi"
