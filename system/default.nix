{ config, pkgs, pkgs-stable, inputs, ... }:

# ============================================================
# PACKAGE CHANNEL POLICY (per machine owner)
#
#   UNSTABLE (pkgs)        -> daily drivers, browsers, gaming, and anything
#                            with a keybind on the Hyprland setup.
#   STABLE   (pkgs-stable) -> everything else: occasional GUI apps, office,
#                            media, system utilities, dev toolchains, fonts,
#                            themes, libraries.
#
# Reconciled against the live Fedora box (authoritative). Apps not present
# on Fedora were dropped; Fedora apps missing here were added. See README.
# ============================================================

{
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  # ============================================================
  # Fonts (stable)
  # ============================================================
  fonts.packages = with pkgs-stable; [
    ubuntu-sans
    ubuntu-sans-mono
    nerd-fonts.lilex
    nerd-fonts.ubuntu
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono
    ioskeley-mono.normal-NF       # Iosevka tuned to mimic Berkeley Mono, normal width, nerd-patched
    material-symbols
    material-design-icons
    dejavu_fonts
    inter
    comfortaa                     # Fedora: aajohan-comfortaa-fonts
    source-code-pro               # Fedora: adobe-source-code-pro-fonts
    noto-fonts                    # Fedora: google-noto-sans-fonts
    font-awesome_4                # Fedora: fontawesome4-fonts
  ];

  # ============================================================
  # Secret service (GNOME Keyring)
  # ============================================================
  # Provides org.freedesktop.secrets so gpg-agent can cache passphrases
  # and Proton Mail Bridge can reach a keychain. The module also creates
  # the setuid /run/wrappers/bin/gnome-keyring-daemon wrapper that the
  # D-Bus activation file needs, plus PAM auto-unlock at login.
  # (Package alone in systemPackages is NOT enough — that was the bug:
  #  wrapper missing -> dbus activation "unit failed" -> no secret service.)
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages =
    # ========================================================
    # UNSTABLE: daily drivers / browsers / gaming / bound apps
    # ========================================================
    (with pkgs; [
      # --- Browsers (all daily) ---
      brave                       # secondary; brave-origin (M+ALT+b) now via brave-origin-flake (home programs.brave-browser)
      vivaldi
      vivaldi-ffmpeg-codecs
      mullvad-browser
      chromium
      firefox                     # Fedora: firefox
      qutebrowser                 # Fedora: qutebrowser
      tor-browser                 # Fedora: torbrowser-launcher
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default  # Zen (flake)

      # --- Communication (daily, autostarted) ---
      vesktop                     # Fedora: vesktop (REPLACES discord)
      signal-desktop              # Fedora: signal-desktop
      telegram-desktop            # Fedora: telegram-desktop
      teamspeak6-client           # TeamSpeak 6 beta voice client
      fractal                     # Matrix client (replaces nheko; uses matrix-rust-sdk, no libolm)
      iamb                        # Matrix TUI (vim-like; matrix-rust-sdk)
      aerc                        # mail TUI (works against Proton Bridge IMAP/SMTP like mu4e)
      dino                        # XMPP/Jabber GUI client (OMEMO)
      protonmail-bridge           # Proton Mail Bridge; autostarted by Hyprland

      # --- Terminals (bound / daily) ---
      kitty                       # bind M+Return
      foot                        # scratchpad terminal
      alacritty

      # --- Editors (bound / daily) ---
      ((emacsPackagesFor emacs).emacsWithPackages (epkgs: [ epkgs.mu4e ])) # bind M+e (emacs-focus.sh)
      neovim
      neovide                     # Fedora: neovide

      # --- Daily CLI / shell tooling ---
      claude-code
      codex
      git
      gh                          # Fedora: gh
      lazygit                     # Fedora: golang-github-jesseduffield-lazygit
      eza
      bat
      ripgrep
      fd
      fzf
      zoxide
      starship
      atuin                       # Fedora: atuin
      direnv                      # Fedora: direnv
      delta                       # Fedora: git-delta
      difftastic                  # Fedora: difftastic
      yazi
      fastfetch                   # Fedora: fastfetch (REPLACES neofetch)
      yt-dlp
      jq
      yq-go                       # Fedora: yq
      pipx                        # Fedora: pipx (unstable: 1.14.0, cached, no test hack)
      mu                          # mu/mu4e indexer for Doom Emacs mail
      isync                       # mbsync for Proton Bridge -> Maildir
      msmtp                       # sendmail-compatible SMTP client for mu4e
      openssl                     # debug local Proton Bridge TLS

      # --- Wayland shell / bound utilities ---
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default  # noctalia v5 bar
      quickshell                  # Quickshell runtime (noctalia stack; Fedora: noctalia-git)
      fuzzel                      # bind M+d / M+Space
      cliphist                    # bind M+p
      wl-clipboard
      grim                        # screenshot binds
      slurp
      rofimoji                    # bind M+semicolon
      wiremix                     # bind M+v (REPLACES pwvucontrol)
      playerctl                   # media-key binds

      # --- Hyprland ecosystem (track hyprland-git) ---
      hyprlock                    # Fedora: hyprlock
      hypridle                    # Fedora: hypridle (dormant fallback; noctalia owns idle)
      hyprpicker                  # Fedora: hyprpicker

      # --- Music (daily) ---
      spotify                     # Fedora: spotify-launcher

      # --- Gaming overlays / tools (gaming = unstable) ---
      lutris
      heroic                      # Fedora: heroic-games-launcher
      protonplus                  # Fedora: protonplus
      mangohud
      goverlay
      vkbasalt                    # Fedora: python3-vkbasalt-cli
      steamtinkerlaunch           # Fedora: steamtinkerlaunch
      protontricks                # Fedora: protontricks

      # --- Input remapping (bound input device) ---
      input-remapper              # Fedora: input-remapper (Naga preset)
    ])
    ++
    # ========================================================
    # STABLE: everything else
    # ========================================================
    (with pkgs-stable; [
      # --- Core system tools ---
      vim
      wget
      curl
      fish
      zsh
      zsh-syntax-highlighting
      tree
      tldr
      unzip
      unrar
      p7zip                       # Fedora: 7zip-standalone
      zip                         # Fedora: zip
      age

      # --- CLI utilities (occasional) ---
      btop
      glow                        # Fedora: glow
      lnav                        # Fedora: lnav
      duf                         # Fedora: duf
      procs                       # Fedora: procs
      hyperfine                   # Fedora: hyperfine
      tokei                       # Fedora: tokei
      ranger                      # Fedora: ranger
      w3m                         # Fedora: w3m
      weechat                     # Fedora: weechat
      pandoc                      # Fedora: pandoc-cli
      shellcheck                  # Fedora: ShellCheck
      mediainfo                   # Fedora: mediainfo
      ffmpegthumbnailer           # Fedora: ffmpegthumbnailer
      chafa                       # Fedora: chafa
      ueberzugpp                  # Fedora: ueberzugpp (yazi previews)

      # --- Notes / Office / Productivity ---
      libreoffice                 # Fedora: libreoffice-*
      joplin-desktop              # Fedora: joplin
      featherpad                  # Fedora: featherpad
      calibre                     # Fedora: calibre
      qalculate-gtk               # Fedora: qalculate-gtk
      zathura                     # (kept: configured in home/username.nix)

      # --- Graphics / Image ---
      gimp                        # Fedora: gimp
      krita                       # Fedora: krita
      shotwell                    # Fedora: shotwell

      # --- Media ---
      vlc
      mpv
      youtube-tui                 # TUI YouTube client; plays via mpv (inherits sponsorblock.so)
      kew                         # Fedora: kew
      mpd                         # Fedora: mpd
      mpc                         # Fedora: mpc
      cava                        # (kept: configured in home/username.nix)

      # --- Audio routing / production ---
      # (helvum dropped: removed from stable 26.05 as unmaintained + vulnerable
      # dep; it was only a manual GUI patchbay, redundant with qpwgraph, and not
      # used by the streamdeck-audio routing.)
      qpwgraph                    # Fedora: qpwgraph
      qjackctl                    # Fedora: qjackctl
      carla                       # Fedora: Carla
      audacity                    # Fedora: audacity
      pamixer                     # Fedora: pamixer (used by scripts)
      pulseaudio                  # provides pactl/pacmd for streamdeck-audio scripts
      alsa-scarlett-gui           # Scarlett 2i2 interface

      # --- File managers ---
      nautilus
      nemo-with-extensions
      nemo-fileroller
      gnome-disk-utility
      gparted                     # Fedora: gparted

      # --- Mail clients ---
      tutanota-desktop            # Tuta mail desktop client

      # --- Security / sync / torrents ---
      keepassxc                   # Fedora: keepassxc
      seahorse                    # Fedora: seahorse
      transmission_4-gtk          # Fedora: transmission-gtk
      feather                     # Fedora: feather (Monero wallet) -- verify attr on rebuild
	
      # --- Development toolchains ---
      vscodium                    # Fedora: codium (REPLACES vscode)
      cmake
      gnumake
      gcc
      clang
      rustup                      # Fedora: rust/cargo
      zig
      nodejs
      deno                        # Fedora: deno
      bun                         # Fedora: bun-bin
      go                          # Fedora: golang
      python3
      meson                       # Fedora: meson
      ninja                       # Fedora: ninja-build

      # --- Virtualization / containers ---
      virt-manager
      podman                      # Fedora: podman

      # --- System utilities ---
      bleachbit
      timeshift
      smartmontools
      borgbackup                  # Fedora: borgbackup
      borgmatic                   # Fedora: borgmatic (working backup setup)

      # --- Android ---
      android-tools

      # --- Network / VPN / Privacy / Diagnostics ---
      mullvad-vpn
      tor
      torsocks
      wireguard-tools
      nmap                        # Fedora: nmap
      wireshark                   # Fedora: wireshark
      mtr                         # Fedora: mtr

      # --- AI / LLM ---
      lmstudio

      # --- Hardware control / monitoring ---
      lact                        # Fedora: lact (RX 9070 XT control)
      amdgpu_top                  # Fedora: amdgpu_top
      openrgb-with-all-plugins    # Fedora: openrgb + openrgb-udev-rules
      solaar                      # Fedora: solaar
      piper                       # Fedora: piper
      ddcutil                     # Fedora: ddcutil
      lm_sensors
      keyd                        # Fedora: keyd (Naga remap)
      ydotool                     # Fedora: ydotool

      # --- Themes / Icons / Cursors ---
      papirus-icon-theme
      adwaita-icon-theme
      kdePackages.breeze-icons
      bibata-cursors              # Fedora: bibata-cursor-theme
      adw-gtk3
      kdePackages.qtstyleplugin-kvantum   # Fedora: kvantum (qt6)
      libsForQt5.qtstyleplugin-kvantum    # Fedora: kvantum-qt5

      # --- Wayland / desktop utilities (non-bound) ---
      waybar
      swaybg
      swayidle
      swaylock                    # Fedora: swaylock (plain; REPLACES swaylock-effects)
      wlogout
      wob                         # Fedora: wob (REPLACES swayosd)
      nwg-look
      wlr-randr
      kanshi                      # Fedora: kanshi (REPLACES wdisplays)
      gammastep                   # Fedora: gammastep (REPLACES wlsunset)
      wev
      wtype
      brightnessctl

      # --- XDG / desktop integration ---
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome    # Fedora: xdg-desktop-portal-gnome
      xdg-user-dirs

      # --- Auth ---
      gnome-keyring

      # --- KDE Connect ---
      kdePackages.kdeconnect-kde  # Fedora: kde-connect

      # --- Qt theming ---
      kdePackages.qt6ct           # Fedora: qt6ct
      libsForQt5.qt5ct            # Fedora: qt5ct
      kdePackages.layer-shell-qt
      gtk-layer-shell

      # --- Libraries ---
      libxkbcommon
      nss
      fontconfig
      libdrm
      mesa
      libnotify
    ]);
}
