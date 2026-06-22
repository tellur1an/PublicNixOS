-- Autostart and lifecycle event handlers.
local lib = require("lib")
local schedule_once = lib.schedule_once
local settle_startup = lib.settle_startup
local repair_scratchpad = lib.repair_scratchpad
local refresh_chat_emacs_column = lib.refresh_chat_emacs_column
local workspace_names = lib.workspace_names

hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY PATH XDG_SESSION_ID XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY PATH XDG_SESSION_ID XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE")
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 28")
  hl.exec_cmd("noctalia")
  hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland && systemctl --user restart xdg-desktop-portal")
  -- corectrl removed: replaced by lactd systemd daemon (GPU settings applied at boot, all WMs)
  -- All app-level autostart shared with MangoWC (single source, no drift)
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/wm-session-autostart")
  for i, name in ipairs(workspace_names) do
    if i <= 8 then
      hl.dispatch(hl.dsp.workspace.rename({ workspace = i, name = name }))
    end
  end
  schedule_once("startup-settle", 8000, settle_startup)
end)

hl.on("config.reloaded", function()
  schedule_once("reload-settle", 1200, function()
    repair_scratchpad()
    refresh_chat_emacs_column()
  end)
end)

hl.on("window.open", function()
  schedule_once("window-open-settle", 1000, repair_scratchpad)
end)
