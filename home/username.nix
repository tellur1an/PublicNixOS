{ config, pkgs, pkgs-stable, lib, inputs, hyprland, hyprland-contrib, hyprland-plugins, mango-flake, ... }:

let
  # Weekly notifier for upstream updates to the pinned gaming inputs
  # (falcond / falcond-profiles / scx-loader). Sends via msmtp (Proton Bridge).
  flakePinCheck = pkgs.writeShellApplication {
    name = "flake-pin-check";
    runtimeInputs = with pkgs; [ curl jq msmtp gnupg gawk gnugrep coreutils gnused ];
    text = builtins.readFile ./scripts/flake-pin-check.sh;
  };

  keepassxcBrowserManifest = pkgs.writeText "org.keepassxc.keepassxc_browser.json" ''
    {
        "allowed_origins": [
            "chrome-extension://pdffhmdngciaglkoonimfcmckehcpafo/",
            "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
        ],
        "description": "KeePassXC integration with native messaging support",
        "name": "org.keepassxc.keepassxc_browser",
        "path": "/run/current-system/sw/bin/keepassxc-proxy",
        "type": "stdio"
    }
  '';

  protonmailBridgeGui = pkgs.writeShellScriptBin "protonmail-bridge-gui" ''
    set -euo pipefail

    bridge="$HOME/.local/share/protonmail/bridge-v3/updates/3.25.0/proton-bridge"
    if [ ! -x "$bridge" ]; then
      bridge="${pkgs.protonmail-bridge}/bin/protonmail-bridge"
    fi

    export LD_LIBRARY_PATH="${lib.makeLibraryPath [
      pkgs.libsecret
      (lib.getLib pkgs.glib)
      pkgs.libfido2
      (lib.getLib pkgs.openssl)
      pkgs.stdenv.cc.cc.lib
    ]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    if ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -f "$bridge" >/dev/null; then
      exit 0
    fi

    exec ${pkgs.systemd}/bin/systemd-run \
      --user \
      --collect \
      --quiet \
      --setenv=LD_LIBRARY_PATH="$LD_LIBRARY_PATH" \
      ${pkgs.steam-run}/bin/steam-run "$bridge" "$@"
  '';
in
{
  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "25.11";

  # Remove stale HM backup files before each activation so rebuilds don't
  # block on "would be clobbered" errors when the same file is re-backed-up.
  home.activation.removeStaleBackups = lib.hm.dag.entryBefore ["writeBoundary"] ''
    rm -f "${config.home.homeDirectory}/.config/gtk-4.0/gtk.css.backup"
    rm -f "${config.home.homeDirectory}/.config/gtk-3.0/gtk.css.backup"
  '';

  # Deploy starship.toml as a writable regular file (not a store symlink) so
  # noctalia can inject/update the [palettes.noctalia] block on theme changes.
  home.activation.noctalia-starship = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/run/current-system/sw/bin:$PATH"
    starship_cfg="${config.home.homeDirectory}/.config/starship.toml"
    palette_cache="${config.home.homeDirectory}/.cache/noctalia/starship-palette.toml"

    cp --no-preserve=mode "${./shell/starship.toml}" "$starship_cfg"

    # noctalia v5 dropped the starship apply.sh template from its package, so
    # guard on the script actually existing — otherwise HM activation aborts
    # (status 127). The static [palettes.noctalia] block in starship.toml stays.
    apply_sh=/run/current-system/sw/share/noctalia/assets/templates/starship/apply.sh
    if [ -f "$palette_cache" ] && [ -f "$apply_sh" ]; then
      bash "$apply_sh"
    fi
  '';

  home.activation.noctalia-notification-daemon = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/run/current-system/sw/bin:$PATH"
    settings="${config.home.homeDirectory}/.local/state/noctalia/settings.toml"

    if [ -f "$settings" ]; then
      if grep -q '^[[:space:]]*enable_daemon[[:space:]]*=' "$settings"; then
        $DRY_RUN_CMD sed -i 's/^[[:space:]]*enable_daemon[[:space:]]*=.*/enable_daemon = true/' "$settings"
      elif grep -q '^\[notification\]' "$settings"; then
        $DRY_RUN_CMD sed -i '/^\[notification\]/a enable_daemon = true' "$settings"
      else
        $DRY_RUN_CMD sh -c 'printf "\n[notification]\nenable_daemon = true\n" >> "$1"' sh "$settings"
      fi
    fi
  '';

  home.activation.keepassxc-brave-origin-native-messaging = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="${config.home.homeDirectory}/.config/BraveSoftware/Brave-Origin/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json"
    $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
    $DRY_RUN_CMD install -m 0644 "${keepassxcBrowserManifest}" "$target"
  '';

  # Copy Papirus icons to a user-writable location and recolor folders grey.
  # NixOS's Papirus is in the read-only store so papirus-folders can't write
  # there. The marker file tracks the store path so we only re-copy on updates.
  home.activation.papirus-grey = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/run/current-system/sw/bin:$PATH"
    icon_src="${pkgs-stable.papirus-icon-theme}/share/icons"
    icon_dst="$HOME/.local/share/icons"
    marker="$icon_dst/.papirus-nix-source"

    if [ ! -f "$marker" ] || [ "$(cat "$marker" 2>/dev/null)" != "$icon_src" ]; then
      $VERBOSE_ECHO "Papirus: copying icons and applying grey folders"
      $DRY_RUN_CMD mkdir -p "$icon_dst"
      $DRY_RUN_CMD chmod -R u+w "$icon_dst/Papirus" "$icon_dst/Papirus-Dark" "$icon_dst/Papirus-Light" 2>/dev/null || true
      $DRY_RUN_CMD rm -rf "$icon_dst/Papirus" "$icon_dst/Papirus-Dark" "$icon_dst/Papirus-Light"
      $DRY_RUN_CMD cp -r --no-preserve=mode "$icon_src/Papirus" "$icon_src/Papirus-Dark" "$icon_src/Papirus-Light" "$icon_dst/"
      $DRY_RUN_CMD "$HOME/.local/bin/papirus-folders" -C grey
      printf '%s' "$icon_src" > "$marker"
    fi
  '';

  # Copy adw-gtk3 themes as real files (not nix-store symlinks) so flatpak's
  # sandbox can read them. Flatpaks get xdg-data/themes:ro but can't follow
  # symlinks into /nix/store. Uses a marker to skip if already done.
  home.activation.adw-gtk3-flatpak = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/run/current-system/sw/bin:$PATH"
    theme_src="${pkgs-stable.adw-gtk3}/share/themes"
    theme_dst="$HOME/.local/share/themes"
    marker="$theme_dst/.adw-gtk3-nix-source"

    if [ ! -f "$marker" ] || [ "$(cat "$marker" 2>/dev/null)" != "$theme_src" ]; then
      $VERBOSE_ECHO "adw-gtk3: copying themes for flatpak access"
      $DRY_RUN_CMD mkdir -p "$theme_dst"
      $DRY_RUN_CMD rm -rf "$theme_dst/adw-gtk3" "$theme_dst/adw-gtk3-dark"
      $DRY_RUN_CMD cp -rL --no-preserve=mode "$theme_src/adw-gtk3" "$theme_src/adw-gtk3-dark" "$theme_dst/"
      printf '%s' "$theme_src" > "$marker"
    fi
  '';

  home.activation.flatpak-dark-theme = lib.hm.dag.entryAfter ["adw-gtk3-flatpak"] ''
    export PATH="/run/current-system/sw/bin:$PATH"
    if command -v flatpak >/dev/null 2>&1; then
      $VERBOSE_ECHO "Flatpak: allowing dark GTK theme access"
      $DRY_RUN_CMD flatpak override --user \
        --filesystem=xdg-data/themes:ro \
        --filesystem="$HOME/.themes:ro" \
        --filesystem="$HOME/.local/share/themes:ro" \
        --env=GTK_THEME=adw-gtk3-dark
    fi
  '';

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

  home.packages = [
    protonmailBridgeGui
    ((pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (epkgs: [ epkgs.mu4e ]))
    pkgs.mu
    pkgs.isync
    pkgs.msmtp
    pkgs.openssl
  ];

  # ============================================================
  # Hyprland (PRIMARY WM) native lua config, copied from the Fedora box.
  # recursive=true symlinks each file individually, so any non-managed
  # files you later drop into ~/.config/hypr still work alongside these.
  # System-path fixes already applied in tree:
  #   /usr/bin/wiremix             -> wiremix (PATH)
  #   rofimoji                     -> rofimoji (PATH); binds.lua calls it bare,
  #                                   resolves to the nixpkgs build.
  # ============================================================
  xdg.configFile."hypr" = {
    source = ./hypr;
    recursive = true;
  };

  xdg.dataFile."applications/protonmail-bridge.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.5
    Name=Proton Mail Bridge
    GenericName=Mail Bridge
    Comment=Use Proton Mail with local IMAP and SMTP mail clients
    Exec=${protonmailBridgeGui}/bin/protonmail-bridge-gui
    Icon=internet-mail
    Terminal=false
    StartupNotify=true
    Categories=Network;Email;
  '';

  # Tuta Mail desktop client (Electron AppImage) rewrites its own
  # ~/.local/share/applications/tutanota-desktop.desktop on every launch,
  # pinning a GC-volatile /nix/store path AND dropping `--no-sandbox` -- so the
  # next launch hits the Electron sandbox and crashes ("did not auto launch").
  # That self-written file shadows the correct nixpkgs entry (higher XDG
  # precedence). Pin a read-only HM symlink here so the app's rewrite fails and
  # the correct command always wins. StartupWMClass stays `tutanota-desktop` to
  # match the Hyprland windowrule (rules.lua) and the windowrule tag below.
  xdg.dataFile."applications/tutanota-desktop.desktop" = {
    force = true;
    text = ''
    [Desktop Entry]
    Type=Application
    Name=Tuta Mail
    GenericName=Mail Client
    Comment=The desktop client for Tuta Mail, the secure e-mail service.
    Exec=tutanota-desktop --no-sandbox %U
    Icon=tutanota-desktop
    Terminal=false
    StartupWMClass=tutanota-desktop
    MimeType=x-scheme-handler/mailto;
    Categories=Network;Email;
  '';
  };

  # Launcher entries for the TUI apps, each opened in kitty. iamb ships no
  # .desktop; aerc ships one but with Terminal=true (uses the XDG default
  # terminal, not kitty) — override it here. `--class` sets the Wayland app-id
  # (== StartupWMClass) so launchers group them and WM rules can target them.
  xdg.dataFile."applications/iamb.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=iamb
    GenericName=Matrix Client
    Comment=Matrix chat client (terminal UI, Vim keys)
    Exec=kitty --class iamb --title "iamb (Matrix)" iamb
    Icon=iamb
    Terminal=false
    StartupWMClass=iamb
    Categories=Network;InstantMessaging;Chat;
    Keywords=Matrix;Chat;IM;
  '';

  xdg.dataFile."applications/aerc.desktop" = {
    force = true;
    text = ''
    [Desktop Entry]
    Type=Application
    Name=aerc
    GenericName=Mail Client
    Comment=Email client (terminal UI)
    Exec=kitty --class aerc --title "aerc (Mail)" aerc %u
    Icon=aerc
    Terminal=false
    StartupWMClass=aerc
    Categories=Office;Network;Email;
    Keywords=Email;Mail;IMAP;SMTP;
    MimeType=x-scheme-handler/mailto;
  '';
  };

  home.file.".mbsyncrc".text = ''
    IMAPAccount proton
    Host 127.0.0.1
    Port 1143
    User your-email@example.com
    PassCmd "gpg --quiet --for-your-eyes-only --no-tty -d ~/.authinfo.gpg 2>/dev/null | awk '/machine 127.0.0.1 login your-email@example.com port 1143/{print $NF}'"
    TLSType None

    IMAPStore proton-remote
    Account proton

    MaildirStore proton-local
    SubFolders Verbatim
    Path ~/Mail/proton/
    Inbox ~/Mail/proton/Inbox/

    Channel proton
    Far :proton-remote:
    Near :proton-local:
    Patterns * !"All Mail" !"Recovered Messages"
    Create Both
    Sync All
    Expunge None
    SyncState *

    Channel proton-recovered
    Far :proton-remote:
    Near :proton-local:
    Patterns "Recovered Messages"
    Create Near
    Sync Pull
    Expunge None
    SyncState *

    Channel proton-allmail
    Far :proton-remote:
    Near :proton-local:
    Patterns "All Mail"
    Create Near
    Sync Pull PushGone PushFlags
    Expunge None
    SyncState *

    Group proton-all
    Channel proton
    Channel proton-recovered
    Channel proton-allmail
  '';

  # Proton Bridge SMTP uses STARTTLS with a self-signed cert (CN=127.0.0.1), so
  # `tls off` makes msmtp refuse PLAIN auth ("cannot use a secure authentication
  # method") and nothing sends. Use STARTTLS and pin the bridge's SHA256
  # fingerprint. NOTE: if the bridge regenerates its cert (reinstall/major
  # update) this fingerprint changes and sending breaks until refreshed — get a
  # new one with:
  #   msmtp --serverinfo --host=127.0.0.1 --port=1025 --tls --tls-starttls --tls-certcheck=off
  home.file.".msmtprc".text = ''
    defaults
    auth on
    tls on
    tls_starttls on
    tls_fingerprint D3:3E:40:95:8B:6D:47:0E:04:AF:A4:FF:13:A1:82:40:5A:82:90:D4:82:48:85:30:89:9D:D7:48:BC:2A:DC:12
    logfile ~/.cache/msmtp.log

    account proton
    host 127.0.0.1
    port 1025
    from your-email@example.com
    user your-email@example.com
    passwordeval gpg --quiet --for-your-eyes-only --no-tty -d ~/.authinfo.gpg 2>/dev/null | awk '/machine 127.0.0.1 login your-email@example.com port 1143/{print $NF}'

    account default : proton
  '';

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
    # Stale GTK_THEME from previous tools/sessions overrides gsettings — force
    # the correct value so spawned apps always use adw-gtk3-dark + noctalia.css.
    env=GTK_THEME,adw-gtk3-dark
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
    bind=SUPER,c,spawn,noctalia msg panel-toggle control-center
    bind=SUPER+SHIFT,n,spawn,noctalia msg panel-toggle control-center notifications
    bind=SUPER+SHIFT,c,spawn,noctalia msg notification-clear-active
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
    windowrule=tags:2,appid:^(dev\.vencord\.Vesktop)$
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
    # ============================================================
    # MangoWC autostart - compositor-specific only.
    # App-level autostart shared with Hyprland via wm-session-autostart
    # (single source, no drift between sessions).
    # ============================================================

    # Portal backend for Electron apps (Signal, Discord, etc.)
    exec-once=systemctl --user start xdg-desktop-portal-wlr && systemctl --user restart xdg-desktop-portal

    # Export compositor env to systemd/dbus BEFORE anything that needs WAYLAND_DISPLAY
    exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY PATH XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE
    exec-once=systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY PATH XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE

    exec-once=noctalia

    # ===== DISPLAY CONFIGURATION =====
    # Direct wlr-randr call (240Hz)
    exec-once=wlr-randr --output DP-2 --mode 3440x1440@239.983994

    # ===== AUTH AGENT =====
    # launched here (after env export) so WAYLAND_DISPLAY is available
    exec-once=/usr/libexec/xfce-polkit

    # ===== IDLE & LOCK =====
    # Handled entirely by Noctalia's built-in idle manager (Settings > Idle)

    # ===== SHARED APP AUTOSTART =====
    # clipboard, scratchterm, vesktop.service (wayland-wait fix), signal, mail,
    # tray utils, syncthing, keepassxc, streamcontroller, input-remapper, delayed steam
    exec-once=~/.local/bin/wm-session-autostart
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

  home.file.".local/bin/wm-session-autostart" = {
    source = ./scripts/wm-session-autostart;
    executable = true;
  };

  home.file.".local/bin/start-streamcontroller" = {
    source = ./scripts/start-streamcontroller;
    executable = true;
  };

  home.file.".local/bin/vesktop-autostart" = {
    source = ./scripts/vesktop-autostart;
    executable = true;
  };

  systemd.user.services.vesktop = {
    Unit = {
      Description = "Vesktop";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${config.home.homeDirectory}/.local/bin/vesktop-autostart";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Weekly check for upstream updates to the pinned gaming inputs. Runs as a
  # user service (needs ~/.msmtprc + gpg-agent + the loopback Proton Bridge,
  # all session-scoped). Notification only; the bump stays manual.
  systemd.user.services.flake-pin-check = {
    Unit = {
      Description = "Check pinned flake inputs (falcond/scx-loader) for upstream updates";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${flakePinCheck}/bin/flake-pin-check";
    };
  };

  systemd.user.timers.flake-pin-check = {
    Unit.Description = "Weekly check of pinned flake inputs for upstream updates";
    Timer = {
      OnCalendar = "Sun 11:00";
      Persistent = true;          # catch up if the machine was off at the trigger
      RandomizedDelaySec = "30m";
    };
    Install.WantedBy = [ "timers.target" ];
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
    # Pin the password backend. Under Hyprland (no GNOME/KDE desktop hint)
    # Chromium guesses the os_crypt backend per launch: gnome-libsecret when
    # the keyring is up (cookies/passwords tagged v11), `basic`/"peanuts" when
    # it is down (v10). The flip-flop -- plus a regenerated Safe Storage key
    # during the old package-only gnome-keyring bug -- left v11 blobs
    # undecryptable and logged the profile out everywhere. Keyring now
    # auto-unlocks via PAM, so pin to it for a deterministic, stable key.
    commandLineArgs = [ "--password-store=gnome-libsecret" ];
  };

  # Zed — GUI-native modal editor. Package comes from unstable `pkgs`
  # (useGlobalPkgs). userSettings writes ~/.config/zed/settings.json; helix_mode
  # turns on Helix-style modal editing.
  programs.zed-editor = {
    enable = true;
    # Zed's Nix extension expects to download `nil`, but prebuilt binaries don't
    # run on NixOS. Provide it from nixpkgs (also on Zed's PATH via extraPackages)
    # and pin the store path so the extension stops asking to install it.
    extraPackages = [ pkgs.nil pkgs.nixfmt ];
    userSettings = {
      helix_mode = true;
      lsp.nil.binary.path = "${pkgs.nil}/bin/nil";
      # Format-on-save for Nix via nixfmt (RFC 166 style). nixfmt reads stdin
      # and writes stdout, so it slots straight into Zed's external formatter.
      languages.Nix = {
        formatter.external = {
          command = "${pkgs.nixfmt}/bin/nixfmt";
          arguments = [ ];
        };
        format_on_save = "on";
      };
    };
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
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Bibata-Modern-Ice"; package = pkgs.bibata-cursors; size = 24; };
    font = { name = "Inter"; size = 12; };
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = true; };
    gtk3.extraCss = ''@import url("file://${config.home.homeDirectory}/.config/gtk-3.0/noctalia.css");'';
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = true; };
    # Adopt the new HM default (no theme name for GTK4): libadwaita apps ignore
    # GTK themes anyway, and noctalia colors come from gtk4.extraCss below, not
    # the theme. Silences the stateVersion < 26.05 legacy-default warning.
    gtk4.theme = null;
    gtk4.extraCss = ''
      @import url("file://${config.home.homeDirectory}/.config/gtk-4.0/noctalia.css");
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  # GNOME font gsettings — the 4 slots in the Tweaks "Fonts" panel.
  # Read by GTK apps + xdg-portal. 34" UW @ 1440p ≈ 109 PPI (like 27"/1440p),
  # so 12pt is comfortable; bump to 13 here if you want roomier.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-name = "Inter 12";            # Interface
      document-font-name = "Inter 12";   # Document
      monospace-font-name = "IoskeleyMono Nerd Font 12";  # Monospace
    };
    "org/gnome/desktop/wm/preferences" = {
      titlebar-font = "Inter 12";        # Legacy window titles
    };
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
