#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"

if [[ -z "$sig" ]]; then
  sig="$(ls -1t "$runtime_dir/hypr" 2>/dev/null | head -n 1 || true)"
fi

if [[ -n "$sig" ]]; then
  socket="$runtime_dir/hypr/$sig/.socket2.sock"
  # Wait for Hyprland IPC to be ready to avoid missing workspace events.
  for _ in {1..50}; do
    [[ -S "$socket" ]] && break
    sleep 0.1
  done
fi

exec waybar
