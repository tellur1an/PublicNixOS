#!/usr/bin/env python3
import json
import os
import re
import shlex
import subprocess
from pathlib import Path

ICON_MAP = {
    # Browsers
    "firefox": "",
    "org.mozilla.firefox": "",
    "chromium": "",
    "google-chrome": "",
    "chrome": "",
    "vivaldi": "󰖟",

    # Terminals
    "foot": "",
    "kitty": "",
    "alacritty": "",
    "wezterm": "",

    # Dev
    "code": "",
    "vscode": "",

    # Chat
    "discord": "",
    "signal": "󰭹",
    "slack": "󰒱",

    # Media
    "spotify": "",
    "vlc": "󰕼",

    # File managers
    "org.gnome.nautilus": "",
    "nautilus": "",
    "dolphin": "",

    # Steam
    "steam": "",
    "steamwebhelper": "",
}

CACHE = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "waybar-active-window.json"

def run(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()

def cmd_exists(name: str) -> bool:
    return subprocess.call(["bash", "-lc", f"command -v {shlex.quote(name)} >/dev/null 2>&1"]) == 0

def normalize_app_id(app_id: str) -> str:
    a = (app_id or "").strip().lower()
    # keep full id too, but provide a simplified key
    # strip common prefixes for lookup convenience
    a_simple = re.sub(r"^(org|com|net)\.", "", a)
    return a, a_simple

def icon_for(app_id: str, title: str) -> str:
    full, simple = normalize_app_id(app_id)

    # Steam games often show as steam_app_XXXX or pressure-vessel titles
    if full.startswith("steam_app_") or "steam" in full:
        return ICON_MAP.get("steam", "")

    # Electron generic app_id: try infer from title
    t = (title or "").lower()
    for key in ("discord", "slack", "spotify", "vivaldi", "firefox", "chromium", "code"):
        if key in full or key in simple or key in t:
            return ICON_MAP.get(key, "")

    return ICON_MAP.get(full) or ICON_MAP.get(simple) or ""

def parse_wlrctl_list_line(line: str):
    # We try to extract: app_id and title from a single line.
    # This is heuristic because formats vary.
    parts = shlex.split(line)
    app_id = ""
    title = ""

    if len(parts) >= 2:
        app_id = parts[1]

        # remove obvious state tokens anywhere after app_id
        rest = [p for p in parts[2:] if p.lower() not in ("focused", "activated", "fullscreen", "maximized", "minimized")]
        title = " ".join(rest).strip()

    return app_id, title

def focused_from_wlrctl():
    # Best case: use find if it exists and supports focused match.
    # If it fails, fall back to list parsing.
    try:
        out = run(["wlrctl", "toplevel", "list"])
    except Exception:
        return "", ""

    lines = [l.strip() for l in out.splitlines() if l.strip()]
    if not lines:
        return "", ""

    # Prefer a line that explicitly marks focus/active
    for l in lines:
        ll = l.lower()
        if "focused" in ll or "activated" in ll:
            return parse_wlrctl_list_line(l)

    # If we couldn't detect focus, DON'T guess line 0.
    # Return empty so we can use cache (prevents wrong titles).
    return "", ""

def hyprland_activewindow():
    data = run(["hyprctl", "activewindow", "-j"])
    w = json.loads(data)
    cls = (w.get("class") or w.get("initialClass") or "").lower()
    title = (w.get("title") or "").strip()
    return cls, title

def read_cache():
    try:
        return json.loads(CACHE.read_text())
    except Exception:
        # Return empty so Waybar can hide the module
        return {"text": "", "tooltip": ""}

def write_cache(payload):
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(payload))
    except Exception:
        pass

def main():
    try:
        if cmd_exists("hyprctl"):
            app_id, title = hyprland_activewindow()
        else:
            app_id, title = focused_from_wlrctl()

        if not app_id and not title:
            cached = read_cache()
            if not cached.get("text"):
                print(json.dumps({"text": "", "tooltip": ""}))
            else:
            	print(json.dumps(cached))
            return

        ic = icon_for(app_id, title)
        max_len = 80
        if title and len(title) > max_len:
            title = title[: max_len - 1] + "…"

        text = f"{ic} {title}" if title else ic
        tip = f"{app_id} — {title}" if title else (app_id or "No active window")
        payload = {"text": text, "tooltip": tip}

        write_cache(payload)
        print(json.dumps(payload))

    except Exception:
        cached = read_cache()
        print(json.dumps(cached))

if __name__ == "__main__":
    main()
