#!/usr/bin/env bash
set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
mkdir -p "$dir"

file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
grim "$file"
notify-send "Saved screen" "$file"
