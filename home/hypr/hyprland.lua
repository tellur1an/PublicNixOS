-- Hyprland Lua config — loader. Split into sub-modules (old hyprlang layout).
-- Backup: ~/.config/hypr/backup/pre-lua-20260518_122013, hyprland.lua.bak
--
-- Order matters: lib defines shared helpers/state; settings registers the
-- lua:fair layout + core config + layer rules; noctalia LAST (overrides
-- general:col border colors via its own hl.config).
require("lib")
require("env")
require("monitors")
require("settings")
require("autostart")
require("binds")
require("rules")

-- For Noctalia Color templates
require("noctalia")
