-- Core config, custom layout registration, and layer rules.
local lib = require("lib")
local colors = lib.colors
local layer = lib.layer

-- Custom "fair" tiled layout (dwl/mango style): balanced near-square grid,
-- equal-width columns, no empty cells. Selectable as "lua:fair".
-- Uses Hyprland 0.55 lua layout API: ctx.area {x,y,w,h}, ctx.targets[],
-- target:place{ x, y, w, h }.
--
-- place{} sets the window's *logicalBox* (the gapless tile); Hyprland derives
-- the visual box by applying general:gaps_in/gaps_out itself. So we place full,
-- edge-to-edge cells with NO gap math. Inserting gaps here would (a) double the
-- gaps and (b) push adjacent logicalBoxes apart, breaking directional focus
-- (getWindowInDirection only treats windows within 2px as adjacent).
hl.layout.register("fair", {
  recalculate = function(ctx)
    local targets = ctx.targets
    local n = #targets
    if n == 0 then
      return
    end

    local area = ctx.area

    -- smallest column count with cols^2 >= n (near square)
    local cols = math.ceil(math.sqrt(n))
    if n == 5 then
      cols = 2 -- dwl parity: 2x3 instead of 3x2
    end

    -- column-major fill; leftmost (n % cols) columns get one extra row
    local base = math.floor(n / cols)
    local extra = n % cols

    local colw = area.w / cols
    local i = 1
    for c = 0, cols - 1 do
      local rows = base + (c < extra and 1 or 0)
      if rows < 1 then
        rows = 1
      end
      local cellh = area.h / rows
      local cx = area.x + c * colw
      for r = 0, rows - 1 do
        if i > n then
          break
        end
        targets[i]:place({
          x = cx,
          y = area.y + r * cellh,
          w = colw,
          h = cellh,
        })
        i = i + 1
      end
    end
  end,
})

hl.config({
  general = {
    layout = "dwindle",
    allow_tearing = true,
    gaps_in = 6,
    gaps_out = 6,
    border_size = 2,
    resize_on_border = true,
    extend_border_grab_area = 20,
    hover_icon_on_border = true,
    col = {
      active_border = { colors = { colors.accent1, colors.accent2 }, angle = 45 },
      inactive_border = colors.inactive_border,
    },
    snap = {
      enabled = true,
      window_gap = 10,
      monitor_gap = 10,
    },
  },

  xwayland = {
    use_nearest_neighbor = false,
    force_zero_scaling = true,
    create_abstract_socket = true,
  },

  input = {
    repeat_rate = 30,
    repeat_delay = 300,
    numlock_by_default = false,
    left_handed = false,
    follow_mouse = 0,
    float_switch_override_focus = 0,
    accel_profile = "flat",
    sensitivity = 0.0,
    touchpad = {
      tap_to_click = true,
      tap_and_drag = true,
      drag_lock = true,
      natural_scroll = false,
      disable_while_typing = true,
      middle_button_emulation = false,
    },
  },

  animations = {
    enabled = false,
  },

  dwindle = {
    preserve_split = true,
    smart_split = false,
    smart_resizing = true,
    force_split = 0,
    split_width_multiplier = 1.0,
    use_active_for_splits = true,
    default_split_ratio = 1.0,
  },

  master = {
    new_status = "master",
    mfact = 0.5,
    slave_count_for_center_master = 0,
  },

  scrolling = {
    column_width = 0.333,
    explicit_column_widths = "0.2, 0.34, 0.46, 0.5, 0.8",
    focus_fit_method = 1,
    follow_focus = true,
    follow_min_visible = 0.4,
    fullscreen_on_one_column = true,
  },

  render = {
    -- scanout OFF deliberately: with bitdepth=10 the scanout path uses the
    -- game's 8-bit buffer, and every noctalia overlay (notification, volume
    -- OSD) forces a scanout exit -> XRGB8888<->XRGB2101010 modeset -> black
    -- flash. Verified live 2026-06-09. Compositing cost @240Hz is <1ms.
    direct_scanout = false,
    cm_enabled = true,
    -- auto-switch DP-2 to HDR while a fullscreen HDR surface is focused,
    -- back to SDR when it closes/unfocuses; replaces old per-game allowlist
    cm_auto_hdr = 1,
    -- smoother VRR frametime pacing (0.55). Experimental: revert if stutter.
    new_render_scheduling = true,
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },

  binds = {
    -- default 300ms gates fast SUPER+scroll / footpedal workspace cycling
    scroll_event_delay = 0,
  },

  opengl = {
    nvidia_anti_flicker = false,
  },

  cursor = {
    no_hardware_cursors = false,
    enable_hyprcursor = true,
    use_cpu_buffer = false,
    sync_gsettings_theme = true,
    inactive_timeout = 3,
    warp_on_change_workspace = true,
    hide_on_key_press = true,
  },

  decoration = {
    rounding = 6,
    dim_inactive = true,
    dim_strength = 0.10,
    dim_special = 0.3,
    dim_around = 0.02,
    active_opacity = 1.0,
    inactive_opacity = 0.90,
    fullscreen_opacity = 1.0,
    blur = {
      enabled = true,
      xray = false,
      size = 5,
      passes = 2,
      new_optimizations = true,
      noise = 0.01,
      contrast = 0.92,
      brightness = 0.92,
      vibrancy = 1.1,
      vibrancy_darkness = 0.25,
    },
    shadow = {
      enabled = true,
      range = 10,
      sharp = false,
      render_power = 4,
      offset = "0 0",
      scale = 1.0,
      color = "rgba(00000060)",
      color_inactive = "rgba(00000060)",
    },
  },

  misc = {
    vrr = 2,
    always_follow_on_dnd = true,
    -- false: noctalia notification popups must not steal keyboard focus from
    -- fullscreen games — focus loss blanks exclusive-fullscreen titles and
    -- makes cm_auto_hdr drop HDR (black-screen modeset flash)
    layers_hog_keyboard_focus = false,
    animate_manual_resizes = false,
    animate_mouse_windowdragging = true,
    enable_swallow = false,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = false,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    middle_click_paste = true,
    allow_session_lock_restore = true,
  },

  debug = {
    overlay = false,
    damage_blink = false,
  },
})

-- Layer rules
layer({ name = "noctalia-bar-blur", match = { namespace = "noctalia-bar-content.*" }, blur = true, ignore_alpha = 0.15, no_anim = true })
layer({ name = "noctalia-notifications-blur", match = { namespace = "noctalia-notifications.*" }, blur = true, ignore_alpha = 0.15 })
layer({ name = "noctalia-background-blur", match = { namespace = "noctalia-background.*" }, blur = true, ignore_alpha = 0.15, no_anim = true })
layer({ name = "selection-no-anim", match = { namespace = "selection" }, no_anim = true })
layer({ name = "wayfreeze-no-anim", match = { namespace = "wayfreeze" }, no_anim = true })
