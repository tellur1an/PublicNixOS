{ config, pkgs, lib, chaotic, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Localization
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable Hyprland, Niri, and GNOME
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.niri = {
    enable = true;
    package = chaotic.legacyPackages.x86_64-linux.niri_git.overrideAttrs (oldAttrs: {
      doCheck = false; # Skip tests to avoid "Too many open files" error
    });
  };

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.xserver.xkb.layout = "us";

  # XDG Portal
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  # Set Niri configuration file
  environment.etc."niri/config.kdl".text = ''
    prefer-no-csd false
    window-rule = [
      { match = { app-id = "some-app" } set = { prefer-no-csd = false, tiled = true } }
    ]
  '';

  # OBS Studio with plugins
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-composite-blur
      obs-shaderfilter
      obs-scale-to-sound
      obs-move-transition
      obs-gradient-source
      obs-replay-source
      obs-source-clone
      obs-3d-effect
      obs-livesplit-one
      waveform
      obs-gstreamer
      obs-vaapi
      obs-vkcapture
    ];
  };

  # Mullvad VPN
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  systemd.services.mullvad-daemon = {
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad-daemon -v --disable-stdout-timestamps";
      Environment = "MULLVAD_RESOURCE_DIR=${pkgs.mullvad-vpn}/share/mullvad/resources";
    };
  };

  # Hardware and gaming
  hardware.wooting.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.xone.enable = true;
  #hardware.xpadneo.enable = true;
  hardware.opentabletdriver.enable = true;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.gamescope.capSysNice = true;

  # Other services
  services.flatpak.enable = true;
  services.hardware.openrgb.enable = true;
  services.printing.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  security.rtkit.enable = true;
  security.polkit.enable = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;

  # User configuration
  users.users.tellur1an = {
    isNormalUser = true;
    description = "User";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # QtWebEngine and dependencies
    #qt5.qtwebengine
    libxkbcommon
    nss
    fontconfig
    libdrm
    mesa

    # Core Utilities
    vim
    wget
    git
    taskwarrior3

    # Shells
    fish

    # Terminal and Multiplexers
    kitty
    alacritty
    foot

    # Communication
    signal-desktop
    # teamspeak_client 
    element-desktop
    simplex-chat-desktop
    electron-mail
    legcord
    rustdesk
	
	#AI
	lmstudio
	
    # Productivity
    featherpad
    standardnotes
    onlyoffice-desktopeditors
    obsidian
    libreoffice
    zathura
    neovim

    # Web Browsers
    vivaldi
    vivaldi-ffmpeg-codecs
    mullvad-browser
    librewolf-bin
    
    # VPN and Security
    mullvad-vpn
    hblock

    # Gaming
    protonplus
    heroic
    gamemode
    mangohud
    goverlay
    joystickwake
    input-remapper

    # Media and Audio
    youtube-music
    easyeffects
    gnomeExtensions.easyeffects-preset-selector
    alsa-scarlett-gui
    pwvucontrol
    mpv

    # Fonts
    ubuntu-sans
    ubuntu-sans-mono
    nerd-fonts.lilex
    nerd-fonts.ubuntu
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    material-symbols
    dejavu_fonts
    texlivePackages.dejavu
    nerd-fonts.dejavu-sans-mono
    lilex
    fira-code-symbols
    nerd-fonts.symbols-only
    nerd-fonts.space-mono
    
    # Themes and Icons
    papirus-icon-theme
    yaru-theme
    yaru-remix-theme
    bibata-cursors

    # Wayland Desktop Utilities
    waybar
    hyprpaper
    swayosd
    hypridle
    quickshell
    walker
    rofi
    wofi
    hyprcursor
    hyprpolkitagent
    wlogout
    kdePackages.layer-shell-qt
    gtk-layer-shell
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-wlr
    kdePackages.qt6ct
    swaylock-effects
    swayidle
    swww
    xwayland-satellite
    

    # Notifications
    libnotify
    mako
    kdePackages.kdeconnect-kde

    # File Managers
    nautilus
    nemo-with-extensions

    # System Utilities
    gearlever
    neofetch
    gnome-tweaks
    gnome-boxes
    openrgb-with-all-plugins
    xdg-user-dirs
    

    # Authentication and Security
    gnome-keyring
    mate.mate-polkit

    # Clipboard and Screenshot Tools
    wl-clipboard
    clipman
    grim
    slurp
    sway-contrib.grimshot
    wayfreeze

    # GNOME Extensions
    gnome-browser-connector
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    gnomeExtensions.compiz-windows-effect
    gnomeExtensions.coverflow-alt-tab
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.just-perfection
    gnomeExtensions.arcmenu
    gnomeExtensions.appindicator
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.custom-osd
    gnomeExtensions.pop-shell
    gnomeExtensions.tiling-shell
    gnomeExtensions.paperwm

    # Graphics and Display
    nwg-look
  ];

  # Mesa configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86) true;
    package = pkgs.mesa;
  };

  # Firewall
  networking.firewall.enable = false;

  # Environment variables
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "xcb"; # Use XWayland for Qt apps
    QTWEBENGINE_DISABLE_GPU = "1"; # Disable GPU to avoid QtWebEngine crashes
    MOZ_ENABLE_WAYLAND = "1";
    XDG_SESSION_TYPE = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_FORCE_DPI = "physical";
    CLUTTER_BACKEND = "wayland";
    TERM = "kitty";
    TERMINAL = "kitty";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    STEAM_FORCE_DESKTOPUI_SCALING = "1";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}
