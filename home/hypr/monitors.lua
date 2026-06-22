-- Monitors and per-workspace rules.
local lib = require("lib")
local workspace_names = lib.workspace_names

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })
hl.monitor({ output = "DP-2", mode = "3440x1440@239.983994", position = "0x0", scale = 1, bitdepth = 10, vrr = 2 })

for i = 1, 9 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", default = i == 1, default_name = workspace_names[i] })
end

hl.workspace_rule({ workspace = "2", monitor = "DP-2", layout = "scrolling", layout_opts = { direction = "right" } })
hl.workspace_rule({ workspace = "5", monitor = "DP-2", layout = "monocle" })
hl.workspace_rule({ workspace = "8", monitor = "DP-2", layout = "monocle" })
