#!/usr/bin/env bash
set -euo pipefail

wayfreeze &
pid=$!
sleep 0.1

grim -g "$(slurp)" - | wl-copy

kill "$pid" 2>/dev/null || true
notify-send "Copied frozen selection to clipboard"
