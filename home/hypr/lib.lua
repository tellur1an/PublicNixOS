-- Shared helpers, constants, and stateful functions for the Hyprland lua config.
-- Required by env/monitors/settings/autostart/binds/rules modules. Kept in one
-- file so the closures (gap_size, timers, the dp2 hdr/sdr + scratchpad helpers)
-- stay co-located and share upvalues; require() caches this so all consumers
-- see the same instance.
local lib = {}

local M = "SUPER"

local colors = {
  accent1 = "rgba(D919BBCC)",
  accent2 = "rgba(9D7CD8FF)",
  inactive_border = "rgba(3D3350FF)",
}

local function exec(cmd)
  return hl.dsp.exec_cmd(cmd)
end

local function sh(cmd)
  return exec("sh -c " .. string.format("%q", cmd))
end

local function bind(keys, dispatcher, opts)
  hl.bind(keys, dispatcher, opts)
end

local function bind_exec(keys, cmd, opts)
  bind(keys, exec(cmd), opts)
end

local function bind_sh(keys, cmd, opts)
  bind(keys, sh(cmd), opts)
end

-- Cycle workspaces 1-9 with wraparound, in-process (no hyprctl/jq forks per
-- keypress — matters for the footpedal). move=true carries the focused window.
local function cycle_workspace(delta, move)
  return function()
    local ws = hl.get_active_workspace()
    local cur = (ws and ws.id and ws.id >= 1 and ws.id <= 9) and ws.id or 1
    local next_ws = tostring((cur - 1 + delta + 9) % 9 + 1)
    if move then
      hl.dispatch(hl.dsp.window.move({ workspace = next_ws }))
    end
    hl.dispatch(hl.dsp.focus({ workspace = next_ws }))
  end
end

local function rule(spec)
  hl.window_rule(spec)
end

local function layer(spec)
  hl.layer_rule(spec)
end

local timers = {}

local function notify(text, timeout)
  hl.notification.create({
    text = text,
    timeout = timeout or 1800,
    color = colors.accent1,
  })
end

-- Manual HDR override (SUPER+F10 / SUPER+SHIFT+F10). Day-to-day HDR is
-- automatic via render:cm_auto_hdr: monitor flips to HDR while a fullscreen
-- HDR surface is focused and back to SDR when it goes away. These binds
-- remain for forcing the mode when a game misdetects.
local function set_dp2_hdr()
  hl.monitor({
    output = "DP-2",
    mode = "3440x1440@239.983994",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "hdr",
    vrr = 2,
    sdrbrightness = 1.5,
    sdr_max_luminance = 250,
    min_luminance = 0,
    max_luminance = 1000,
    supports_hdr = 1,
    supports_wide_color = 1,
  })
  notify("DP-2 HDR on")
end

local function set_dp2_sdr()
  hl.monitor({
    output = "DP-2",
    mode = "3440x1440@239.983994",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
    vrr = 2,
    sdrbrightness = 1.0,
    sdr_max_luminance = 80,
    -- keep advertising HDR/WCG capability in SDR mode: games must see an
    -- HDR-capable output to offer HDR, which is what triggers cm_auto_hdr
    supports_hdr = 1,
    supports_wide_color = 1,
  })
  notify("DP-2 HDR off")
end

local function schedule_once(name, timeout, callback)
  if timers[name] then
    timers[name]:set_enabled(false)
  end

  timers[name] = hl.timer(callback, {
    timeout = timeout,
    type = "oneshot",
  })
end

local function find_scratchpad()
  local windows = hl.get_windows({ class = "scratchterm" })
  return windows and windows[1] or nil
end

local function repair_scratchpad()
  local window = find_scratchpad()

  if not window then
    hl.exec_cmd("kitty --class scratchterm")
    return
  end

  if not window.workspace or window.workspace.name ~= "special:scratch" then
    hl.dispatch(hl.dsp.focus({ window = window }))
    hl.dispatch(hl.dsp.window.move({ workspace = "special:scratch" }))
    notify("Scratchpad repaired")
  end
end

local function refresh_chat_emacs_column()
  local cmd = [[
active=$(hyprctl activewindow -j | jq -r '.address // empty')
emacs=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id == 2 and .class == "emacs") | .address' | head -n 1)
if [ -n "$emacs" ]; then
  hyprctl dispatch focuswindow "address:$emacs" >/dev/null
  hyprctl dispatch layoutmsg "colresize 0.46" >/dev/null
  emacsclient --eval '(progn (redraw-frame) (force-window-update) (redisplay t) t)' >/dev/null 2>&1 || true
  if [ -n "$active" ] && [ "$active" != "$emacs" ]; then
    hyprctl dispatch focuswindow "address:$active" >/dev/null
  fi
fi
]]

  hl.exec_cmd("sh -c " .. string.format("%q", cmd))
end

local function toggle_scratchpad()
  repair_scratchpad()
  hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))
end

local function settle_startup()
  set_dp2_sdr()
  repair_scratchpad()
  refresh_chat_emacs_column()
  -- workspace-layouts.sh disabled: uses `hyprctl keyword` which is a no-op under
  -- the lua parser. Per-workspace layouts now set via hl.workspace_rule below;
  -- global default = lua:fair.
  notify("Startup layout settled")
end

local gap_size = 6

local function set_layout(name)
  hl.config({ general = { layout = name } })
  notify("Layout: " .. name)
end

-- Full breadth of native layouts, rotated by a single key (SUPER + n)
local layout_cycle = { "master", "dwindle", "scrolling", "monocle", "lua:fair" }

local function cycle_layout()
  local current = hl.get_config("general:layout")
  local idx = 0
  for i, name in ipairs(layout_cycle) do
    if name == current then
      idx = i
      break
    end
  end
  set_layout(layout_cycle[(idx % #layout_cycle) + 1])
end

local function set_gaps(size)
  gap_size = math.max(0, size)
  hl.config({ general = { gaps_in = gap_size, gaps_out = gap_size } })
  notify("Gaps: " .. gap_size)
end

local function adjust_gaps(delta)
  set_gaps(gap_size + delta)
end

local function toggle_workspace_allfloat()
  hl.dispatch(hl.dsp.exec_raw("workspaceopt allfloat"))
  notify("Workspace all-float toggled")
end

local workspace_names = { "Code", "Chat", "Web", "Steam", "Game", "Media", "Util", "Mail", "9" }

lib.M = M
lib.colors = colors
lib.workspace_names = workspace_names
lib.exec = exec
lib.sh = sh
lib.bind = bind
lib.bind_exec = bind_exec
lib.bind_sh = bind_sh
lib.cycle_workspace = cycle_workspace
lib.rule = rule
lib.layer = layer
lib.notify = notify
lib.set_dp2_hdr = set_dp2_hdr
lib.set_dp2_sdr = set_dp2_sdr
lib.schedule_once = schedule_once
lib.find_scratchpad = find_scratchpad
lib.repair_scratchpad = repair_scratchpad
lib.refresh_chat_emacs_column = refresh_chat_emacs_column
lib.toggle_scratchpad = toggle_scratchpad
lib.settle_startup = settle_startup
lib.set_layout = set_layout
lib.cycle_layout = cycle_layout
lib.set_gaps = set_gaps
lib.adjust_gaps = adjust_gaps
lib.toggle_workspace_allfloat = toggle_workspace_allfloat

return lib
