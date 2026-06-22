#!/usr/bin/env bash
# Per-workspace layout switcher matching MangoWC tagrule layout assignments
#
# MangoWC → Hyprland layout mapping:
#   tile           → master
#   scroller       → scrolling
#   monocle        → monocle   (native since v0.54)
#   right_tile     → master   (orientation:right set via workspace rule)
#   vertical_scroller → scrolling (direction:down set via workspace rule)
#   tgmix          → master   (no direct equivalent)

LOCK_FILE="/tmp/hypr-workspace-layouts.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 0
fi

declare -A LAYOUTS=(
    [1]="master"     # Main      - tile
    [2]="scrolling"  # Comms     - scroller
    [3]="monocle"    # Browser   - monocle (added in v0.54)
    [4]="master"     # Launchers - right_tile (orientation:right set via workspace rule)
    [5]="monocle"    # Games     - monocle (added in v0.54)
    [6]="monocle"    # Media     - monocle
    [7]="master"     # System    - tgmix (no direct equiv)
    [8]="scrolling"  # Mail      - vertical_scroller (direction:down set via workspace rule)
    [9]="master"     # Utils     - tile
)

declare -A SCROLLING_WIDTHS=(
    [2]="0.33"       # Comms: fit three visible columns with a bit more slack
    [8]="0.99"       # Mail: keep near-full-width columns
)

declare -A APPLIED_SCROLLING_WIDTHS=()
LAST_APPLIED_WS=""

set_layout() {
    local ws="$1"
    local layout="${LAYOUTS[$ws]:-master}"

    [[ "$ws" =~ ^[0-9]+$ ]] || return 0
    [[ "$ws" == "$LAST_APPLIED_WS" ]] && return 0

    hyprctl keyword general:layout "$layout"

    if [[ "$layout" == "scrolling" && -n "${SCROLLING_WIDTHS[$ws]}" && -z "${APPLIED_SCROLLING_WIDTHS[$ws]}" ]]; then
        hyprctl keyword scrolling:column_width "${SCROLLING_WIDTHS[$ws]}"
        APPLIED_SCROLLING_WIDTHS["$ws"]=1
    fi

    LAST_APPLIED_WS="$ws"
}

# Set layout for the workspace that's active at startup
initial_ws=$(hyprctl activeworkspace -j | grep '"id"' | head -1 | grep -o '[0-9]*' | head -1)
set_layout "${initial_ws:-1}"

# Listen for workspace change events via the Hyprland IPC socket
socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
while read -r line; do
    case "$line" in
        workspace\>\>*)
            ws="${line#workspace>>}"
            set_layout "$ws"
            ;;
    esac
done
