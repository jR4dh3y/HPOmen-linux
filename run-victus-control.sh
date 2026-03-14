#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
PREFIX="${PREFIX:-/usr}"
CONTROL_BIN="${PREFIX}/bin/victus-control"
HELPER_BIN="${PREFIX}/bin/victusd"
SERVICE_NAME="io.github.radhey.VictusControl1"
OBJECT_PATH="/io/github/radhey/VictusControl1"
METHOD_NAME="io.github.radhey.VictusControl1.GetSnapshot"

log() {
  printf '[victus-control] %s\n' "$*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

ensure_build() {
  if [[ ! -d "${BUILD_DIR}" ]]; then
    log "Configuring Meson build directory"
    meson setup "${BUILD_DIR}" --prefix "${PREFIX}"
  else
    log "Reconfiguring Meson prefix to ${PREFIX}"
    meson configure "${BUILD_DIR}" --prefix "${PREFIX}"
  fi

  log "Compiling project"
  meson compile -C "${BUILD_DIR}"
}

install_project() {
  log "Installing project files to ${PREFIX}"
  sudo meson install -C "${BUILD_DIR}"
}

reload_system_bus() {
  if command -v systemctl >/dev/null 2>&1; then
    log "Reloading system D-Bus"
    sudo systemctl reload dbus || true
  fi
}

helper_responding() {
  gdbus call --system \
    --dest "${SERVICE_NAME}" \
    --object-path "${OBJECT_PATH}" \
    --method "${METHOD_NAME}" >/dev/null 2>&1
}

start_helper() {
  if pgrep -x victusd >/dev/null 2>&1; then
    log "Stopping existing victusd process"
    sudo pkill -x victusd || true
    sleep 1
  fi

  log "Starting helper"
  sudo "${HELPER_BIN}" >/tmp/victusd.log 2>&1 &

  for _ in {1..10}; do
    if helper_responding; then
      log "Helper is online"
      return
    fi
    sleep 1
  done

  log "Helper did not come online. Recent log output:"
  if [[ -f /tmp/victusd.log ]]; then
    tail -n 40 /tmp/victusd.log
  fi
  exit 1
}

launch_gui() {
  log "Launching GUI"
  exec "${CONTROL_BIN}"
}

main() {
  require_command meson
  require_command sudo
  require_command gdbus

  ensure_build
  install_project
  reload_system_bus
  start_helper
  launch_gui
}

main "$@"
