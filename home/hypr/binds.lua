-- Keybinds, mouse binds, and submaps.
local lib = require("lib")
local M = lib.M
local bind = lib.bind
local bind_exec = lib.bind_exec
local bind_sh = lib.bind_sh
local notify = lib.notify
local cycle_workspace = lib.cycle_workspace
local schedule_once = lib.schedule_once
local repair_scratchpad = lib.repair_scratchpad
local toggle_scratchpad = lib.toggle_scratchpad
local set_dp2_hdr = lib.set_dp2_hdr
local set_dp2_sdr = lib.set_dp2_sdr
local cycle_layout = lib.cycle_layout
local set_layout = lib.set_layout
local set_gaps = lib.set_gaps
local adjust_gaps = lib.adjust_gaps
local toggle_workspace_allfloat = lib.toggle_workspace_allfloat

bind_sh(M .. " + Escape", "hyprctl reload && notify-send -a hyprland 'Config reloaded'")
bind_exec(M .. " + slash", os.getenv("HOME") .. "/.local/bin/show-binds")

for i = 1, 9 do
  local workspace = tostring(i)
  bind(M .. " + " .. i, hl.dsp.focus({ workspace = workspace }))
  bind(M .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = workspace }))
end

bind(M .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
bind("F16", hl.dsp.focus({ workspace = "previous" }))
bind_exec("F17", os.getenv("HOME") .. "/.local/bin/hypr-focus-cycle")
bind_exec(M .. " + grave", os.getenv("HOME") .. "/.local/bin/hypr-focus-cycle")
bind("F18", cycle_workspace(1))
bind(M .. " + comma", cycle_workspace(-1))
bind(M .. " + period", cycle_workspace(1))
bind("F13", cycle_workspace(-1))
bind("F15", cycle_workspace(1))
bind("XF86Tools", cycle_workspace(-1))
bind("XF86Launch6", cycle_workspace(1))
bind_exec("F14", os.getenv("HOME") .. "/.local/bin/hypr-focus-cycle")
bind_exec("XF86Launch5", os.getenv("HOME") .. "/.local/bin/hypr-focus-cycle")
bind(M .. " + mouse_down", cycle_workspace(1))
bind(M .. " + mouse_up", cycle_workspace(-1))
bind(M .. " + SHIFT + comma", cycle_workspace(-1, true))
bind(M .. " + SHIFT + period", cycle_workspace(1, true))

bind_exec(M .. " + Return", "kitty")
bind_exec(M .. " + d", "noctalia msg panel-toggle launcher")
bind_exec(M .. " + e", os.getenv("HOME") .. "/.local/bin/emacs-focus.sh")
bind_exec(M .. " + Space", "fuzzel")
bind_exec(M .. " + ALT + m", "gnome-calculator")
bind_exec(M .. " + ALT + f", "nemo")
bind_exec(M .. " + ALT + e", "featherpad")
bind_exec(M .. " + ALT + l", os.getenv("HOME") .. "/.local/bin/lock-and-dpms")
bind_exec(M .. " + CTRL + SHIFT + q", "noctalia msg panel-toggle session")

bind(M .. " + Left", hl.dsp.focus({ direction = "left" }))
bind(M .. " + Right", hl.dsp.focus({ direction = "right" }))
bind(M .. " + Up", hl.dsp.focus({ direction = "up" }))
bind(M .. " + Down", hl.dsp.focus({ direction = "down" }))
bind(M .. " + h", hl.dsp.focus({ direction = "left" }))
bind(M .. " + j", hl.dsp.focus({ direction = "down" }))
bind(M .. " + k", hl.dsp.focus({ direction = "up" }))
bind(M .. " + l", hl.dsp.focus({ direction = "right" }))

bind(M .. " + q", hl.dsp.window.close())
bind(M .. " + f", function()
  hl.dispatch(hl.dsp.window.fullscreen({ mode = 0 }))
  notify("Fullscreen toggled")
end)
bind(M .. " + SHIFT + f", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))
bind(M .. " + s", function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  notify("Floating toggled")
end)
bind(M .. " + x", function()
  hl.dispatch(hl.dsp.window.fullscreen({ mode = 1 }))
  notify("Maximize toggled")
end)
bind(M .. " + a", function()
  hl.dispatch(hl.dsp.window.pin())
  notify("Pin toggled")
end)

bind(M .. " + t", hl.dsp.group.toggle())
bind(M .. " + SHIFT + t", hl.dsp.group.lock("toggle"))
bind(M .. " + bracketleft", hl.dsp.group.prev())
bind(M .. " + bracketright", hl.dsp.group.next())
bind(M .. " + SHIFT + bracketleft", hl.dsp.group.move_window("b"))
bind(M .. " + SHIFT + bracketright", hl.dsp.group.move_window("f"))
bind(M .. " + CTRL + g", hl.dsp.window.deny_from_group("toggle"))

-- i3-style manual tiling (dwindle layoutmsg). preserve_split=true (see general
-- config) makes the chosen split orientation persist, so these behave like i3:
-- toggle the orientation of the focused split, and preselect where the next
-- window spawns. No plugin (hy3 disabled, ABI break) and no custom lua layout
-- (layout API exposes no stable window->target identity to build a tree).
bind(M .. " + o", hl.dsp.layout("togglesplit"))                 -- flip split orientation H/V
bind(M .. " + ALT + Left",  hl.dsp.layout("preselect l"))       -- next window left
bind(M .. " + ALT + Right", hl.dsp.layout("preselect r"))       -- next window right
bind(M .. " + ALT + Up",    hl.dsp.layout("preselect u"))       -- next window up
bind(M .. " + ALT + Down",  hl.dsp.layout("preselect d"))       -- next window down

bind(M .. " + z", toggle_scratchpad)
bind(M .. " + SHIFT + z", function()
  hl.exec_cmd("kitty --class scratchterm")
  schedule_once("scratchpad-spawn", 1000, repair_scratchpad)
  notify("Scratchpad spawned")
end)
bind(M .. " + CTRL + z", hl.dsp.window.move({ workspace = "special:scratch" }))
bind_exec(M .. " + ALT + b", "brave-origin")
bind_exec(M .. " + ALT + SHIFT + b", "mullvad-browser")
bind(M .. " + i", hl.dsp.window.move({ workspace = "special:minimized" }))
bind(M .. " + SHIFT + i", hl.dsp.workspace.toggle_special("minimized"))

bind(M .. " + SHIFT + Left", hl.dsp.window.swap({ direction = "left" }))
bind(M .. " + SHIFT + Right", hl.dsp.window.swap({ direction = "right" }))
bind(M .. " + SHIFT + Up", hl.dsp.window.swap({ direction = "up" }))
bind(M .. " + SHIFT + Down", hl.dsp.window.swap({ direction = "down" }))
bind(M .. " + SHIFT + h", hl.dsp.window.swap({ direction = "left" }))
bind(M .. " + SHIFT + l", hl.dsp.window.swap({ direction = "right" }))
bind(M .. " + SHIFT + k", hl.dsp.window.swap({ direction = "up" }))
bind(M .. " + SHIFT + j", hl.dsp.window.swap({ direction = "down" }))

bind(M .. " + F10", set_dp2_hdr)
bind(M .. " + SHIFT + F10", set_dp2_sdr)

bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind(M .. " + CTRL + h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
bind(M .. " + CTRL + l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
bind(M .. " + CTRL + k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
bind(M .. " + CTRL + j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- No "reset" second arg: that makes the submap one-shot (any bind fires →
-- compositor jumps back to the named submap). Persistent until Esc/Return.
hl.define_submap("resize", function()
  bind("h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
  bind("l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
  bind("k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
  bind("j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
  bind("Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
  bind("Right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
  bind("Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
  bind("Down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
  bind("Escape", function()
    hl.dispatch(hl.dsp.submap("reset"))
    notify("Resize mode off")
  end)
  bind("Return", function()
    hl.dispatch(hl.dsp.submap("reset"))
    notify("Resize mode off")
  end)
end)

bind(M .. " + r", function()
  hl.dispatch(hl.dsp.submap("resize"))
  notify("Resize mode: h/j/k/l, arrows, Esc")
end)

bind(M .. " + n", cycle_layout)
bind(M .. " + CTRL + m", function() set_layout("monocle") end)
bind(M .. " + CTRL + r", function() set_layout("master") end)
bind(M .. " + equal", hl.dsp.layout("addmaster"))
bind(M .. " + minus", hl.dsp.layout("removemaster"))
bind(M .. " + CTRL + equal", hl.dsp.layout("colresize +conf"))
bind(M .. " + CTRL + apostrophe", hl.dsp.layout("colresize -conf"))
bind(M .. " + CTRL + minus", hl.dsp.layout("colresize 1.0"))
bind(M .. " + g", hl.dsp.layout("colresize 0.15"))
bind(M .. " + CTRL + period", hl.dsp.layout("cyclenext"))
bind(M .. " + CTRL + comma", hl.dsp.layout("cycleprev"))
bind(M .. " + ALT + t", toggle_workspace_allfloat)
bind(M .. " + ALT + equal", function() adjust_gaps(1) end)
bind(M .. " + ALT + minus", function() adjust_gaps(-1) end)
bind(M .. " + ALT + g", function() set_gaps(0) end)

bind_exec(M .. " + c", "noctalia msg panel-toggle control-center")
bind_exec(M .. " + SHIFT + n", "noctalia msg panel-toggle control-center notifications")
bind_exec(M .. " + SHIFT + c", "noctalia msg notification-clear-active")
bind_sh(M .. " + p", "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy")
bind_exec(M .. " + semicolon", "rofimoji --action copy --selector fuzzel --prompt Emoji")
bind_exec(M .. " + v", "kitty --class wiremix wiremix")

bind_exec("XF86AudioRaiseVolume", "noctalia msg volume-up", { locked = true, repeating = true })
bind_exec("XF86AudioLowerVolume", "noctalia msg volume-down", { locked = true, repeating = true })
bind_exec("XF86AudioMute", "noctalia msg volume-mute", { locked = true })
bind_exec("XF86AudioMicMute", "noctalia msg mic-mute", { locked = true })
bind_exec("XF86AudioPlay", "playerctl play-pause", { locked = true })
bind_exec("XF86AudioStop", "playerctl stop", { locked = true })
bind_exec("XF86AudioPrev", "playerctl previous", { locked = true })
bind_exec("XF86AudioNext", "playerctl next", { locked = true })

bind_sh("Print", "$HOME/.config/hypr/scripts/ss3.sh")
bind_sh("SHIFT + Print", "$HOME/.config/hypr/scripts/ss2.sh")
bind_sh("CTRL + Print", "$HOME/.config/hypr/scripts/ss1.sh")
bind_exec(M .. " + F11", "wlr-randr --output DP-2 --mode 3440x1440@239.983994")
