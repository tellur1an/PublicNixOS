{ config, pkgs, lib, inputs, hyprland, hyprland-contrib, hyprland-plugins, mango-flake, ... }:

{
  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "25.11";

  # ============================================================
  # Personal scripts (vpn-pick + family, yt-x / yt-xr, rumble-x) are kept
  # MUTABLE in ~/.local/bin (restored via the Dots repo), NOT baked into the
  # nix store -- they're iterated on often and yt-x self-updates from upstream.
  # Nix's job is only to (1) keep ~/.local/bin on PATH and (2) provide every
  # runtime dep. All deps are already in system/default.nix:
  #   vpn-pick family : nmcli (NetworkManager), fuzzel, libnotify,
  #                     wireguard-tools, coreutils/gawk/gnugrep (base)
  #   yt-x / yt-xr    : yt-dlp, mpv, fzf, chafa, ueberzugpp, curl
  #   rumble-x        : python3 (pure-stdlib script) + yt-dlp + mpv
  #                     (curl_cffi<0.15 is yt-dlp's own pipx venv, not nix)
  # ~/.zshrc already prepends ~/.local/bin; this covers graphical/login PATH.
  # ============================================================
  home.sessionPath = [ "$HOME/.local/bin" ];

  # ============================================================
  # Hyprland (PRIMARY WM) native lua config, copied from the Fedora box.
  # recursive=true symlinks each file individually, so any non-managed
  # files you later drop into ~/.config/hypr still work alongside these.
  # System-path fixes already applied in tree:
  #   /usr/bin/wiremix             -> wiremix (PATH)
  # NOTE: binds.lua still hardcodes ~/.local/bin/rofimoji; rofimoji is also
  # installed via nixpkgs (in PATH) -- symlink or edit if that path is empty.
  # ============================================================
  xdg.configFile."hypr" = {
    source = ./hypr;
    recursive = true;
  };

  # ============================================================
  # MangoWC Configuration
  # Using wayland.windowManager.mango from the imported hmModule
  # ============================================================
  
  wayland.windowManager.mango = {
    enable = true;
    
    # Main configuration settings
    settings = ''
      source=~/.config/mango/env.conf
      source=~/.config/mango/rules.conf
      source=~/.config/mango/autostart.conf

      # --- Core / misc ---
      xwayland_persistence=1
      syncobj_enable=0

      # Keep tearing OFF globally, enable per-game
      allow_tearing=0

      # IMPORTANT: prevent Steam/games from inhibiting shortcuts/focus and breaking input
      allow_shortcuts_inhibit=0

      # River-like focus behavior
      focus_on_activate=0

      axis_bind_apply_timeout=100

      focus_cross_monitor=0
      exchange_cross_monitor=1
      focus_cross_tag=0
      view_current_to_back=1

      circle_layout=tile,scroller

      enable_floating_snap=1
      snap_distance=50

      # Auto-hide cursor after 3 seconds (cleaner for gaming/videos)
      cursor_hide_timeout=3000

      drag_tile_to_tile=1
      single_scratchpad=1

      warpcursor=1
      left_handed=0
      sloppyfocus=0

      mouse_natural_scrolling=0

      tap_to_click=1
      tap_and_drag=1
      disable_trackpad=0
      drag_lock=1
      trackpad_natural_scrolling=0
      disable_while_typing=1
      middle_button_emulation=0
      swipe_min_threshold=1

      # XKB
      xkb_rules_rules=evdev
      xkb_rules_layout=us

      repeat_rate=30
      repeat_delay=300
      numlockon=0

      new_is_master=1

      # Enable smart gaps (auto-remove when single window)
      smartgaps=1

      default_mfact=0.5
      default_nmaster=1
      center_master_overspread=1
      center_when_single_stack=1

      scroller_structs=20
      scroller_default_proportion=0.99
      scroller_focus_center=0
      scroller_prefer_center=0
      edge_scroller_pointer_focus=1
      scroller_default_proportion_single=1.0
      scroller_proportion_preset=0.5,0.8,1.0

      hotarea_size=7
      enable_hotarea=1
      ov_tab_mode=0
      overviewgappi=3
      overviewgappo=24

      source=~/.config/mango/appearance.conf
      source=~/.config/mango/binds.conf
    '';
    
    # NOTE: autostart is handled via home.file ".config/mango/autostart.conf"
    # which is sourced by the settings block above
  };

  # ============================================================
  # Additional MangoWC Config Files (via home.file)
  # ============================================================
  
  home.file.".config/mango/env.conf".text = ''
    # Env setting format is: env=NAME,VALUE (no spaces).
    env=MOZ_ENABLE_WAYLAND,1
    env=MOZ_DBUS_REMOTE,1
    env=XDG_SESSION_TYPE,wayland
    env=XDG_CURRENT_DESKTOP,wlroots
    env=XDG_SESSION_DESKTOP,wlroots
    env=EGL_PLATFORM,wayland
    env=CLUTTER_BACKEND,wayland
    env=TERM,foot
    env=TERMINAL,foot
    env=ELECTRON_OZONE_PLATFORM_HINT,auto

    # Cursor (these are Mango options, keep them here or in config.conf)
    cursor_theme=Bibata-Modern-Ice
    cursor_size=28
    env=XCURSOR_SIZE,28
    env=XCURSOR_THEME,Bibata-Modern-Ice

    env=QT_QPA_PLATFORMTHEME,qt6ct
    env=QT_STYLE_OVERRIDE,Fusion
    env=QT_FONT_DPI,96
    env=QT5_QPA_PLATFORMTHEME,qt5ct
    env=QT_AUTO_SCREEN_SCALE_FACTOR,1
    env=QT_QPA_PLATFORM,Wayland;xcb
    env=QT_WAYLAND_FORCE_DPI,physical

    env=GDK_BACKEND,wayland,x11,*
  '';

  home.file.".config/mango/appearance.conf".text = ''
    # Window effects
    blur=1
    blur_layer=1
    blur_optimized=1
    blur_params_num_passes=4
    blur_params_radius=5
    blur_params_noise=0.01
    blur_params_brightness=0.92
    blur_params_contrast=0.92
    blur_params_saturation=1.1

    shadows=1
    shadow_only_floating=1
    layer_shadows=0
    shadows_size=6
    shadows_blur=10
    shadows_position_x=0
    shadows_position_y=0
    shadowscolor=0x00000060

    border_radius=0
    no_radius_when_single=0
    focused_opacity=1.0

    # Dim unfocused windows for better focus clarity on ultrawide OLED
    unfocused_opacity=0.90

    # Appearance settings
    gappih=0
    gappiv=0
    gappoh=0
    gappov=0

    borderpx=2
    rootcolor=0x12111AFF
    bordercolor=0x2A2734FF
    focuscolor=0xD919BBCC
    urgentcolor=0xF7768EFF
    scratchpadcolor=0x9D7CD8FF
    overlaycolor=0x2AC3DE66
    globalcolor=0x2AC3DE33
    maximizescreencolor=0xD919BB33
  '';

  home.file.".config/mango/binds.conf".text = ''
    # ============================================================
    # Optimized MangoWC Keybinds - Ultrawide 1440p Focused
    # Pattern: SUPER for primary actions, SUPER+SHIFT for destructive/move
    # ============================================================

    # ===== SYSTEM =====
    bind=SUPER,Escape,reload_config
    bind=SUPER+SHIFT,Escape,spawn,notify-send -a mangowc "Config reloaded"

    # ===== TAGS: View (SUPER+[1-9]) =====
    bind=SUPER,1,view,1,0
    bind=SUPER,2,view,2,0
    bind=SUPER,3,view,3,0
    bind=SUPER,4,view,4,0
    bind=SUPER,5,view,5,0
    bind=SUPER,6,view,6,0
    bind=SUPER,7,view,7,0
    bind=SUPER,8,view,8,0
    bind=SUPER,9,view,9,0

    # Tag navigation
    bind=SUPER,Tab,view,-1,0
    bind=SUPER,comma,viewtoleft,0
    bind=SUPER,period,viewtoright,0

    # Scroll wheel tag view
    axisbind=SUPER,Down,viewtoright,0
    axisbind=SUPER,Up,viewtoleft,0

    # ===== TAGS: Move Window (SUPER+SHIFT+[1-9]) =====
    bind=SUPER+SHIFT,1,tag,1,0
    bind=SUPER+SHIFT,2,tag,2,0
    bind=SUPER+SHIFT,3,tag,3,0
    bind=SUPER+SHIFT,4,tag,4,0
    bind=SUPER+SHIFT,5,tag,5,0
    bind=SUPER+SHIFT,6,tag,6,0
    bind=SUPER+SHIFT,7,tag,7,0
    bind=SUPER+SHIFT,8,tag,8,0
    bind=SUPER+SHIFT,9,tag,9,0

    # Move to adjacent tags
    bind=SUPER+SHIFT,comma,tagtoleft,0
    bind=SUPER+SHIFT,period,tagtoright,0

    # ===== APPLICATIONS (muscle memory preserved) =====
    bind=SUPER,Return,spawn,foot
    bind=SUPER,d,spawn,fuzzel
    bind=SUPER,e,spawn,emacsclient -c -n
    bind=SUPER,Space,spawn,fuzzel
    bind=SUPER+SHIFT,b,spawn,mullvad-browser
    bind=SUPER+SHIFT,f,spawn,nemo
    bind=SUPER+SHIFT,e,spawn,featherpad
    bind=SUPER+SHIFT,v,spawn,pwvucontrol
    bind=SUPER,m,spawn,gnome-calculator

    # Power/lock/logout
    bind=SUPER+SHIFT,l,spawn,~/.local/bin/lock-and-dpms
    bind=SUPER+SHIFT,q,spawn_shell,sh -lc 'pkill -x wlogout 2>/dev/null || true; wlogout --protocol layer-shell --buttons-per-row 2 --column-spacing 24 --row-spacing 24 --margin 320'

    # ===== FOCUS (Arrow keys & vim-style) =====
    bind=SUPER,Left,focusdir,left
    bind=SUPER,Right,focusdir,right
    bind=SUPER,Up,focusdir,up
    bind=SUPER,Down,focusdir,down

    # Vim-style focus (h/j/k/l)
    bind=SUPER,h,focusdir,left
    bind=SUPER,j,focusdir,down
    bind=SUPER,k,focusdir,up
    bind=SUPER,l,focusdir,right

    # ===== WINDOW MANAGEMENT =====
    # Close/kill window
    bind=SUPER,q,killclient

    # Window states
    bind=SUPER,f,togglefullscreen
    bind=SUPER,s,togglefloating
    bind=SUPER,x,togglemaximizescreen
    bind=SUPER,a,toggleglobal

    # "Scratchpad" using tag 9 (guaranteed to work)
    bind=SUPER,z,toggleview,9
    bind=SUPER+SHIFT,z,spawn,foot
    bind=SUPER+CTRL,z,tag,9,0

    # Overlay mode
    bind=SUPER,o,toggleoverlay

    # Minimize / restore
    bind=SUPER,i,minimized
    bind=SUPER+SHIFT,i,restore_minimized

    # Move windows in layout (SUPER+SHIFT+arrows)
    bind=SUPER+SHIFT,Left,exchange_client,left
    bind=SUPER+SHIFT,Right,exchange_client,right
    bind=SUPER+SHIFT,Up,exchange_client,up
    bind=SUPER+SHIFT,Down,exchange_client,down

    # Alternative vim-style movement (SUPER+ALT to avoid lock screen conflict)
    bind=SUPER+ALT,h,exchange_client,left
    bind=SUPER+ALT,l,exchange_client,right
    bind=SUPER+ALT,k,exchange_client,up
    bind=SUPER+ALT,j,exchange_client,down

    # ===== MOUSE =====
    mousebind=SUPER,btn_left,moveresize,curmove
    mousebind=SUPER,btn_right,moveresize,curresize

    # ===== LAYOUT CONTROL =====
    # Master/stack controls (for ultrawide use)
    bind=SUPER,equal,incnmaster,1
    bind=SUPER,minus,incnmaster,-1
    bind=SUPER+CTRL,h,setmfact,-0.05
    bind=SUPER+CTRL,l,setmfact,+0.05
    bind=SUPER,n,switch_layout

    # Scroller controls
    bind=ALT,equal,switch_proportion_preset
    bind=ALT,minus,set_proportion,1.0

    # Gaps (SUPER+ALT)
    bind=SUPER+ALT,equal,incgaps,1
    bind=SUPER+ALT,minus,incgaps,-1
    bind=SUPER+ALT,g,togglegaps

    # ===== ADVANCED TAG OPERATIONS =====
    # Toggle view (show multiple tags at once)
    bind=SUPER+CTRL,1,toggleview,1
    bind=SUPER+CTRL,2,toggleview,2
    bind=SUPER+CTRL,3,toggleview,3
    bind=SUPER+CTRL,4,toggleview,4
    bind=SUPER+CTRL,5,toggleview,5
    bind=SUPER+CTRL,6,toggleview,6
    bind=SUPER+CTRL,7,toggleview,7
    bind=SUPER+CTRL,8,toggleview,8
    bind=SUPER+CTRL,9,toggleview,9

    # ===== NOTIFICATIONS & UTILITIES =====
    bind=SUPER,c,spawn,swaync-client -t
    bind=SUPER+SHIFT,c,spawn,swaync-client -C
    bind=SUPER,p,spawn_shell,cliphist list | rofi -dmenu -i | cliphist decode | wl-copy
    bind=SUPER,semicolon,spawn,rofimoji --action copy --selector wofi --prompt Emoji
    bind=SUPER,v,spawn,pwvucontrol

    # ===== MEDIA KEYS (locked - work even when locked) =====
    bindl=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    bindl=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindl=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindl=NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

    bindl=NONE,XF86AudioPlay,spawn,playerctl play-pause
    bindl=NONE,XF86AudioStop,spawn,playerctl stop
    bindl=NONE,XF86AudioPrev,spawn,playerctl previous
    bindl=NONE,XF86AudioNext,spawn,playerctl next

    # ===== SCREENSHOTS =====
    bind=NONE,Print,spawn_shell,bash -lc "$HOME/.config/mango/keybindscripts/ss3.sh"
    bind=SHIFT,Print,spawn_shell,bash -lc "$HOME/.config/mango/keybindscripts/ss2.sh"
    bind=CTRL,Print,spawn_shell,bash -lc "$HOME/.config/mango/keybindscripts/ss1.sh"

    # ===== DISPLAY FIX =====
    bind=SUPER,F11,spawn,wlr-randr --output DP-2 --mode 3440x1440@239.983994
  '';

  home.file.".config/mango/rules.conf".text = ''
    # ------------------------------------------------------------
    # Tag visibility (river-style: always exist)
    # ------------------------------------------------------------
    tagrule=id:1,no_hide:1   # main
    tagrule=id:2,no_hide:1   # chat
    tagrule=id:3,no_hide:1   # dev
    tagrule=id:4,no_hide:1   # web
    tagrule=id:5,no_hide:1   # misc / Steam
    tagrule=id:6,no_hide:1   # media
    tagrule=id:7,no_hide:1   # mail
    tagrule=id:8,no_hide:1   # scratchpad
    tagrule=id:9,no_hide:1   # gaming context

    # ------------------------------------------------------------
    # Common apps: force tiling (river: no-float)
    # ------------------------------------------------------------
    windowrule=isfloating:0,appid:^(signal|Signal)$
    windowrule=isfloating:0,appid:^(legcord|Legcord)$
    windowrule=isfloating:0,appid:^(electron-mail)$

    # Quickshell bar: never grab keyboard
    windowrule=keyboard-interactive:0,title:^Quickshell Bar$
    windowrule=focusable:0,title:^Quickshell Bar$

    # ------------------------------------------------------------
    # Steam (client) -> tag5 + tiled
    # ------------------------------------------------------------
    windowrule=tags:5,appid:^(steam)$
    windowrule=isfloating:0,appid:^(steam)$

    windowrule=allow_shortcuts_inhibit:0,appid:^(steam)$
    windowrule=allow_shortcuts_inhibit:0,appid:^(steam_app_.*|gamescope|wine|wine-preloader|steam_proton|proton)$

    # pwvucontrol
    windowrule=isfloating:1,appid:^com\.saivert\.pwvucontrol$
    # Gearlever
    windowrule=isfloating:1,appid:it.mijorus.gearlever
    # Blueman
    windowrule=isfloating:1,noopenmaximized:1,width:900,height:650,appid:^blueman-manager$
    # File Roller
    windowrule=isfloating:1,noopenmaximized:1,width:900,height:650,appid:^org\.gnome\.FileRoller$
    # Ark
    windowrule=isfloating:1,noopenmaximized:1,width:900,height:650,appid:^org\.kde\.ark$
    # BleachBit
    windowrule=isfloating:1,noopenmaximized:1,width:900,height:650,appid:^org\.bleachbit\.BleachBit$
    # COSMIC Media Player
    windowrule=isfloating:1,noopenmaximized:1,width:1000,height:700,appid:^com\.system76\.CosmicPlayer$
    # VLC
    windowrule=isfloating:1,noopenmaximized:1,width:1000,height:700,appid:^vlc$
    # mpv
    windowrule=isfloating:1,noopenmaximized:1,width:1000,height:700,appid:^mpv$
    # Proton Plus
    windowrule=isfloating:1,appid:^com.vysp3r.ProtonPlus
    # gnome-calculator
    windowrule=isfloating:1,appid:^(org.gnome.Calculator)$
    # jome-emoji-picker
    windowrule=isfloating:1,appid:^(jome)$
    # mpv/kew
    windowrule=isfloating:1,noopenmaximized:1,width:1000,height:700,appid:^kew$

    # Jiffy in kitty — float + pixel-match fuzzel size
    windowrule=isfloating:1,width:800,height:800,isnoborder:1,title:^applicationMenu$
    windowrule=isfloating:1,width:800,height:800,isnoborder:1,title:^emojiMenu$
    windowrule=isfloating:1,width:800,height:800,isnoborder:1,title:^powerMenu$

    # Chat (tag2)
    windowrule=tags:2,appid:^(legcord)$
    windowrule=tags:2,appid:^(signal)$
    windowrule=tags:2,appid:^(discord)$
    windowrule=tags:2,appid:^(chat-simplex-desktop-MainKt)$

    # SimpleX – force floating and cap height
    windowrule=tags:2,appid:^(chat-simplex-desktop-MainKt)$
    windowrule=isfloating:o,appid:^(chat-simplex-desktop-MainKt)$

    # Media (tag3)
    windowrule=tags:3,appid:^(cef)$
    windowrule=tags:3,appid:^(cef)$,title:^(Grayjay)$
    windowrule=tags:3,appid:^(vlc)$
    windowrule=tags:3,appid:^(mpv)$

    # Web (tag4)
    windowrule=tags:4,appid:^(vivaldi|vivaldi-stable)$
    windowrule=tags:4,appid:^(brave|brave-browser)$

    # Steam client (tag5)
    windowrule=tags:5,appid:^(steam)$

    # Dev (tag6)
    windowrule=tags:6,appid:^(streamcontroller)$
    windowrule=isfloating:1,appid:^(streamcontroller|StreamController)$
    windowrule=nofocus:1,appid:^com\.core447\.StreamController$
    windowrule=tags:6,appid:^(openrgb)$
    windowrule=isfloating:1,appid:^(openrgb|OpenRGB)$
    windowrule=tags:6,appid:^(com\.core447\.StreamController)$
    windowrule=isfloating:1,appid:^(com\.core447\.StreamController)$
    windowrule=tags:6,appid:^(org\.openrgb\.OpenRGB)$
    windowrule=isfloating:1,appid:^(org\.openrgb\.OpenRGB)$
    windowrule=tags:6,appid:^(Mullvad[[:space:]]VPN)$
    windowrule=isfloating:1,appid:^(Mullvad[[:space:]]VPN)$

    # Mail (tag7)
    windowrule=tags:7,appid:^(electron-mail)$
    windowrule=tags:7,appid:^(tutanota-desktop)$
    windowrule=tags:7,appid:^(thunderbird)$
    windowrule=tags:7,appid:^(ch\.proton\.bridge-gui)$

    # Gaming context (tag9)
    windowrule=tags:9,appid:^(steam_app_.*)$
    windowrule=tags:9,appid:^(gamescope)$
    windowrule=tags:9,appid:^(wine|wine-preloader|steam_proton|proton)$

    windowrule=allow_shortcuts_inhibit:0,appid:^(steam)$
    windowrule=allow_shortcuts_inhibit:0,appid:^(steam_app_.*|gamescope|wine|wine-preloader|steam_proton|proton)$

    windowrule=isfloating:0,appid:^(signal|legcord|electron-mail|steam|grayjay|Grayjay|app\.grayjay\.Grayjay)$

    # ----------------------------
    # Per-tag layouts
    # ----------------------------
    tagrule=id:1,layout_name:tile
    tagrule=id:2,layout_name:scroller
    tagrule=id:3,layout_name:monocle
    tagrule=id:4,layout_name:right_tile
    tagrule=id:5,layout_name:tgmix
    tagrule=id:6,layout_name:tile
    tagrule=id:7,layout_name:vertical_scroller
    tagrule=id:8,layout_name:tgmix
    tagrule=id:9,layout_name:monocle
  '';

  home.file.".config/mango/autostart.conf".text = ''
    # ===== SYSTEM ENVIRONMENT =====
    exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots DISPLAY PATH
    exec-once=systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY PATH

    # Portal backend for Electron apps (Signal, Discord, etc.)
    exec-once=systemctl --user start xdg-desktop-portal-wlr && systemctl --user restart xdg-desktop-portal

    # ===== DISPLAY CONFIGURATION =====
    exec-once=wlr-randr --output DP-2 --mode 3440x1440@239.983994

    # ===== VISUAL =====
    exec-once=swaybg -i "$HOME/Pictures/Wallpapers/Ultrawide/boat.jpg" -m fill
    exec-once=waybar
    exec-once=unclutter --timeout 3 --hide-on-touch

    # ===== SYSTEM SERVICES =====
    exec-once=gnome-keyring-daemon --start --components=secrets,ssh,pkcs11
    exec-once=/usr/lib/kwalletd6
    exec-once=emacs --daemon

    # Notifications & system tray
    exec-once=swaync
    exec-once=blueman-applet

    # ===== CLIPBOARD =====
    exec-once=wl-clip-persist --clipboard regular
    exec-once=wl-paste --type text --watch cliphist store

    # ===== IDLE & LOCK =====
    exec-once=swayidle -w timeout 300 '~/.local/bin/idle-lock-guard' timeout 1800 'systemctl suspend' before-sleep 'swaylock -f --color 000000'

    # ===== SCRATCHPAD TERMINAL =====
    exec-once=foot --app-id=scratchterm

    # ===== APPLICATIONS =====
    # Communication
    exec-once=discord
    exec-once=signal-desktop
    exec-once=sh -lc 'env DESKTOPINTEGRATION=1 _JAVA_AWT_WM_NONREPARENTING=1 /home/username/AppImages/simplex_chat.appimage'
    exec-once=fractal
    exec-once=dino

    # Mail
    exec-once=protonmail-bridge
    exec-once=gtk-launch tutanota-desktop
    exec-once=thunderbird

    # Utilities
    exec-once=kdeconnectd
    exec-once=kdeconnect-indicator
    exec-once=openrgb

    # Gaming
    exec-once=steam -silent

    # Custom tools
    exec-once=~/.local/bin/streamcontroller-autostart

    # ===== SYSTEM TWEAKS =====
    exec-once=dconf write /org/gnome/desktop/interface/cursor-size 24
    exec-once=pikman-update-manager-autostart
  '';

  # ============================================================
  # Screenshot Scripts
  # ============================================================
  
  home.file.".config/mango/keybindscripts/ss1.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}"
      mkdir -p "$dir"

      file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
      grim "$file"
      notify-send "Saved screen" "$file"
    '';
    executable = true;
  };

  home.file.".config/mango/keybindscripts/ss2.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      grim -g "$(slurp)" - | wl-copy
      notify-send "Copied selection to clipboard"
    '';
    executable = true;
  };

  home.file.".config/mango/keybindscripts/ss3.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      wayfreeze &
      pid=$!
      sleep 0.1

      grim -g "$(slurp)" - | wl-copy

      kill "$pid" 2>/dev/null || true
      notify-send "Copied frozen selection to clipboard"
    '';
    executable = true;
  };

  home.file.".config/mango/keybindscripts/capslock.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Caps lock indicator
      if [ "$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1)" = "1" ]; then
        notify-send -t 800 "Caps Lock" "ON"
      else
        notify-send -t 800 "Caps Lock" "OFF"
      fi
    '';
    executable = true;
  };

  home.file.".config/mango/keybindscripts/mango-display.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Force display to 240Hz
      wlr-randr --output DP-2 --mode 3440x1440@239.983994
    '';
    executable = true;
  };

  home.file.".local/bin/mango-display.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Force display to 240Hz
      wlr-randr --output DP-2 --mode 3440x1440@239.983994
    '';
    executable = true;
  };

  home.file.".local/bin/lock-and-dpms" = {
    text = ''
      #!/usr/bin/env bash
      # Lock screen with swaylock
      swaylock -f --color 000000
    '';
    executable = true;
  };

  home.file.".local/bin/idle-lock-guard" = {
    text = ''
      #!/usr/bin/env bash
      # Lock screen after idle
      swaylock -f --color 000000
    '';
    executable = true;
  };

  # ============================================================
  # Live ~/.config dirs symlinked verbatim from the Fedora box.
  # recursive=true symlinks each file individually (live edits to unmanaged
  # files in these dirs keep working). Binaries come from system/default.nix.
  # State/logs/backups (btop.log, *.bak, watch_later) were stripped when
  # staged. The matching home-manager `programs.*` generators were removed
  # so they don't clobber these.
  # ============================================================
  xdg.configFile."alacritty".source = ./config/alacritty;  # was programs.alacritty
  xdg.configFile."kitty".source      = ./config/kitty;     # primary terminal (no prior module)
  xdg.configFile."foot".source       = ./config/foot;      # scratchpad terminal
  xdg.configFile."mpv".source        = ./config/mpv;       # was programs.mpv (incl. sponsorblock.so)
  xdg.configFile."fuzzel".source     = ./config/fuzzel;    # was home.file fuzzel.ini
  xdg.configFile."cava".source       = ./config/cava;      # was home.file cava/config
  xdg.configFile."waybar".source     = ./config/waybar;    # was home.file waybar/*
  xdg.configFile."btop".source       = ./config/btop;      # was programs.btop
  xdg.configFile."MangoHud".source   = ./config/MangoHud;  # was programs.mangohud
  xdg.configFile."yazi".source       = ./config/yazi;      # was programs.yazi

  # ============================================================
  # Zsh + Starship — REAL configs from the Fedora box (symlinked verbatim).
  #
  # The live .zshrc is a 570-line zinit setup (fast-syntax-highlighting,
  # zsh-autosuggestions, fzf-tab, abbr, forgit, ...) and inits zoxide/atuin/
  # starship/fzf itself. Letting home-manager generate zsh/starship would
  # clobber it, so we install the binaries (see system/default.nix) and
  # symlink the user's own configs instead. zinit bootstraps its plugins to
  # ~/.local/share/zinit on first interactive shell (needs network once).
  #
  # The staged zshrc was patched to also source fzf key-bindings from the
  # NixOS path (/run/current-system/sw/share/fzf). dnf/AppImage aliases are
  # kept verbatim (harmless no-ops on NixOS).
  # ============================================================
  home.file.".zshrc".source = ./shell/zshrc;
  xdg.configFile."starship.toml" = {
    source = ./shell/starship.toml;
    force = true;
  };

  # ============================================================
  # CLI Tools
  # zsh integration is OFF for all of these: the real ~/.zshrc (symlinked
  # above) already inits zoxide/fzf/atuin itself. Letting home-manager also
  # inject inits would double-bind keys and override the user's fzf/zoxide
  # flags. These modules just install the binary + write their own config.
  # ============================================================
  # Brave Origin (brave-origin-flake). The module default `pkgs.brave-origin`
  # does not exist in our pkgs (the flake exposes no overlay), so it would
  # silently fall back to plain `pkgs.brave` -- set the package explicitly
  # from the flake's per-system output. Binary/desktop id: `brave-origin`.
  programs.brave-browser = {
    enable = true;
    package = inputs.brave-origin.packages.${pkgs.system}.brave-origin;
  };

  programs.zoxide = { enable = true; enableZshIntegration = false; };
  programs.eza = { enable = true; icons = "auto"; git = true; };
  programs.bat = { enable = true; config = { theme = "TwoDark"; style = "numbers,changes,header"; }; };
  programs.ripgrep.enable = true;
  programs.fd.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };
  # yazi: config symlinked from ./config/yazi; binary from system/default.nix

  # ============================================================
  # Tmux
  # ============================================================
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    prefix = "C-a";
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
      bind | split-window -h
      bind - split-window -v
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      set -g status-style bg=#1a1b26,fg=#c0caf5
      set -g status-left "#[fg=#7aa2f7,bold] #S "
      set -g status-right "#[fg=#7dcfff] %H:%M "
      set -g window-status-current-style fg=#7aa2f7,bold
    '';
  };

  # ============================================================
  # Media & Documents
  # mpv config symlinked from ./config/mpv (incl. sponsorblock.so); binary
  # from system/default.nix. zathura kept generated (no live ~/.config/zathura
  # on the Fedora box -- it uses GNOME papers).
  # ============================================================
  programs.zathura = {
    enable = true;
    options = {
      default-bg = "#1a1b26"; default-fg = "#c0caf5";
      highlight-color = "#7aa2f7"; highlight-active-color = "#f7768e";
      recolor = true; recolor-lightcolor = "#1a1b26"; recolor-darkcolor = "#c0caf5";
      selection-clipboard = "clipboard";
    };
  };

  # cava / fuzzel / waybar configs symlinked from ./config/* (see xdg.configFile above).

  # MangoHud config symlinked from ./config/MangoHud; binary from system/default.nix (gaming/unstable).

  # ============================================================
  # GTK & Qt Theming
  # ============================================================
  gtk = {
    enable = true;
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Bibata-Modern-Ice"; package = pkgs.bibata-cursors; size = 24; };
    font = { name = "Inter"; size = 11; };
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = true; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = true; };
  };
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
