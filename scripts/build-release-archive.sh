#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-release"
DIST_DIR="${ROOT_DIR}/dist"
VERSION="${1:-}"
ARCHITECTURE="${2:-$(uname -m)}"
ARCHIVE_STEM="victus-control-${VERSION}-${ARCHITECTURE}"
STAGE_DIR="${DIST_DIR}/${ARCHIVE_STEM}"
ARCHIVE_PATH="${DIST_DIR}/${ARCHIVE_STEM}.tar.zst"

if [[ -z "${VERSION}" ]]; then
  printf 'Usage: %s <version> [arch]\n' "${BASH_SOURCE[0]##*/}" >&2
  exit 1
fi

if [[ ! -f "${ROOT_DIR}/LICENSE" ]]; then
  printf 'Missing LICENSE file in %s\n' "${ROOT_DIR}" >&2
  exit 1
fi

rm -rf "${BUILD_DIR}" "${STAGE_DIR}" "${ARCHIVE_PATH}" "${ARCHIVE_PATH}.sha256"
mkdir -p "${DIST_DIR}"

meson setup "${BUILD_DIR}" --prefix /usr --buildtype release
meson compile -C "${BUILD_DIR}"
DESTDIR="${STAGE_DIR}" meson install -C "${BUILD_DIR}" --no-rebuild

install -Dm644 "${ROOT_DIR}/LICENSE" \
  "${STAGE_DIR}/usr/share/licenses/victus-control/LICENSE"

tar --zstd -cf "${ARCHIVE_PATH}" -C "${DIST_DIR}" "${ARCHIVE_STEM}"
sha256sum "${ARCHIVE_PATH}" > "${ARCHIVE_PATH}.sha256"

printf 'Built %s\n' "${ARCHIVE_PATH}"
printf 'Wrote %s.sha256\n' "${ARCHIVE_PATH}"
