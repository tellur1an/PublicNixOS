#!/usr/bin/env bash
set -euo pipefail

grim -g "$(slurp)" - | wl-copy
notify-send "Copied selection to clipboard"
