#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
PATCH_DIR="$ROOT_DIR/patches/hp-wmi-v10"

PATCHES=(
    "$PATCH_DIR/0000-cover-letter.patch"
    "$PATCH_DIR/0001-platform-x86-hp-wmi-Introduce-board-specific-feature.patch"
    "$PATCH_DIR/0002-platform-x86-hp-wmi-Drive-fan-control-from-board-dat.patch"
    "$PATCH_DIR/0003-platform-x86-hp-wmi-Add-Victus-15-fb0xxx-support.patch"
)

usage() {
    printf 'usage: %s [--dry-run|--send]\n' "$0"
}

DRY_RUN=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=1
            ;;
        --send)
            DRY_RUN=0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
    shift
done

for patch in "${PATCHES[@]}"; do
    if [[ ! -f "$patch" ]]; then
        printf 'missing patch: %s\n' "$patch" >&2
        exit 1
    fi
done

args=(
    --no-annotate
    --confirm=never
    --thread
    --no-chain-reply-to
    --from "Radhey Kalra <radheykalra901@gmail.com>"
    --suppress-cc=self
    --to "platform-driver-x86@vger.kernel.org"
    --cc "linux-kernel@vger.kernel.org"
    --cc "hansg@kernel.org"
    --cc "ilpo.jarvinen@linux.intel.com"
    --cc "krishna.chomal108@gmail.com"
)

if [[ $DRY_RUN -eq 1 ]]; then
    args+=(--dry-run)
    printf 'Dry run only. Use `%s --send` to send for real.\n\n' "$0"
fi

git send-email "${args[@]}" "${PATCHES[@]}"
